require 'test_helper'

class ContentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    @admin = User.create!(
      email: 'admin-controller@example.com',
      name: 'Admin Controller',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    @volunteer = User.create!(
      email: 'volunteer-controller@example.com',
      name: 'Volunteer Controller',
      password: 'password123',
      password_confirmation: 'password123',
      role: :volunteer
    )
    @intern = User.create!(
      email: 'intern-controller@example.com',
      name: 'Intern Controller',
      password: 'password123',
      password_confirmation: 'password123',
      role: :intern
    )
    @metadata_type = MetadataType.create!(name: 'Subject', order: 1, user: @admin)
    @metadatum = Metadatum.create!(name: 'Science', metadata_type: @metadata_type, user: @admin)
    @matching_content = create_content(title: 'Matching Content', filename: 'matching.pdf', metadata: [@metadatum])
    create_content(title: 'Other Content', filename: 'other.pdf')
    @report_filename = 'dlms_content_transfer_test_report.json'
  end

  teardown do
    clear_enqueued_jobs
    report_path = Rails.root.join('tmp', @report_filename)
    File.delete(report_path) if File.exist?(report_path)
  end

  test 'admin can queue DLMS transfer with current content filters snapshot' do
    sign_in @admin

    get list_contents_path, params: {
      title: 'Matching',
      sort: 'title',
      direction: 'asc',
      items_per_page: '20',
      columns: ['title', @metadata_type.id.to_s],
      metadata: { @metadata_type.id.to_s => 'Science' }
    }

    assert_response :success

    assert_enqueued_with(job: ContentDlmsTransferJob) do
      get create_dlms_transfer_contents_path
    end

    job_args = enqueued_jobs.last[:args].first.deep_stringify_keys
    assert_equal [@matching_content.id], job_args['content_ids']
    assert_equal 'Matching', job_args.dig('filters', 'title')
    assert_equal 'Science', job_args.dig('filters', 'metadata', @metadata_type.id.to_s)
    assert_equal '20', job_args.dig('filters', 'items_per_page')
    assert_equal ['title', @metadata_type.id.to_s], job_args.dig('filters', 'columns')
  end

  test 'general search matches display title without metadata' do
    sign_in @admin

    content = create_content(
      title: 'Display Title Match',
      display_title: 'duplicate2',
      filename: 'display-title-match.pdf'
    )

    get list_contents_path, params: { general: '2' }

    assert_response :success
    assert_includes response.body, "/contents/#{content.id}"
  end

  test 'admin can download a DLMS report' do
    sign_in @admin
    File.write(Rails.root.join('tmp', @report_filename), '{"success":true}')

    get download_dlms_report_contents_path(filename: @report_filename)

    assert_response :success
    assert_equal 'application/json', response.media_type
    assert_includes response.body, '"success":true'
  end

  test 'non-admin users are denied DLMS transfer actions' do
    sign_in @volunteer
    File.write(Rails.root.join('tmp', @report_filename), '{"success":true}')

    get create_dlms_transfer_contents_path
    assert_redirected_to root_path

    get download_dlms_report_contents_path(filename: @report_filename)
    assert_redirected_to root_path
  end

  test 'updating content without a file param keeps the existing attachment' do
    sign_in @admin

    content = create_content(title: 'Editable Update', filename: 'editable-update.pdf')
    original_blob_id = content.file.blob.id

    get edit_content_path(content)

    assert_response :success
    assert_select "input[name='content[file]'][type='hidden']", count: 0

    patch content_path(content), params: {
      content: {
        title: content.title,
        display_title: 'Updated Display Title',
        description: 'Updated description',
        year_of_publication: content.year_of_publication,
        additional_notes: content.additional_notes
      }
    }

    assert_redirected_to content_path(content)

    content.reload
    assert_equal original_blob_id, content.file.blob.id
    assert_equal 'Updated Display Title', content.display_title
    assert_equal 'Updated description', content.description
  end

  test 'updating content with a duplicate uploaded file fails' do
    sign_in @admin

    existing = create_content(title: 'Duplicate Source', filename: 'duplicate-source.pdf', file_body: '%PDF-1.4 duplicate')
    content = create_content(title: 'Duplicate Target', filename: 'duplicate-target.pdf', file_body: '%PDF-1.4 target')
    duplicate_blob = create_uploaded_blob(filename: 'replacement.pdf', body: '%PDF-1.4 duplicate')
    original_blob_id = content.file.blob.id

    patch content_path(content), params: {
      content: {
        title: content.title,
        display_title: content.display_title,
        description: content.description,
        year_of_publication: content.year_of_publication,
        additional_notes: content.additional_notes,
        file: duplicate_blob.signed_id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "File already exists with title: #{existing.title}"

    content.reload
    assert_equal original_blob_id, content.file.blob.id
  end

  test 'failed content creation preserves the direct upload for a successful retry' do
    sign_in @admin
    uploaded_blob = create_uploaded_blob(filename: 'retry-upload.pdf', body: '%PDF-1.4 retry upload')
    submitted_content = {
      title: @matching_content.title,
      display_title: 'Retry Display Title',
      description: 'Retry Description',
      year_of_publication: 2024,
      additional_notes: 'Retry Notes',
      file: uploaded_blob.signed_id,
      metadatum_ids: [@metadatum.id]
    }

    assert_no_difference('Content.count') do
      post contents_path, params: { content: submitted_content }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, 'Title must be unique'
    assert_select '.rails-bootstrap-forms-error-summary', count: 1
    assert_select "input[name='content[title]']", value: @matching_content.title
    assert_select "input[name='content[file]'][type='hidden']", count: 1 do |fields|
      assert_equal uploaded_blob.signed_id, fields.first['value']
      assert_equal 'true', fields.first['data-filepond-hidden-field']
    end
    assert_select "input[name='content[metadatum_ids][]'][value='#{@metadatum.id}'][checked]", count: 1

    assert_difference('Content.count', 1) do
      post contents_path, params: {
        content: submitted_content.merge(title: 'Successful Retry')
      }
    end

    created_content = Content.find_by!(title: 'Successful Retry')
    assert_redirected_to content_path(created_content)
    assert_equal uploaded_blob.id, created_content.file.blob.id
    assert_equal [@metadatum.id], created_content.metadatum_ids
  end

  test 'failed content update preserves the replacement direct upload' do
    sign_in @admin
    content = create_content(title: 'Update Retry', filename: 'update-retry.pdf')
    original_blob_id = content.file.blob.id
    replacement_blob = create_uploaded_blob(filename: 'update-replacement.pdf', body: '%PDF-1.4 replacement')

    patch content_path(content), params: {
      content: {
        title: @matching_content.title,
        display_title: content.display_title,
        description: content.description,
        year_of_publication: content.year_of_publication,
        additional_notes: content.additional_notes,
        file: replacement_blob.signed_id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, 'Title must be unique'
    assert_select "input[name='content[file]'][type='hidden']", count: 1 do |fields|
      assert_equal replacement_blob.signed_id, fields.first['value']
      assert_equal 'true', fields.first['data-filepond-hidden-field']
    end
    assert_equal original_blob_id, content.reload.file.blob.id
  end

  test 'updating content ignores preloaded blob urls submitted as file params' do
    sign_in @admin

    content = create_content(title: 'Preloaded Url Content', filename: 'preloaded-url.pdf')
    original_blob_id = content.file.blob.id

    patch content_path(content), params: {
      content: {
        title: content.title,
        display_title: 'Updated via URL Payload',
        description: 'Updated description',
        file: Rails.application.routes.url_helpers.rails_blob_path(content.file, only_path: true),
        year_of_publication: content.year_of_publication,
        additional_notes: content.additional_notes
      }
    }

    assert_redirected_to content_path(content)

    content.reload
    assert_equal original_blob_id, content.file.blob.id
    assert_equal 'Updated via URL Payload', content.display_title
  end

  test 'user below metadata type access level cannot add a new metadatum from content form' do
    sign_in @intern
    restricted_type = MetadataType.create!(
      name: 'Admin-only metadata',
      order: 2,
      access_level: User.roles.fetch(:admin),
      user: @admin
    )

    assert_no_difference('Metadatum.count') do
      get add_new_metadatum_contents_path(format: :turbo_stream), params: {
        metadata_type_id: restricted_type.id,
        target: "metadataBadge_#{restricted_type.id}_container",
        name: 'Restricted value'
      }
    end

    assert_response :forbidden
    assert_includes response.body, 'You do not have permission to add values for this metadata type.'
  end

  test 'user at metadata type access level can add a new metadatum from content form' do
    sign_in @intern
    intern_type = MetadataType.create!(
      name: 'Intern metadata',
      order: 2,
      access_level: User.roles.fetch(:intern),
      user: @admin
    )

    assert_difference('Metadatum.count', 1) do
      get add_new_metadatum_contents_path(format: :turbo_stream), params: {
        metadata_type_id: intern_type.id,
        target: "metadataBadge_#{intern_type.id}_container",
        name: 'Allowed value'
      }
    end

    assert_response :success
    assert_equal @intern, Metadatum.find_by!(metadata_type: intern_type, name: 'Allowed value').user
  end

  private

  def create_content(title:, filename:, metadata: [], display_title: nil, file_body: nil)
    content = Content.new(
      title: title,
      display_title: display_title || "#{title} Display",
      description: "#{title} Description",
      year_of_publication: 2024,
      additional_notes: "#{title} Notes",
      user: @admin
    )
    content.file.attach(
      io: StringIO.new(file_body || "%PDF-1.4 #{title}"),
      filename: filename,
      content_type: 'application/pdf'
    )
    content.save!
    content.metadata = metadata if metadata.any?
    content
  end

  def create_uploaded_blob(filename:, body:, content_type: 'application/pdf')
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(body),
      filename: filename,
      content_type: content_type
    )
  end
end
