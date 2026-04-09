require 'test_helper'

class ContentDlmsTransferJobTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @admin = User.create!(
      email: 'admin-job@example.com',
      name: 'Admin Job',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    @subject_type = MetadataType.create!(name: 'Subject', order: 1, user: @admin)
    @resource_type = MetadataType.create!(name: 'Resource Type', order: 2, user: @admin)
    @science = Metadatum.create!(name: 'Science', metadata_type: @subject_type, user: @admin)
    @book = Metadatum.create!(name: 'Book', metadata_type: @resource_type, user: @admin)
    cleanup_reports
  end

  teardown do
    cleanup_reports
  end

  test 'writes report with uploaded content, filters, metadata ids, active true field, published_date, and reviewed_on' do
    content = create_content(title: 'Transferable', filename: 'transferable.pdf', metadata: [@science, @book])
    fake_client = FakeDlmsClient.new
    job = build_job(fake_client, 'job-upload-1')

    travel_to Time.zone.local(2026, 4, 9, 8, 15, 0) do
      job.perform(
        content_ids: [content.id],
        filters: { 'title' => 'Transferable', 'metadata' => { @subject_type.id.to_s => 'Science' } },
        queued_at: '2026-04-07T12:00:00Z',
        base_url: 'http://example.test'
      )
    end

    report = JSON.parse(File.read(report_files.first))
    result = report.fetch('results').first

    assert_equal 'http://example.test', report.fetch('dlms_base_url')
    assert_equal 'Transferable', report.dig('filters', 'title')
    assert_equal 'uploaded', result.fetch('status')
    assert_equal [101, 102], result.fetch('resolved_metadata_ids')
    assert_equal 'True', fake_client.uploads.first[:fields].fetch('active')
    assert_equal '2025-01-01', fake_client.uploads.first[:fields].fetch('published_date')
    assert_equal '2026-04-09', fake_client.uploads.first[:fields].fetch('reviewed_on')
    assert_not fake_client.uploads.first[:fields].key?('published_year')
    assert_equal 'transferable.pdf', fake_client.uploads.first[:original_filename]
    assert_equal [101, 102], Array(fake_client.uploads.first[:fields]['metadata']).map(&:to_i)
    assert_equal 1, report.dig('summary', 'uploaded')
  end

  test 'skips duplicate filenames and continues after upload failures' do
    duplicate = create_content(title: 'Duplicate', filename: 'duplicate.pdf', metadata: [@science])
    failing = create_content(title: 'Failing', filename: 'failing.pdf', metadata: [@book])
    succeeding = create_content(title: 'Succeeding', filename: 'succeeding.pdf', metadata: [@science])
    fake_client = FakeDlmsClient.new(
      duplicate_filenames: ['duplicate.pdf'],
      failing_filenames: ['failing.pdf']
    )
    job = build_job(fake_client, 'job-upload-2')

    job.perform(
      content_ids: [duplicate.id, failing.id, succeeding.id],
      filters: { 'title' => '' },
      queued_at: '2026-04-07T12:00:00Z',
      base_url: 'http://example.test'
    )

    report = JSON.parse(File.read(report_files.first))
    statuses = report.fetch('results').map { |entry| entry.fetch('status') }

    assert_includes statuses, 'skipped'
    assert_includes statuses, 'failed'
    assert_includes statuses, 'uploaded'
    assert_equal 1, report.dig('summary', 'skipped')
    assert_equal 1, report.dig('summary', 'failed')
    assert_equal 1, report.dig('summary', 'uploaded')
  end

  test 'skips duplicate titles before upload' do
    duplicate_title = create_content(title: 'Existing Title', filename: 'new-file.pdf', metadata: [@science])
    fake_client = FakeDlmsClient.new(duplicate_titles: ['Existing Title'])
    job = build_job(fake_client, 'job-upload-3')

    job.perform(
      content_ids: [duplicate_title.id],
      filters: { 'title' => 'Existing Title' },
      queued_at: '2026-04-07T12:00:00Z',
      base_url: 'http://example.test'
    )

    report = JSON.parse(File.read(report_files.first))
    result = report.fetch('results').first

    assert_equal 'skipped', result.fetch('status')
    assert_equal 'duplicate_title', result.fetch('reason')
    assert_equal 0, report.dig('summary', 'uploaded')
    assert_equal 1, report.dig('summary', 'skipped')
  end

  test 'treats duplicate upload errors as skipped' do
    duplicate = create_content(title: 'Duplicate After Upload', filename: 'duplicate-after-upload.pdf', metadata: [@science])
    fake_client = FakeDlmsClient.new(duplicate_upload_titles: ['Duplicate After Upload'])
    job = build_job(fake_client, 'job-upload-4')

    job.perform(
      content_ids: [duplicate.id],
      filters: { 'title' => 'Duplicate After Upload' },
      queued_at: '2026-04-07T12:00:00Z',
      base_url: 'http://example.test'
    )

    report = JSON.parse(File.read(report_files.first))
    result = report.fetch('results').first

    assert_equal 'skipped', result.fetch('status')
    assert_equal 'duplicate_title', result.fetch('reason')
    assert_equal 0, report.dig('summary', 'uploaded')
    assert_equal 1, report.dig('summary', 'skipped')
  end

  test 'reports unexpected upload responses as failed' do
    content = create_content(title: 'Unexpected Upload Response', filename: 'unexpected.mp4', metadata: [@science])
    fake_client = FakeDlmsClient.new(unexpected_upload_titles: ['Unexpected Upload Response'])
    job = build_job(fake_client, 'job-upload-5')

    job.perform(
      content_ids: [content.id],
      filters: { 'title' => 'Unexpected Upload Response' },
      queued_at: '2026-04-07T12:00:00Z',
      base_url: 'http://example.test'
    )

    report = JSON.parse(File.read(report_files.first))
    result = report.fetch('results').first

    assert_equal 'failed', result.fetch('status')
    assert_equal 'DLMS upload response missing content id', result.dig('error', 'message')
    assert_equal 0, report.dig('summary', 'uploaded')
    assert_equal 1, report.dig('summary', 'failed')
  end

  test 'reports metadata type and value alongside metadata lookup or creation errors' do
    content = create_content(title: 'Metadata Failure', filename: 'metadata-failure.pdf', metadata: [@science])
    fake_client = FakeDlmsClient.new(metadata_error_pairs: [['Subject', 'Science']])
    job = build_job(fake_client, 'job-upload-6')

    job.perform(
      content_ids: [content.id],
      filters: { 'title' => 'Metadata Failure' },
      queued_at: '2026-04-07T12:00:00Z',
      base_url: 'http://example.test'
    )

    report = JSON.parse(File.read(report_files.first))
    result = report.fetch('results').first

    assert_equal 'failed', result.fetch('status')
    assert_includes result.dig('error', 'message'), 'metadata: Subject=Science'
    assert_equal 'Subject', result.dig('error', 'body', 'metadata_type_name')
    assert_equal 'Science', result.dig('error', 'body', 'metadata_value')
    assert_equal 1, report.dig('summary', 'failed')
  end

  private

  def create_content(title:, filename:, metadata:)
    content = Content.new(
      title: title,
      display_title: "#{title} Display",
      description: "#{title} Description",
      year_of_publication: 2025,
      additional_notes: "#{title} Notes",
      user: @admin
    )
    content.file.attach(
      io: StringIO.new("%PDF-1.4 #{title}"),
      filename: filename,
      content_type: 'application/pdf'
    )
    content.save!
    content.metadata = metadata
    content
  end

  def cleanup_reports
    report_files.each { |path| File.delete(path) }
  end

  def build_job(fake_client, fixed_job_id)
    Class.new(ContentDlmsTransferJob) do
      define_method(:dlms_client) { |_base_url| fake_client }
      define_method(:job_id) { fixed_job_id }
    end.new
  end

  def report_files
    Dir[Rails.root.join('tmp/dlms_content_transfer_*.json')]
  end

  class FakeDlmsClient
    attr_reader :uploads

    def initialize(duplicate_filenames: [], duplicate_titles: [], duplicate_upload_titles: [], unexpected_upload_titles: [], metadata_error_pairs: [], failing_filenames: [])
      @duplicate_filenames = duplicate_filenames
      @duplicate_titles = duplicate_titles
      @duplicate_upload_titles = duplicate_upload_titles
      @unexpected_upload_titles = unexpected_upload_titles
      @metadata_error_pairs = metadata_error_pairs
      @failing_titles = failing_filenames.map { |filename| File.basename(filename, '.*').titleize }
      @uploads = []
      @metadata_sequence = 100
    end

    def content_exists?(file_name: nil, title: nil)
      @duplicate_filenames.include?(file_name) || @duplicate_titles.include?(title)
    end

    def ensure_metadata(type_name:, name:)
      if @metadata_error_pairs.include?([type_name, name])
        raise DlmsClient::RequestError.new(
          'DLMS request failed with status 400',
          status: 400,
          body: { 'error' => { 'non_field_errors' => ['The fields type, name must make a unique set.'] } }
        )
      end

      @metadata_sequence += 1
      { id: @metadata_sequence, created: type_name == 'Resource Type' && name == 'Book' }
    end

    def duplicate_content_error_reason(body)
      error_hash = body.is_a?(Hash) ? body['error'] || {} : {}
      return 'duplicate_filename' if Array(error_hash['content_file']).any? { |message| message.to_s.downcase.include?('already exist') }
      return 'duplicate_title' if Array(error_hash['title']).any? { |message| message.to_s.downcase.include?('already exist') }

      nil
    end

    def upload_content(file_path:, original_filename:, content_type:, fields:)
      if @duplicate_upload_titles.include?(fields['title'])
        raise DlmsClient::RequestError.new(
          'upload failed',
          status: 400,
          body: { 'error' => { 'title' => ['Content with this title already exists.'] } }
        )
      end

      if @unexpected_upload_titles.include?(fields['title'])
        raise DlmsClient::RequestError.new(
          'DLMS upload response missing content id',
          body: { 'id' => nil, 'title' => fields['title'] }
        )
      end

      if @failing_titles.include?(fields['title'])
        raise DlmsClient::RequestError.new('upload failed', status: 400, body: { 'title' => fields['title'] })
      end

      @uploads << { file_path: file_path, original_filename: original_filename, content_type: content_type, fields: fields }
      { 'id' => @uploads.length + 500 }
    end
  end
end
