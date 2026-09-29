require 'test_helper'

class MetadataTypes::MetadataControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(
      email: 'metadata-controller@example.com',
      name: 'Metadata Controller Admin',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    @metadata_type = MetadataType.create!(name: 'Subject', order: 1, user: @admin)
    @source = Metadatum.create!(name: 'Old Subject', metadata_type: @metadata_type, user: @admin)
    @replacement = Metadatum.create!(name: 'New Subject', metadata_type: @metadata_type, user: @admin)

    sign_in @admin
  end

  test 'info renders a patch form with the replacement id parameter' do
    get info_metadata_type_metadatum_path(@metadata_type, @source, format: :turbo_stream)

    assert_response :success
    assert_select "form[action='#{replace_metadata_type_metadatum_path(@metadata_type, @source)}'][method='post']" do
      assert_select "input[name='_method'][value='patch']", count: 1
      assert_select "input[name='replace_with'][type='number']", count: 1
    end
  end

  test 'replace moves every content association and destroys the source metadata value' do
    source_only_content = create_content(title: 'Source Only', filename: 'source-only.pdf')
    source_only_content.metadata = [@source]
    content_with_both = create_content(title: 'Both Values', filename: 'both-values.pdf')
    content_with_both.metadata = [@source, @replacement]

    patch replace_metadata_type_metadatum_path(@metadata_type, @source, format: :turbo_stream),
          params: { replace_with: @replacement.id }

    assert_response :success
    assert_not Metadatum.exists?(@source.id)
    assert_equal [@replacement.id], source_only_content.reload.metadatum_ids
    assert_equal [@replacement.id], content_with_both.reload.metadatum_ids
    assert_equal 2, ContentMetadatum.where(metadatum: @replacement).count
    assert_includes response.body, %(target="metadatum_#{@source.id}")
  end

  test 'replace rejects metadata from a different type without changing data' do
    other_type = MetadataType.create!(name: 'Resource Type', order: 2, user: @admin)
    other_metadatum = Metadatum.create!(name: 'Book', metadata_type: other_type, user: @admin)
    content = create_content(title: 'Unchanged Content', filename: 'unchanged.pdf')
    content.metadata = [@source]

    patch replace_metadata_type_metadatum_path(@metadata_type, @source, format: :turbo_stream),
          params: { replace_with: other_metadatum.id }

    assert_response :unprocessable_entity
    assert Metadatum.exists?(@source.id)
    assert_equal [@source.id], content.reload.metadatum_ids
    assert_includes response.body, 'Both metadata values must have the same metadata type.'
  end

  test 'replace rejects replacing a metadata value with itself' do
    patch replace_metadata_type_metadatum_path(@metadata_type, @source, format: :turbo_stream),
          params: { replace_with: @source.id }

    assert_response :unprocessable_entity
    assert Metadatum.exists?(@source.id)
    assert_includes response.body, 'A metadata value cannot replace itself.'
  end

  private

  def create_content(title:, filename:)
    content = Content.new(
      title: title,
      display_title: "#{title} Display",
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
    content
  end
end
