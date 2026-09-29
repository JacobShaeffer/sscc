# Run with:
#   bin/rails runner script/trim_content_whitespace.rb
#   bin/rails runner script/trim_content_whitespace.rb --dry-run
#
# An optional first argument changes the report location:
#   bin/rails runner script/trim_content_whitespace.rb tmp/my_report.txt
#   bin/rails runner script/trim_content_whitespace.rb --dry-run tmp/my_report.txt

require 'fileutils'
require 'pathname'
require 'set'

class ContentWhitespaceTrimmer
  TRIMMABLE_FIELDS = %i[title display_title description additional_notes].freeze
  UNIQUE_FIELDS = %i[title].freeze
  DEFAULT_REPORT_PATH = Rails.root.join('tmp/content_whitespace_duplicates.txt').freeze

  def initialize(report_path: DEFAULT_REPORT_PATH, dry_run: false)
    @report_path = Pathname.new(report_path.to_s)
    @report_path = Rails.root.join(@report_path) unless @report_path.absolute?
    @dry_run = dry_run
  end

  def run
    duplicate_groups = []
    resources_updated = 0
    fields_updated = 0
    planned_changes = []

    Content.transaction do
      contents = Content.lock.order(:id).to_a
      duplicate_groups = find_duplicate_groups(contents)
      conflicting_title_ids = duplicate_groups.flat_map do |group|
        group.fetch(:entries).map { |entry| entry.fetch(:content).id }
      end.to_set

      now = Time.current

      contents.each do |content|
        updates = trimmed_updates(content, conflicting_title_ids)
        next if updates.empty?

        fields_updated += updates.length
        resources_updated += 1
        planned_changes << { content: content, fields: updates.keys }
        content.update_columns(updates.merge(updated_at: now)) unless @dry_run
      end
    end

    write_report(duplicate_groups)
    print_planned_changes(planned_changes) if @dry_run

    action = @dry_run ? 'Would trim' : 'Trimmed'
    puts "#{action} #{fields_updated} field(s) on #{resources_updated} content resource(s)."
    puts "Wrote duplicate report to #{@report_path}."
    puts "Skipped title changes for #{affected_resource_count(duplicate_groups)} content resource(s) " \
         "in #{duplicate_groups.length} duplicate group(s)."
    puts 'Dry run complete; no database records were changed.' if @dry_run
  end

  private

  def find_duplicate_groups(contents)
    UNIQUE_FIELDS.flat_map do |field|
      entries = contents.map do |content|
        original_value = content.public_send(field)

        {
          content: content,
          original_value: original_value,
          trimmed_value: trim(original_value)
        }
      end

      entries
        .reject { |entry| entry.fetch(:trimmed_value).nil? }
        .group_by { |entry| entry.fetch(:trimmed_value).downcase }
        .sort_by { |normalized_value, _entries| normalized_value }
        .filter_map do |normalized_value, grouped_entries|
          next unless grouped_entries.length > 1
          next unless grouped_entries.any? do |entry|
            entry.fetch(:original_value) != entry.fetch(:trimmed_value)
          end

          {
            field: field,
            normalized_value: normalized_value,
            entries: grouped_entries
          }
        end
    end
  end

  def trimmed_updates(content, conflicting_title_ids)
    TRIMMABLE_FIELDS.each_with_object({}) do |field, updates|
      next if field == :title && conflicting_title_ids.include?(content.id)

      original_value = content.public_send(field)
      trimmed_value = trim(original_value)
      updates[field] = trimmed_value if original_value != trimmed_value
    end
  end

  def trim(value)
    return value unless value.is_a?(String)

    value.sub(/\A[[:space:]]+/, '').sub(/[[:space:]]+\z/, '')
  end

  def write_report(duplicate_groups)
    FileUtils.mkdir_p(@report_path.dirname)
    File.write(@report_path, report(duplicate_groups))
  end

  def print_planned_changes(planned_changes)
    planned_changes.each do |change|
      content = change.fetch(:content)
      puts "Would trim content #{content.id} #{content.title.inspect}: " \
           "#{change.fetch(:fields).join(', ')}"
    end
  end

  def report(duplicate_groups)
    lines = [
      "Total resources: #{affected_resource_count(duplicate_groups)}",
      "Total duplicates: #{duplicate_groups.length}",
      ''
    ]

    if duplicate_groups.empty?
      lines << 'No duplicate conflicts were found.'
    else
      duplicate_groups.each_with_index do |group, index|
        lines << "Duplicate #{index + 1}"
        lines << "Field: #{group.fetch(:field)}"
        lines << "Value after trimming (case-insensitive): #{group.fetch(:normalized_value).inspect}"
        lines << 'Content titles:'

        group.fetch(:entries).each do |entry|
          content = entry.fetch(:content)
          lines << "- #{content.title.inspect} (content ID: #{content.id})"
        end

        lines << ''
      end
    end

    "#{lines.join("\n").rstrip}\n"
  end

  def affected_resource_count(duplicate_groups)
    duplicate_groups
      .flat_map { |group| group.fetch(:entries).map { |entry| entry.fetch(:content).id } }
      .uniq
      .length
  end
end

arguments = ARGV.dup
dry_run = !!arguments.delete('--dry-run')

if arguments.length > 1 || arguments.any? { |argument| argument.start_with?('--') }
  raise ArgumentError, 'Usage: bin/rails runner script/trim_content_whitespace.rb [--dry-run] [REPORT_PATH]'
end

report_path = arguments.first || ContentWhitespaceTrimmer::DEFAULT_REPORT_PATH
ContentWhitespaceTrimmer.new(report_path: report_path, dry_run: dry_run).run
