json.extract! metadatum, :id, :name, :metadata_type_id, :created_at, :updated_at
json.url metadatum_url(metadatum, format: :json)
