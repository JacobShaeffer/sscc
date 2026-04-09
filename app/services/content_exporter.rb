class ContentExporter
  BASE_HEADERS = [
    'Title',
    'Display Title',
    'File Name',
    'Description',
    'Modified On',
    'Copyright Notes',
    'Additional Notes',
    'Year Published',
    'Reviewed On',
    'Active',
    'Duplicatable',
    'Filesize'
  ].freeze

  def self.headers(metadata_types: MetadataType.all.order(:order).to_a)
    BASE_HEADERS + metadata_types.map(&:name)
  end

  def self.metadata_values(content, metadata_types: MetadataType.all.order(:order).to_a)
    metadata_by_type = content.metadata.group_by(&:metadata_type_id)

    metadata_types.each_with_object({}) do |metadata_type, values|
      values[metadata_type.name] = Array(metadata_by_type[metadata_type.id]).map(&:name)
    end
  end

  def self.row_hash(content, metadata_types: MetadataType.all.order(:order).to_a)
    row = {
      'Title' => content.title,
      'Display Title' => content.display_title,
      'File Name' => content.file.filename.to_s,
      'Description' => content.description,
      'Modified On' => '',
      'Copyright Notes' => '',
      'Additional Notes' => content.additional_notes,
      'Year Published' => content.year_of_publication,
      'Reviewed On' => '',
      'Active' => 'True',
      'Duplicatable' => 'False',
      'Filesize' => content.file.byte_size
    }

    metadata_values(content, metadata_types: metadata_types).each do |metadata_type_name, values|
      row[metadata_type_name] = values.join(' | ')
    end

    row
  end

  def self.row_values(content, metadata_types: MetadataType.all.order(:order).to_a)
    row = row_hash(content, metadata_types: metadata_types)
    headers(metadata_types: metadata_types).map { |header| row[header] }
  end

  def self.dlms_fields(content, metadata_types: MetadataType.all.order(:order).to_a)
    row = row_hash(content, metadata_types: metadata_types)

    {
      'title' => row['Title'],
      'display_title' => row['Display Title'],
      'description' => row['Description'],
      'additional_notes' => row['Additional Notes'],
      'published_date' => published_date(row['Year Published']),
      'reviewed_on' => reviewed_on,
      'active' => row['Active']
    }.compact
  end

  def self.published_date(year)
    return if year.blank?

    Date.new(year.to_i, 1, 1).iso8601
  end

  def self.reviewed_on
    Date.current.iso8601
  end
end
