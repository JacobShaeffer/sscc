json.extract! content, :id, :title, :user_id, :created_at, :updated_at
json.url content_url(content, format: :json)
