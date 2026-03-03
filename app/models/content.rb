class Content < ApplicationRecord
  belongs_to :user
  has_many :content_metadata, dependent: :destroy
  has_many :metadata, through: :content_metadata

  has_one_attached :file

  validates :title, presence: true, allow_blank: false,
                    uniqueness: { case_sensitive: false, message: 'Title must be unique' }
  validates :display_title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :file, presence: true,
                   blob: { content_type: ['application/pdf', 'audio/mpeg', 'video/mp4'], size_range: 0..(256.megabytes) }

  validate :file_checksum_must_be_unique
  validate :file_filename_must_be_unique


  # List of filterable columns
  FILTERABLE_COLUMNS = %i[title user display_title description year_of_publication year_of_publication_from
                          year_of_publication_to filename created_after created_before].freeze
  FILTER_PARAMS = [FILTERABLE_COLUMNS + %i[sort direction], :items_per_page, { columns: [], metadata: {} }].freeze

  scope :by_title,                      ->(title) { where('lower(title) LIKE lower(?)', "%#{title}%") }
  scope :by_display_title,              lambda { |display_title|
    where('lower(display_title) LIKE lower(?)', "%#{display_title}%")
  }
  scope :by_user, lambda { |user|
    joins(:user).where('lower(users.name) LIKE lower(?)', "%#{user}%")
  }
  scope :by_description, lambda { |description|
    where('lower(description) LIKE lower(?)', "%#{description}%")
  }
  scope :by_year_of_publication_from, lambda { |year_of_publication_from|
    where('year_of_publication >= ?', year_of_publication_from)
  }
  scope :by_year_of_publication_to, lambda { |year_of_publication_to|
    where('year_of_publication <= ?', year_of_publication_to)
  }
  scope :by_filename, lambda { |filename|
    joins(file_attachment: :blob).where('lower(active_storage_blobs.filename) LIKE lower(?)', "%#{filename}%")
  }
  scope :by_created_after, ->(created_after) { where('contents.created_at >= ?', created_after) }
  scope :by_created_before, ->(created_before) { where('contents.created_at <= ?', created_before) }

  # scope :by_metadata_type_and_metadata, ->  (type_id, metadata) { where_assoc_exists(:metadata, ['metadata_type_id = ?', type_id]).where_assoc_exists(:metadata, ['lower(name) LIKE lower(?)', "%#{metadata}%"]) }
  # scope :by_metadata_type_and_metadata, ->  (type_id, metadata) { where_assoc_exists(:metadata, ['metadata_type_id = ? AND lower(name) LIKE lower(?)', type_id, "%#{metadata}%"]).where_assoc_exists(:metadata, ['lower(name) LIKE lower(?)', "%#{metadata}%"]) }
  scope :by_metadata_type_and_metadata, lambda { |type_id, metadata|
    joins(:metadata).where(metadata: { metadata_type_id: type_id }).where('LOWER(metadata.name) LIKE LOWER(?)', "%#{metadata}%").distinct
  }

  def self.filter(filters)
    # puts "\e[38;2;0;255;0m#{filters}\e[0m"
    # start by getting all the records
    filtered = Content.all

    # filter by each column if there is a value
    filtered = filtered.by_title(filters['title']) if filters['title'].present?
    filtered = filtered.by_display_title(filters['display_title']) if filters['display_title'].present?
    filtered = filtered.by_user(filters['user']) if filters['user'].present?
    filtered = filtered.by_description(filters['description']) if filters['description'].present?
    if filters['year_of_publication_from'].present?
      filtered = filtered.by_year_of_publication_from(filters['year_of_publication_from'])
    end
    if filters['year_of_publication_to'].present?
      filtered = filtered.by_year_of_publication_to(filters['year_of_publication_to'])
    end
    filtered = filtered.by_filename(filters['filename']) if filters['filename'].present?
    filtered = filtered.by_created_after(filters['created_after']) if filters['created_after'].present?
    filtered = filtered.by_created_before(filters['created_before']) if filters['created_before'].present?

    # dynamc filtering for metadata
    if filters['metadata'].present?
      filters['metadata'].keys.each do |metadata_type_id|
        if filters['metadata'][metadata_type_id].present?
          filtered = filtered.by_metadata_type_and_metadata(metadata_type_id, filters['metadata'][metadata_type_id])
        end
      end
    end

    # if there is a direction sort by given sort column
    if filters['direction'].present? && filters['direction'] != 'none'
      case filters['sort']
        # user is a special case because it is a belongs_to relationship
      when 'user'
        sorted = filtered.includes(:user).order("users.name #{filters['direction']}")
      when 'filename'
        sorted = filtered.includes(file_attachment: :blob).order("active_storage_blobs.filename #{filters['direction']}")
      else
        # Check if the sort key is a metadata_type id
        if MetadataType.exists?(filters['sort'])
          # sorted = filtered.includes(:metadata).order("metadata.name #{filters['direction']}")
          metadata_type_id = filters['sort']
          join_sql = ActiveRecord::Base.sanitize_sql_array([<<~SQL, metadata_type_id])
            LEFT JOIN content_metadata cm
              ON cm.content_id = contents.id
            LEFT JOIN metadata m
              ON m.id = cm.metadatum_id
              AND m.metadata_type_id = ?
          SQL

          sorted = filtered
                   .joins(join_sql)
                   .group('contents.id')
                   .order(Arel.sql("COALESCE(MIN(LOWER(m.name)), '') #{filters['direction']}, contents.id"))
        else
          sorted = filtered.order("#{filters['sort']} #{filters['direction']}")
        end
      end
    else
      # return the filtered results if there is no sort or direction
      sorted = filtered
    end

    sorted
  end

  # List of metadata for a given metadata type
  # Used in Content View
  def metadatas(metadata_type_id)
    metadata_record = metadata.where(metadata_type_id: metadata_type_id)
    if metadata_record.present?
      metadata_record.map { |m| m.name }
    else
      []
    end
  end

  # List of metadata for a given metadata type name
  def metadatas_by_name(metadata_type_name)
    metadataType = MetadataType.find_by(name: metadata_type_name)
    # FIXME: metadataType might be nil
    if metadataType.nil?
      ['']
    else
      metadatas(metadataType.id)
    end
  end

  def file_checksum_must_be_unique
    return unless ActiveStorage::Blob.where(checksum: file.blob.checksum).exists?

    existing_file_title = Content.joins(file_attachment: :blob).where(active_storage_blobs: { checksum: file.blob.checksum }).first.title

    errors.add(:file, "File already exists with title: #{existing_file_title}")
  end

  def file_filename_must_be_unique
    return if errors.include?(:file)
    filename = file.blob.filename.to_s
    return unless ActiveStorage::Blob.where(filename: filename).exists?

    existing_file_title = Content.by_filename(filename).first.title

    errors.add(:file, "A file with the same filename already exists with title: #{existing_file_title}")
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << [
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
      ].concat(MetadataType.all.map { |type| type.name })
      all.each do |content|
        csv << [
          content.title,
          content.display_title,
          content.file.filename.to_s, # does this work?
          content.description,
          '', # check this (Modified On)
          '', # check this (Copywrite Notes)
          content.additional_notes,
          content.year_of_publication,
          '', # check this (Reviewed On)
          'True',
          'False',
          content.file.byte_size
        ].concat(MetadataType.all.map { |type| content.metadatas_by_name(type.name).join(' | ') })
        # multiple values should be separated by a pipe (|)
      end
    end
  end

  def self.to_xlsx
    require 'caxlsx'

    package = Axlsx::Package.new
    workbook = package.workbook

    # Create a new worksheet
    workbook.add_worksheet(name: 'Contents') do |sheet|
      # Build the header row
      header_row = [
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
      ].concat(MetadataType.all.map(&:name))

      # Add header row
      sheet.add_row(header_row)

      # Iterate over all content records
      all.find_each do |content|
        row_data = [
          content.title,
          content.display_title,
          content.file.filename.to_s,
          content.description,
          '',                           # "Modified On" placeholder
          '',                           # "Copyright Notes" placeholder
          content.additional_notes,
          content.year_of_publication,
          '',                           # "Reviewed On" placeholder
          'True',
          'False',
          content.file.byte_size
        ].concat(
          MetadataType.all.map { |type| content.metadatas_by_name(type.name).join(' | ') }
        )

        sheet.add_row(row_data)
      end
    end

    # Return the raw XLSX stream data (e.g. for sending as a file download)
    package.to_stream.read
  end
end
