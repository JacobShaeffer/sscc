require 'test_helper'
require 'zip'

class ContentExporterTest < ActiveSupport::TestCase
  test 'to_xlsx includes shared exporter headers and row values' do
    admin = User.create!(
      email: 'admin-export@example.com',
      name: 'Admin Export',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    metadata_type = MetadataType.create!(name: 'Subject', order: 1, user: admin)
    metadatum = Metadatum.create!(name: 'Science', metadata_type: metadata_type, user: admin)
    content = Content.new(
      title: 'Spreadsheet Title',
      display_title: 'Spreadsheet Display',
      description: 'Spreadsheet Description',
      year_of_publication: 2026,
      additional_notes: 'Spreadsheet Notes',
      user: admin
    )
    content.file.attach(
      io: StringIO.new('%PDF-1.4 spreadsheet'),
      filename: 'spreadsheet.pdf',
      content_type: 'application/pdf'
    )
    content.save!
    content.metadata = [metadatum]

    xlsx_data = Content.where(id: content.id).to_xlsx

    Zip::File.open_buffer(StringIO.new(xlsx_data)) do |zip|
      workbook_text = String.new
      shared_strings_entry = zip.find_entry('xl/sharedStrings.xml')
      workbook_text << shared_strings_entry.get_input_stream.read if shared_strings_entry
      workbook_text << zip.find_entry('xl/worksheets/sheet1.xml').get_input_stream.read

      assert_includes workbook_text, 'Spreadsheet Title'
      assert_includes workbook_text, 'Spreadsheet Display'
      assert_includes workbook_text, 'Spreadsheet Description'
      assert_includes workbook_text, 'Spreadsheet Notes'
      assert_includes workbook_text, 'Science'
      assert_includes workbook_text, 'Active'
      assert_includes workbook_text, 'True'
      assert_includes workbook_text, 'Subject'
    end
  end
end
