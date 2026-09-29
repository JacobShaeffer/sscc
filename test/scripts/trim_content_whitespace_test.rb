require 'test_helper'
require 'tempfile'

class TrimContentWhitespaceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'content-whitespace-script@example.com',
      name: 'Content Whitespace Script User',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
  end

  test 'trims content fields while reporting and preserving conflicting titles' do
    first_conflict = create_content(title: 'Title 1', filename: 'title-1.pdf')
    second_conflict = create_content(title: 'Temporary 1', filename: 'temporary-1.pdf')
    third_conflict = create_content(title: 'Temporary 2', filename: 'temporary-2.pdf')
    safe_content = create_content(title: 'Title 2', filename: 'title-2.pdf')

    first_conflict.update_columns(display_title: " Display 1\t")
    second_conflict.update_columns(title: ' title 1 ', description: " Description 2\n")
    third_conflict.update_columns(title: "TITLE 1\t", additional_notes: "\u00A0Notes 3\u00A0")
    safe_content.update_columns(
      title: ' Title 2 ',
      display_title: ' Display 2 ',
      description: "\tDescription 4\n",
      additional_notes: ' Notes 4 '
    )

    metadata_type = MetadataType.create!(name: 'Subject', order: 1, user: @user)
    metadatum = Metadatum.create!(name: 'Science', metadata_type: metadata_type, user: @user)
    first_conflict.metadata << metadatum
    metadatum.update_columns(name: ' Science ')

    Tempfile.create(['content-whitespace-duplicates', '.txt']) do |report_file|
      report_path = report_file.path
      report_file.close

      dry_run_output = with_argv('--dry-run', report_path) do
        capture_io { load Rails.root.join('script/trim_content_whitespace.rb') }.first
      end

      assert_includes dry_run_output, "Would trim content #{safe_content.id}"
      assert_includes dry_run_output, 'Dry run complete; no database records were changed.'
      assert_equal ' Title 2 ', safe_content.reload.title
      assert_equal " Display 1\t", first_conflict.reload.display_title

      capture_io do
        ContentWhitespaceTrimmer.new(report_path: report_path).run
      end

      report = File.read(report_path)

      assert_match(/\ATotal resources: 3\nTotal duplicates: 1\n/, report)
      assert_includes report, 'Field: title'
      assert_includes report, '"Title 1"'
      assert_includes report, '" title 1 "'
      assert_includes report, '"TITLE 1\\t"'
    end

    assert_equal 'Title 1', first_conflict.reload.title
    assert_equal 'Display 1', first_conflict.display_title
    assert_equal ' title 1 ', second_conflict.reload.title
    assert_equal 'Description 2', second_conflict.description
    assert_equal "TITLE 1\t", third_conflict.reload.title
    assert_equal 'Notes 3', third_conflict.additional_notes

    safe_content.reload
    assert_equal 'Title 2', safe_content.title
    assert_equal 'Display 2', safe_content.display_title
    assert_equal 'Description 4', safe_content.description
    assert_equal 'Notes 4', safe_content.additional_notes

    assert_equal ' Science ', metadatum.reload.name
  end

  private

  def create_content(title:, filename:)
    content = Content.new(
      title: title,
      display_title: "#{title} Display",
      description: "#{title} Description",
      additional_notes: "#{title} Notes",
      user: @user
    )
    content.file.attach(
      io: StringIO.new("%PDF-1.4 #{title}"),
      filename: filename,
      content_type: 'application/pdf'
    )
    content.save!
    content
  end

  def with_argv(*arguments)
    original_arguments = ARGV.dup
    ARGV.replace(arguments)
    yield
  ensure
    ARGV.replace(original_arguments)
  end
end
