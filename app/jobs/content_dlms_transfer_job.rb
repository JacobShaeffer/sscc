class ContentDlmsTransferJob < ApplicationJob
  queue_as :default

  def perform(content_ids:, filters:, queued_at:, base_url: DlmsClient.default_base_url)
    started_at = Time.current
    metadata_types = MetadataType.order(:order).to_a
    client = dlms_client(base_url)
    results = []

    Content.where(id: content_ids)
           .includes(:metadata, file_attachment: :blob)
           .find_each do |content|
      results << transfer_content(content, client, metadata_types)
    rescue StandardError => e
      results << failure_result(content, e)
    end

    write_report(
      base_url: base_url,
      content_ids: content_ids,
      filters: filters,
      queued_at: queued_at,
      started_at: started_at,
      finished_at: Time.current,
      results: results
    )
  end

  private

  def dlms_client(base_url)
    DlmsClient.new(base_url: base_url)
  end

  def transfer_content(content, client, metadata_types)
    filename = content.file.filename.to_s

    duplicate_reason = duplicate_reason_for(content, client)
    return skipped_result(content, reason: duplicate_reason) if duplicate_reason.present?

    created_metadata = []
    metadata_ids = resolve_metadata_ids(content, client, metadata_types, created_metadata)
    upload_response = with_local_file(content) do |file_path|
      client.upload_content(
        file_path: file_path,
        original_filename: content.file.filename.to_s,
        content_type: content.file.blob.content_type,
        fields: ContentExporter.dlms_fields(content, metadata_types: metadata_types).merge('metadata' => metadata_ids)
      )
    end

    uploaded_result(content, upload_response: upload_response, metadata_ids: metadata_ids, created_metadata: created_metadata)
  rescue DlmsClient::RequestError => e
    duplicate_reason = client.duplicate_content_error_reason(e.body)
    return skipped_result(content, reason: duplicate_reason) if duplicate_reason.present?

    failure_result(content, e, metadata_ids: metadata_ids, created_metadata: created_metadata)
  rescue StandardError => e
    failure_result(content, e, metadata_ids: metadata_ids, created_metadata: created_metadata)
  end

  def resolve_metadata_ids(content, client, metadata_types, created_metadata)
    ContentExporter.metadata_values(content, metadata_types: metadata_types).flat_map do |metadata_type_name, values|
      values.reject(&:blank?).map do |value|
        resolution = client.ensure_metadata(type_name: metadata_type_name, name: value)

        if resolution[:created]
          created_metadata << {
            'type_name' => metadata_type_name,
            'name' => value,
            'id' => resolution[:id]
          }
        end

        resolution[:id]
      rescue StandardError => e
        raise metadata_resolution_error(metadata_type_name: metadata_type_name, value: value, error: e)
      end
    end
  end

  def failure_result(content, error, metadata_ids: [], created_metadata: [])
    {
      'status' => 'failed',
      'content_id' => content&.id,
      'title' => content&.title,
      'filename' => content&.file&.filename&.to_s,
      'resolved_metadata_ids' => metadata_ids,
      'created_metadata' => created_metadata,
      'error' => error_payload(error)
    }
  end

  def duplicate_reason_for(content, client)
    return 'duplicate_filename' if client.content_exists?(file_name: content.file.filename.to_s)
    return 'duplicate_title' if client.content_exists?(title: content.title)

    nil
  end

  def skipped_result(content, reason:)
    {
      'status' => 'skipped',
      'content_id' => content.id,
      'title' => content.title,
      'filename' => content.file.filename.to_s,
      'reason' => reason
    }
  end

  def uploaded_result(content, upload_response:, metadata_ids:, created_metadata:)
    {
      'status' => 'uploaded',
      'content_id' => content.id,
      'title' => content.title,
      'filename' => content.file.filename.to_s,
      'dlms_content_id' => upload_response['id'],
      'resolved_metadata_ids' => metadata_ids,
      'created_metadata' => created_metadata
    }
  end

  def error_payload(error)
    payload = {
      'class' => error.class.name,
      'message' => error.message
    }

    if error.respond_to?(:status) && error.status.present?
      payload['status'] = error.status
    end

    payload['body'] = error.body if error.respond_to?(:body) && error.body.present?
    payload
  end

  def metadata_resolution_error(metadata_type_name:, value:, error:)
    message = "#{error.message} (metadata: #{metadata_type_name}=#{value})"
    body = if error.respond_to?(:body) && error.body.present?
             error.body.deep_dup
           else
             {}
           end

    body['metadata_type_name'] = metadata_type_name
    body['metadata_value'] = value

    if error.respond_to?(:status)
      DlmsClient::RequestError.new(message, status: error.status, body: body)
    else
      StandardError.new(message)
    end
  end

  def with_local_file(content)
    blob = content.file.blob
    service = blob.service

    if service.respond_to?(:path_for)
      path = service.path_for(blob.key)
      return yield(path) if File.exist?(path)
    end

    tempfile = Tempfile.new([File.basename(blob.filename.to_s, '.*'), File.extname(blob.filename.to_s)])
    tempfile.binmode
    blob.download { |chunk| tempfile.write(chunk) }
    tempfile.flush
    yield(tempfile.path)
  ensure
    tempfile&.close!
  end

  def write_report(base_url:, content_ids:, filters:, queued_at:, started_at:, finished_at:, results:)
    report = {
      'job_id' => job_id,
      'queued_at' => queued_at,
      'started_at' => started_at.iso8601,
      'finished_at' => finished_at.iso8601,
      'dlms_base_url' => base_url,
      'selected_content_count' => content_ids.size,
      'filters' => filters,
      'summary' => summary_for(results),
      'results' => results
    }

    File.write(report_path, JSON.pretty_generate(report))
  end

  def summary_for(results)
    counts = results.each_with_object(Hash.new(0)) do |result, totals|
      totals[result.fetch('status')] += 1
    end

    {
      'uploaded' => counts['uploaded'],
      'skipped' => counts['skipped'],
      'failed' => counts['failed']
    }
  end

  def report_path
    timestamp = Time.current.strftime('%m-%d-%y_%H-%M-%S')
    Rails.root.join('tmp', "dlms_content_transfer_#{timestamp}_#{job_id}.json")
  end
end
