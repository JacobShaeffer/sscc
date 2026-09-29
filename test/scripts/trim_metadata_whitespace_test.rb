require 'test_helper'

class TrimMetadataWhitespaceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'metadata-whitespace-script@example.com',
      name: 'Metadata Whitespace Script User',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    @subject_type = MetadataType.create!(name: 'Subject', order: 1, user: @user)
    @other_type = MetadataType.create!(name: 'Other Subject', order: 2, user: @user)
  end

  test 'trims values and replaces whitespace variants with their clean value' do
    clean_science = create_metadatum('Science', @subject_type)
    dirty_science = create_metadatum('Temporary Science', @subject_type)
    dirty_science.update_columns(name: ' Science ')

    dirty_only_content = create_content('Dirty Science Content', 'dirty-science.pdf')
    duplicate_content = create_content('Duplicate Science Content', 'duplicate-science.pdf')
    ContentMetadatum.create!(content: dirty_only_content, metadatum: dirty_science)
    ContentMetadatum.create!(content: duplicate_content, metadatum: clean_science)
    ContentMetadatum.create!(content: duplicate_content, metadatum: dirty_science)

    topic = create_metadatum('Temporary Topic', @subject_type)
    topic.update_columns(name: "\tTopic\n")

    other_type_science = create_metadatum('Temporary Other Science', @other_type)
    other_type_science.update_columns(name: "\u00A0Science\u00A0")

    first_history = create_metadatum('Temporary History 1', @subject_type)
    second_history = create_metadatum('Temporary History 2', @subject_type)
    first_history.update_columns(name: ' History')
    second_history.update_columns(name: 'history ')
    history_content = create_content('History Content', 'history.pdf')
    ContentMetadatum.create!(content: history_content, metadatum: second_history)

    dry_run_output = with_argv('--dry-run') do
      capture_io { load Rails.root.join('script/trim_metadata_whitespace.rb') }.first
    end

    assert_includes dry_run_output, "Would replace metadatum #{dirty_science.id}"
    assert_includes dry_run_output, "Would trim metadatum #{topic.id}"
    assert_includes dry_run_output, 'Would replace 2 colliding metadata value(s).'
    assert_includes dry_run_output, 'Dry run complete; no database records were changed.'
    assert Metadatum.exists?(dirty_science.id)
    assert_equal ' Science ', dirty_science.reload.name
    assert_equal "\tTopic\n", topic.reload.name

    output, = capture_io { MetadataWhitespaceTrimmer.new.run }

    assert_includes output, 'Trimmed 3 metadata value(s) in place.'
    assert_includes output, 'Replaced 2 colliding metadata value(s).'
    assert_includes output, 'Moved 2 content association(s) and removed 1 duplicate association(s).'

    assert_not Metadatum.exists?(dirty_science.id)
    assert_equal [clean_science.id], dirty_only_content.reload.metadata.ids
    assert_equal [clean_science.id], duplicate_content.reload.metadata.ids

    assert_equal 'Topic', topic.reload.name
    assert_equal 'Science', other_type_science.reload.name
    assert_equal @other_type.id, other_type_science.metadata_type_id

    assert_equal 'History', first_history.reload.name
    assert_not Metadatum.exists?(second_history.id)
    assert_equal [first_history.id], history_content.reload.metadata.ids
  end

  private

  def create_metadatum(name, metadata_type)
    Metadatum.create!(name: name, metadata_type: metadata_type, user: @user)
  end

  def create_content(title, filename)
    content = Content.new(
      title: title,
      display_title: "#{title} Display",
      description: "#{title} Description",
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
