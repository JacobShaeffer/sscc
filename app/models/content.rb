class Content < ApplicationRecord
  belongs_to :user
  belongs_to :copyright_permission
  has_many :content_metadata, dependent: :destroy
  has_many :metadata, through: :content_metadata

  has_one_attached :file

  validates :title, presence: true, allow_blank: false, uniqueness: { case_sensitive: false, message: "Title must be unique" }
  validates :display_title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :file, presence: true, blob: { content_type: ['application/pdf', 'audio/mpeg', 'video/mp4'], size_range: 0..(256.megabytes) }

  #List of searchable columns
  SEARCHABLE_COLUMNS = %i[ title user copyright_permission display_title description year_of_publication year_of_publication_from year_of_publication_to ].freeze
  FILTER_PARAMS = [SEARCHABLE_COLUMNS + %i[sort direction], :columns => [], :metadata => {}].freeze

  scope :by_title,                      ->  (title) { where('lower(title) LIKE lower(?)', "%#{title}%") }
  scope :by_display_title,              ->  (display_title) { where('lower(display_title) LIKE lower(?)', "%#{display_title}%") }
  scope :by_user,                       ->  (user) { joins(:user).where('lower(users.name) LIKE lower(?)', "%#{user}%") }
  scope :by_description,                ->  (description) { where('lower(description) LIKE lower(?)', "%#{description}%") }
  scope :by_year_of_publication_from,   ->  (year_of_publication_from) { where('year_of_publication >= ?', year_of_publication_from) }
  scope :by_year_of_publication_to,     ->  (year_of_publication_to) { where('year_of_publication <= ?', year_of_publication_to) }
  scope :by_copyright_permission,       ->  (permission) { joins(:copyright_permission).where('lower(copyright_permissions.organization_name) LIKE lower(?)', "%#{permission}%") }

  scope :by_metadata_type_and_metadata, ->  (type_id, metadata) { where_assoc_exists(:metadata, ['metadata_type_id = ?', type_id]).where_assoc_exists(:metadata, ['lower(name) LIKE lower(?)', "%#{metadata}%"]) }

  def self.filter(filters)
    #start by getting all the records
    filtered = Content.all

    #filter by each column if there is a value
    filtered = filtered.by_title(filters['title']) if filters['title'].present?
    filtered = filtered.by_display_title(filters['display_title']) if filters['display_title'].present?
    filtered = filtered.by_user(filters['user']) if filters['user'].present?
    filtered = filtered.by_description(filters['description']) if filters['description'].present?
    filtered = filtered.by_year_of_publication_from(filters['year_of_publication_from']) if filters['year_of_publication_from'].present?
    filtered = filtered.by_year_of_publication_to(filters['year_of_publication_to']) if filters['year_of_publication_to'].present?
    filtered = filtered.by_copyright_permission(filters['copyright_permission']) if filters['copyright_permission'].present?

    #dynamc filtering for metadata
    if filters['metadata'].present?
      filters['metadata'].keys.each do |metadata_type_id|
        if filters['metadata'][metadata_type_id].present?
          puts "metadata_type_id: #{metadata_type_id}"
          filtered = filtered.by_metadata_type_and_metadata(metadata_type_id, filters['metadata'][metadata_type_id])
        end
      end
    end

    # if there is a direction sort by given sort column
    if filters['direction'].present? && filters['direction'] != 'none'
      case filters['sort']
        #user is a special case because it is a belongs_to relationship
        when 'user'
          sorted = filtered.includes(:user).order("users.name #{filters['direction']}")
        #metadata is a special case because it is a belongs_to relationship
        when 'copyright_permission'
          sorted = filtered.includes(:copyright_permission).order("copyright_permissions.organization_name #{filters['direction']}")
        else
          sorted = filtered.order("#{filters['sort']} #{filters['direction']}") 
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
      metadata = metadata_record.map { |m| m.name }
    else
      metadata = []
    end
    metadata
  end

  # List of metadata for a given metadata type name
  def metadatas_by_name(metadata_type_name)
		metadataType = MetadataType.find_by(name: metadata_type_name)
		# FIXME: metadataType might be nil
		if metadataType == nil
			['']
		else
    	metadatas(metadataType.id)
		end
  end

  def self.to_csv()
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
				'Filesize', 
			].concat(MetadataType.all.map{|type| type.name})
      all.each do |content|
        csv << [
          content.title, 
          content.display_title, 
          content.file.filename.to_s, #does this work?
          content.description, 
          '', #check this (Modified On)
          '', #check this (Copywrite Notes)
          content.additional_notes, 
          content.year_of_publication, 
          '', #check this (Reviewed On)
          'True', 
          'False', 
          content.file.byte_size, #does this work?
				].concat(MetadataType.all.map{|type| content.metadatas_by_name(type.name).join(' | ')})
					# multiple values should be separated by a pipe (|)
      end
    end
  end

end

html_file_path = Rails.root.join('contents.html')

# Open a new HTML file for writing
File.open(html_file_path, 'w') do |file|
  file.puts "<html><body><table border='1'>"

  # Add header row
  file.puts "<tr><th>ID</th><th>Title</th><th>Description</th><th>File Name</th><th>Created At</th><th>Updated At</th></tr>"

  # Add data rows
  contents.find_each do |content|
    file.puts "<tr>"
    file.puts "<td>#{content.id}</td>"
    file.puts "<td>#{content.title}</td>"
    file.puts "<td>#{content.description}</td>"
    file.puts "<td>#{content.file_name}</td>"
    file.puts "<td>#{content.created_at.strftime('%Y-%m-%d %H:%M:%S')}</td>"
    file.puts "<td>#{content.updated_at.strftime('%Y-%m-%d %H:%M:%S')}</td>"
    file.puts "</tr>"
  end

  file.puts "</table></body></html>"
end