class Content < ApplicationRecord
  belongs_to :user
  belongs_to :copyright_permission
  has_many :content_metadata, dependent: :destroy
  has_many :metadata, through: :content_metadata

  has_one_attached :file

  validates :title, presence: true, allow_blank: false
  validates :display_title, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: false
  validates :file, presence: true, allow_blank: false

  # created_at, updated_at, year_of_publication
  SEARCHABLE_COLUMNS = %i[ title user copyright_permission display_title description year_of_publication year_of_publication_from year_of_publication_to ].freeze
  FILTER_PARAMS = [SEARCHABLE_COLUMNS + %i[sort direction], :metadata => {}].freeze

  scope :by_title,                      ->  (title) { where('lower(title) LIKE lower(?)', "%#{title}%") }
  scope :by_display_title,              ->  (display_title) { where('lower(display_title) LIKE lower(?)', "%#{display_title}%") }
  scope :by_user,                       ->  (user) { joins(:user).where('lower(users.name) LIKE lower(?)', "%#{user}%") }
  scope :by_description,                ->  (description) { where('lower(description) LIKE lower(?)', "%#{description}%") }
  scope :by_year_of_publication_from,   ->  (year_of_publication_from) { where('year_of_publication >= ?', year_of_publication_from) }
  scope :by_year_of_publication_to,     ->  (year_of_publication_to) { where('year_of_publication <= ?', year_of_publication_to) }
  scope :by_copyright_permission,       ->  (permission) { joins(:copyright_permission).where('lower(copyright_permissions.organization_name) LIKE lower(?)', "%#{permission}%") }

  scope :by_metadata_type_and_metadata, ->  (type_id, metadata) { has_metadata(type_id, "%#{metadata}%") }
  # scope :by_collection_type, -> (collection_type) {joins(:metadata).where('metadata.metadata_type_id = 1').where('metadata.name = ?', collection_type)}

  def self.filter(filters)
    sorted = nil
    if filters['direction'] == 'nil'
      sorted = Content.all
    else
      sorted = Content.order("#{filters['sort']} #{filters['direction']}") 
    end
    sorted = sorted.by_title(filters['title']) if filters['title'].present?
    sorted = sorted.by_display_title(filters['display_title']) if filters['display_title'].present?
    sorted = sorted.by_user(filters['user']) if filters['user'].present?
    sorted = sorted.by_description(filters['description']) if filters['description'].present?
    sorted = sorted.by_year_of_publication_from(filters['year_of_publication_from']) if filters['year_of_publication_from'].present?
    sorted = sorted.by_year_of_publication_to(filters['year_of_publication_to']) if filters['year_of_publication_to'].present?
    sorted = sorted.by_copyright_permission(filters['copyright_permission']) if filters['copyright_permission'].present?

    if filters['metadata'].present?
      filters['metadata'].keys.each do |metadata_type_id|
        if filters['metadata'][metadata_type_id].present?
          sorted = sorted.by_metadata_type_and_metadata(metadata_type_id, filters['metadata'][metadata_type_id])
        end
      end
    end
    # sorted = sorted.by_collection_type('1', filters['metadata']) if filters['metadata'].present?
    return sorted
  end

  def metadatas(metadata_type_id)
    metadata_record = metadata.where(metadata_type_id: metadata_type_id)
    if metadata_record.present?
      metadata = metadata_record.map { |m| m.name }
    else
      metadata = []
    end
    metadata
  end

  # # lists content with a collection type metatatum and with the specific name of "collection_type"
  # def self.has_collection_type(collection_type)
  #   joins(:metadata).where('metadata.metadata_type_id = 1').where('metadata.name = ?', collection_type)
  # end

  def self.has_metadata(metadata_type_id, metadata_name)
    joins(:metadata).where('metadata.metadata_type_id = ?', metadata_type_id).where('lower(metadata.name) LIKE lower(?)', metadata_name).distinct
  end

  # def self.has_metadata_type(metadata_type_id)
  #   joins(:metadata).where('metadata.metadata_type_id = ?', metadata_type_id)
  # end

  # def self.has_metadata_type_and_metadata(metadata_type_id, metadata_name)
  #   joins(:metadata).where('metadata.metadata_type_id = ?', metadata_type_id).where('metadata.name = ?', metadata_name)
  # end

  # # lists content with metadata that matches the metadata_type_id and is in the list of metadata_names
  # def self.has_metadata_type_and_metadata_in(metadata_type_id, metadata_names)
  #   joins(:metadata).where('metadata.metadata_type_id = ?', metadata_type_id).where('metadata.name IN (?)', metadata_names)
  # end

end