class CopyrightPermission < ApplicationRecord
  belongs_to :user
  has_many :content

  has_one_attached :communication

  enum granted: {yes: 1, no: 0, waiting_for_response: 2, organization_requesting_more_information: 3}, _prefix: true

  validates :granted, presence: true
  validates :date_contacted, presence: true
  validates :communication, presence: true, allow_blank: false
  validates :organization_name, presence: true, allow_blank: false
  validates :organization_contact_information, presence: true, allow_blank: false

  #List of searchable columns
  SEARCHABLE_COLUMNS = %i[ organization_name organization_website organization_contact_information date_contacted date_contacted_from date_contacted_to date_of_response date_of_response_from date_of_response_to granted notes ].freeze
  FILTER_PARAMS = [SEARCHABLE_COLUMNS + %i[sort direction], :columns => []].freeze

  scope :by_organization_name,                      ->  (organization_name) { where('lower(organization_name) LIKE lower(?)', "%#{organization_name}%") }
  scope :by_organization_website,                   ->  (organization_website) { where('lower(organization_website) LIKE lower(?)', "%#{organization_website}%") }
  scope :by_organization_contact_information,       ->  (organization_contact_information) { where('lower(organization_contact_information) LIKE lower(?)', "%#{organization_contact_information}%") }
  scope :by_date_contacted_from,                    ->  (date_contacted_from) { where('date_contacted >= ?', date_contacted_from) }
  scope :by_date_contacted_to,                      ->  (date_contacted_to) { where('date_contacted <= ?', date_contacted_to) }
  scope :by_date_of_response_from,                  ->  (date_of_response_from) { where('date_of_response >= ?', date_of_response_from) }
  scope :by_date_of_response_to,                    ->  (date_of_response_to) { where('date_of_response <= ?', date_of_response_to) }
  scope :by_granted,                                ->  (granted) { where(granted: granted) }
  scope :by_notes,                                  ->  (notes) { where('lower(notes) LIKE lower(?)', "%#{notes}%") }

  def self.filter(filters)
    filtered = CopyrightPermission.all

    filtered = filtered.by_organization_name(filters['organization_name']) if filters['organization_name'].present?
    filtered = filtered.by_organization_website(filters['organization_website']) if filters['organization_website'].present?  
    filtered = filtered.by_organization_contact_information(filters['organization_contact_information']) if filters['organization_contact_information'].present?  
    filtered = filtered.by_date_contacted_from(filters['date_contacted_from']) if filters['date_contacted_from'].present? 
    filtered = filtered.by_date_contacted_to(filters['date_contacted_to']) if filters['date_contacted_to'].present?
    filtered = filtered.by_date_of_response_from(filters['date_of_response_from']) if filters['date_of_response_from'].present?
    filtered = filtered.by_date_of_response_to(filters['date_of_response_to']) if filters['date_of_response_to'].present?
    filtered = filtered.by_granted(filters['granted']) if filters['granted'].present?
    filtered = filtered.by_notes(filters['notes']) if filters['notes'].present?

    if filters['direction'].present? && filters['direction'] != 'none'
      case filters['sort']
        when 'user'
          sorted = filtered.includes(:user).order("users.name #{filters['direction']}")
        else
          sorted = filtered.order("#{filters['sort']} #{filters['direction']}")
      end
    else
      sorted = filtered
    end

    sorted
  end
end
