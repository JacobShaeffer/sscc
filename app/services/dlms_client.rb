require 'cgi'
require 'json'
require 'net/http'
require 'open3'
require 'uri'

class DlmsClient
  METADATA_CONFLICT_FETCH_ATTEMPTS = 3
  METADATA_CONFLICT_FETCH_DELAY = 0.2

  class RequestError < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  def self.default_base_url
    ENV.fetch('DLMS_BASE_URL', 'http://10.177.128.17')
  end

  def initialize(base_url: self.class.default_base_url)
    @base_url = base_url
    @metadata_type_ids = nil
  end

  attr_reader :base_url

  def content_exists?(file_name: nil, title: nil)
    query = {}
    query[:file_name] = file_name if file_name.present?
    query[:title] = title if title.present?
    return false if query.empty?

    payload = get_json('/api/contents/', query: query)
    extract_results(payload).any?
  end

  def ensure_metadata(type_name:, name:)
    existing = find_metadata(type_name: type_name, name: name)
    return { id: existing.fetch('id'), created: false } if existing.present?

    created = create_metadata(type_name: type_name, name: name)
    { id: created.fetch('id'), created: true }
  rescue RequestError => e
    raise unless unique_metadata_conflict?(e.body)

    existing = fetch_metadata_after_conflict(type_name: type_name, name: name)
    unless existing.present?
      raise RequestError.new(
        'DLMS metadata already existed but could not be re-fetched',
        status: e.status,
        body: {
          'original_error' => e.body,
          'metadata_type_name' => type_name,
          'name' => name
        }
      )
    end

    { id: existing.fetch('id'), created: false }
  end

  def upload_content(file_path:, original_filename:, content_type:, fields:)
    form_fields = fields.each_with_object([]) do |(key, value), parts|
      Array(value).each do |entry|
        next if entry.blank?

        parts << [key.to_s, entry.to_s]
      end
    end

    stdout, stderr, status = execute_curl(
      'curl',
      '--silent',
      '--show-error',
      '--write-out',
      "\n%{http_code}",
      "#{base_url}/api/contents/",
      '-F',
      "content_file=@#{file_path};filename=#{File.basename(original_filename)};type=#{content_type}",
      *form_fields.flat_map { |key, value| ['-F', "#{key}=#{value}"] }
    )

    unless status.success?
      raise RequestError.new("DLMS upload failed: #{stderr.presence || stdout}", body: { 'stderr' => stderr, 'stdout' => stdout })
    end

    body, http_status = split_body_and_status(stdout)
    parsed_body = parse_json(body)

    if http_status.to_i >= 400 || (parsed_body.is_a?(Hash) && parsed_body['success'] == false)
      raise RequestError.new('DLMS upload failed', status: http_status.to_i, body: parsed_body)
    end

    validate_upload_response!(parsed_body, expected_title: fields['title'])
    parsed_body
  end

  def metadata_type_id_by_name(name)
    metadata_type_ids.fetch(name) do
      raise RequestError.new("Unknown DLMS metadata type: #{name}", body: { 'metadata_type_name' => name })
    end
  end

  def duplicate_content_error_reason(body)
    error_hash = body.is_a?(Hash) ? body['error'] || {} : {}

    return 'duplicate_filename' if duplicate_error_messages(error_hash['content_file']).any?
    return 'duplicate_title' if duplicate_error_messages(error_hash['title']).any?

    nil
  end

  private

  def execute_curl(*args)
    Open3.capture3(*args)
  end

  def metadata_type_ids
    @metadata_type_ids ||= begin
      payload = get_json('/api/metadata_types/')
      Array(payload['data']).each_with_object({}) do |metadata_type, values|
        values[metadata_type.fetch('name')] = metadata_type.fetch('id')
      end
    end
  end

  def find_metadata(type_name:, name:)
    payload = get_json("/api/metadata/#{escape_path_segment(type_name)}/get/", query: { name: name })
    extract_results(payload).first
  end

  def create_metadata(type_name:, name:)
    payload = post_form('/api/metadata/', fields: { name: name, type: metadata_type_id_by_name(type_name) })

    if payload.is_a?(Hash) && payload['success'] == false
      raise RequestError.new('DLMS metadata creation failed', body: payload)
    end

    payload
  end

  def get_json(path, query: nil)
    uri = build_uri(path, query: query)
    request = Net::HTTP::Get.new(uri)
    parse_response(uri, request)
  end

  def post_form(path, fields:)
    uri = build_uri(path)
    request = Net::HTTP::Post.new(uri)
    request.set_form(
      fields.to_a.map { |key, value| [key.to_s, value.to_s] },
      'multipart/form-data'
    )
    parse_response(uri, request)
  end

  def parse_response(uri, request)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    parsed_body = parse_json(response.body)

    if !response.is_a?(Net::HTTPSuccess) || (parsed_body.is_a?(Hash) && parsed_body['success'] == false)
      raise RequestError.new("DLMS request failed with status #{response.code}", status: response.code.to_i, body: parsed_body)
    end

    parsed_body
  end

  def build_uri(path, query: nil)
    uri = URI.join("#{base_url}/", path.sub(%r{\A/}, ''))
    uri.query = URI.encode_www_form(query) if query.present?
    uri
  end

  def escape_path_segment(value)
    CGI.escape(value.to_s).gsub('+', '%20')
  end

  def extract_results(payload)
    data = payload['data']

    case data
    when Hash
      Array(data['results'])
    when Array
      data
    else
      []
    end
  end

  def unique_metadata_conflict?(body)
    body.dig('error', 'non_field_errors').to_a.any? do |message|
      message.include?('must make a unique set')
    end
  end

  def duplicate_error_messages(messages)
    Array(messages).select do |message|
      normalized = message.to_s.downcase
      normalized.include?('already exists') || normalized.include?('already exist')
    end
  end

  def fetch_metadata_after_conflict(type_name:, name:)
    METADATA_CONFLICT_FETCH_ATTEMPTS.times do |attempt|
      existing = find_metadata(type_name: type_name, name: name)
      return existing if existing.present?

      sleep(METADATA_CONFLICT_FETCH_DELAY) if attempt < METADATA_CONFLICT_FETCH_ATTEMPTS - 1
    end

    nil
  end

  def validate_upload_response!(body, expected_title:)
    unless body.is_a?(Hash)
      raise RequestError.new('DLMS upload returned unexpected response body', body: { 'response' => body })
    end

    if body['id'].blank?
      raise RequestError.new('DLMS upload response missing content id', body: body)
    end

    return if expected_title.blank? || body['title'].blank? || body['title'] == expected_title

    raise RequestError.new(
      'DLMS upload response title did not match uploaded content',
      body: {
        'expected_title' => expected_title,
        'response' => body
      }
    )
  end

  def parse_json(body)
    JSON.parse(body)
  rescue JSON::ParserError
    body
  end

  def split_body_and_status(output)
    body, separator, status = output.rpartition("\n")
    return [output, nil] if separator.empty? || status !~ /\A\d{3}\z/

    [body, status]
  end
end
