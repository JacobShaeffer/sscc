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

  private

  def create_content(title:, filename:, metadata: [], display_title: nil)
    content = Content.new(
      title: title,
      display_title: display_title || "#{title} Display",
      description: "#{title} Description",
      year_of_publication: 2024,
      additional_notes: "#{title} Notes",
      user: @admin
    )
    content.file.attach(
      io: StringIO.new("%PDF-1.4 #{title}"),
      filename: filename,
      content_type: 'application/pdf'
    )
    content.save!
    content.metadata = metadata if metadata.any?
    content
  end
end
