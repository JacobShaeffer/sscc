require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'content-model@example.com',
      name: 'Content Model User',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
  end

  test 'updating non-file fields keeps the existing attachment valid' do
    content = create_content(title: 'Editable Content', filename: 'editable.pdf')
    original_blob_id = content.file.blob.id

    assert content.update(display_title: 'Updated Display', description: 'Updated Description')

    content.reload
    assert_equal original_blob_id, content.file.blob.id
    assert_equal 'Updated Display', content.display_title
    assert_equal 'Updated Description', content.description
  end

  test 'replacing a file with duplicate checksum on another record is invalid' do
    existing = create_content(title: 'Existing Content', filename: 'existing.pdf', file_body: '%PDF-1.4 duplicate')
    content = create_content(title: 'Target Content', filename: 'target.pdf', file_body: '%PDF-1.4 target')
    duplicate_blob = create_uploaded_blob(filename: 'replacement.pdf', body: '%PDF-1.4 duplicate')

    assert_not content.update(file: duplicate_blob.signed_id)
    assert_includes content.errors[:file], "File already exists with title: #{existing.title}"

    content.reload
    assert_equal 'target.pdf', content.file.filename.to_s
  end

  test 'replacing a file with the same filename differing only by case is invalid' do
    existing = create_content(title: 'Original Name', filename: 'Shared-Name.pdf', file_body: '%PDF-1.4 original')
    content = create_content(title: 'Rename Target', filename: 'rename-target.pdf', file_body: '%PDF-1.4 target')
    duplicate_blob = create_uploaded_blob(filename: 'shared-name.PDF', body: '%PDF-1.4 replacement')

    assert_not content.update(file: duplicate_blob.signed_id)
    assert_includes content.errors[:file], "A file with the same filename already exists with title: #{existing.title}"

    content.reload
    assert_equal 'rename-target.pdf', content.file.filename.to_s
  end

  test 'replacing a file with a similar but different filename is allowed' do
    create_content(title: 'Annual Report', filename: 'annual-report.pdf', file_body: '%PDF-1.4 annual')
    content = create_content(title: 'Quarterly Report', filename: 'quarterly-report.pdf', file_body: '%PDF-1.4 quarterly')
    replacement_blob = create_uploaded_blob(filename: 'report.pdf', body: '%PDF-1.4 replacement')

    assert content.update(file: replacement_blob.signed_id)

    content.reload
    assert_equal 'report.pdf', content.file.filename.to_s
  end

  test 'text fields reject leading and trailing whitespace' do
    content = create_content(title: 'Boundary Validation', filename: 'boundary-validation.pdf')
    fields = {
      title: 'Title',
      display_title: 'Display Title',
      description: 'Description',
      additional_notes: 'Additional Notes'
    }

    fields.each do |attribute, valid_value|
      [" ", "\t", "\n", "\u00A0"].each do |whitespace|
        ["#{whitespace}#{valid_value}", "#{valid_value}#{whitespace}"].each do |invalid_value|
          content.public_send("#{attribute}=", invalid_value)

          assert_not content.valid?, "expected #{attribute} to reject #{invalid_value.inspect}"
          assert_includes content.errors[attribute], 'must not have leading or trailing whitespace'
        end
      end

      content.public_send("#{attribute}=", valid_value)
    end
  end

  test 'text fields allow internal whitespace and blank optional notes' do
    content = create_content(title: 'Internal Whitespace', filename: 'internal-whitespace.pdf')

    content.assign_attributes(
      title: 'Internal Title',
      display_title: 'Internal Display Title',
      description: "First line\nSecond line",
      additional_notes: nil
    )

    assert content.valid?
  end

  private

  def create_content(title:, filename:, file_body: nil)
    content = Content.new(
      title: title,
      display_title: "#{title} Display",
      description: "#{title} Description",
      year_of_publication: 2024,
      additional_notes: "#{title} Notes",
      user: @user
    )
    content.file.attach(
      io: StringIO.new(file_body || "%PDF-1.4 #{title}"),
      filename: filename,
      content_type: 'application/pdf'
    )
    content.save!
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
