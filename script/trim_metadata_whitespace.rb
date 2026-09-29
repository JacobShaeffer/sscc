# Run with:
#   bin/rails runner script/trim_metadata_whitespace.rb
#   bin/rails runner script/trim_metadata_whitespace.rb --dry-run

require 'set'

class MetadataWhitespaceTrimmer
  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  def run
    stats = {
      renamed_values: 0,
      replaced_values: 0,
      moved_associations: 0,
      removed_duplicate_associations: 0
    }

    Metadatum.transaction do
      metadata = Metadatum.lock.order(:metadata_type_id, :id).to_a
      ensure_values_can_be_trimmed!(metadata)

      grouped_values(metadata).each_value do |group|
        dirty_values = group.select { |metadatum| needs_trimming?(metadatum.name) }
        next if dirty_values.empty?

        clean_values = group - dirty_values

        if clean_values.any?
          target = clean_values.min_by(&:id)
          replace_all(dirty_values, target, stats)
        else
          target = dirty_values.min_by(&:id)
          trimmed_name = trim(target.name)
          puts trim_preview(target, trimmed_name) if @dry_run
          target.update!(name: trimmed_name) unless @dry_run
          stats[:renamed_values] += 1

          replace_all(dirty_values - [target], target, stats, target_name: trimmed_name)
        end
      end
    end

    action = @dry_run ? 'Would trim' : 'Trimmed'
    replace_action = @dry_run ? 'Would replace' : 'Replaced'
    association_action = @dry_run ? 'Would move' : 'Moved'
    duplicate_action = @dry_run ? 'would remove' : 'removed'

    puts "#{action} #{stats[:renamed_values]} metadata value(s) in place."
    puts "#{replace_action} #{stats[:replaced_values]} colliding metadata value(s)."
    puts "#{association_action} #{stats[:moved_associations]} content association(s) and #{duplicate_action} " \
         "#{stats[:removed_duplicate_associations]} duplicate association(s)."
    puts 'Dry run complete; no database records were changed.' if @dry_run
  end

  private

  def grouped_values(metadata)
    metadata.group_by do |metadatum|
      [metadatum.metadata_type_id, trim(metadatum.name).downcase]
    end
  end

  def ensure_values_can_be_trimmed!(metadata)
    invalid_ids = metadata.filter_map do |metadatum|
      metadatum.id if trim(metadatum.name).blank?
    end
    return if invalid_ids.empty?

    raise "Cannot trim metadata values to an empty name. Metadatum IDs: #{invalid_ids.join(', ')}"
  end

  def needs_trimming?(value)
    value != trim(value)
  end

  def trim(value)
    return value unless value.is_a?(String)

    value.sub(/\A[[:space:]]+/, '').sub(/[[:space:]]+\z/, '')
  end

  def replace_all(sources, target, stats, target_name: target.name)
    if @dry_run
      target_content_ids = target.content_metadata.pluck(:content_id).to_set

      sources.each do |source|
        puts replace_preview(source, target, target_name)
        simulate_replace(source, target_content_ids, stats)
      end
    else
      sources.each { |source| replace(source, target, stats) }
    end
  end

  def simulate_replace(source, target_content_ids, stats)
    source.content_metadata.pluck(:content_id).each do |content_id|
      if target_content_ids.include?(content_id)
        stats[:removed_duplicate_associations] += 1
      else
        target_content_ids << content_id
        stats[:moved_associations] += 1
      end
    end

    stats[:replaced_values] += 1
  end

  def trim_preview(metadatum, trimmed_name)
    "Would trim metadatum #{metadatum.id} in metadata type #{metadatum.metadata_type_id}: " \
      "#{metadatum.name.inspect} -> #{trimmed_name.inspect}"
  end

  def replace_preview(source, target, target_name)
    "Would replace metadatum #{source.id} #{source.name.inspect} with metadatum " \
      "#{target.id} #{target_name.inspect} in metadata type #{target.metadata_type_id}"
  end

  def replace(source, target, stats)
    source.content_metadata.find_each do |content_metadatum|
      existing_association = ContentMetadatum.find_by(
        content_id: content_metadatum.content_id,
        metadatum_id: target.id
      )

      if existing_association
        content_metadatum.destroy!
        stats[:removed_duplicate_associations] += 1
      else
        content_metadatum.update!(metadatum_id: target.id)
        stats[:moved_associations] += 1
      end
    end

    source.destroy!
    stats[:replaced_values] += 1
  end
end

arguments = ARGV.dup
dry_run = !!arguments.delete('--dry-run')

unless arguments.empty?
  raise ArgumentError, 'Usage: bin/rails runner script/trim_metadata_whitespace.rb [--dry-run]'
end

MetadataWhitespaceTrimmer.new(dry_run: dry_run).run
