require 'test_helper'

class DlmsClientTest < ActiveSupport::TestCase
  test 'ensure_metadata re-fetches after uniqueness conflict' do
    client = DlmsClient.new(base_url: 'http://example.test')
    duplicate_error = DlmsClient::RequestError.new(
      'duplicate metadata',
      status: 400,
      body: {
        'success' => false,
        'error' => { 'non_field_errors' => ['The fields type, name must make a unique set.'] }
      }
    )
    lookup_calls = 0

    client.define_singleton_method(:find_metadata) do |type_name:, name:|
      lookup_calls += 1
      lookup_calls == 1 ? nil : { 'id' => 9001, 'name' => name, 'type_name' => type_name }
    end
    client.define_singleton_method(:create_metadata) do |type_name:, name:|
      raise duplicate_error if type_name == 'Language' && name == 'English'
    end

    result = client.ensure_metadata(type_name: 'Language', name: 'English')

    assert_equal({ id: 9001, created: false }, result)
    assert_equal 2, lookup_calls
  end

  test 'ensure_metadata retries fetch after uniqueness conflict before failing' do
    client = DlmsClient.new(base_url: 'http://example.test')
    duplicate_error = DlmsClient::RequestError.new(
      'duplicate metadata',
      status: 400,
      body: {
        'success' => false,
        'error' => { 'non_field_errors' => ['The fields type, name must make a unique set.'] }
      }
    )
    lookup_calls = 0

    client.define_singleton_method(:find_metadata) do |type_name:, name:|
      lookup_calls += 1
      lookup_calls < 4 ? nil : { 'id' => 9002, 'name' => name, 'type_name' => type_name }
    end
    client.define_singleton_method(:create_metadata) do |type_name:, name:|
      raise duplicate_error if type_name == 'Language' && name == 'French'
    end
    client.define_singleton_method(:sleep) do |_seconds|
      nil
    end

    result = client.ensure_metadata(type_name: 'Language', name: 'French')

    assert_equal({ id: 9002, created: false }, result)
    assert_equal 4, lookup_calls
  end

  test 'ensure_metadata raises a specific error if duplicate metadata cannot be re-fetched' do
    client = DlmsClient.new(base_url: 'http://example.test')
    duplicate_error = DlmsClient::RequestError.new(
      'duplicate metadata',
      status: 400,
      body: {
        'success' => false,
        'error' => { 'non_field_errors' => ['The fields type, name must make a unique set.'] }
      }
    )

    client.define_singleton_method(:find_metadata) do |type_name:, name:|
      nil
    end
    client.define_singleton_method(:create_metadata) do |type_name:, name:|
      raise duplicate_error if type_name == 'Language' && name == 'Kinyarwanda'
    end
    client.define_singleton_method(:sleep) do |_seconds|
      nil
    end

    error = assert_raises(DlmsClient::RequestError) do
      client.ensure_metadata(type_name: 'Language', name: 'Kinyarwanda')
    end

    assert_equal 'DLMS metadata already existed but could not be re-fetched', error.message
    assert_equal 400, error.status
    assert_equal 'Kinyarwanda', error.body['name']
  end

  test 'upload_content sends the original filename in multipart form data' do
    client = DlmsClient.new(base_url: 'http://example.test')
    captured_args = nil

    client.define_singleton_method(:execute_curl) do |*args|
      captured_args = args
      ['{"id":123,"title":"TestDocument"}' + "\n201", '', Struct.new(:success?).new(true)]
    end

    response = client.upload_content(
      file_path: '/tmp/bwr9xmsybly9ywfstwpd5xhbz4rk',
      original_filename: 'FeedingManual.pdf',
      content_type: 'application/pdf',
      fields: { 'title' => 'TestDocument', 'active' => 'True', 'metadata' => [54184] }
    )

    content_file_arg = captured_args.each_cons(2).find { |flag, _value| flag == '-F' && _value.start_with?('content_file=@') }&.last

    assert_includes content_file_arg, 'content_file=@/tmp/bwr9xmsybly9ywfstwpd5xhbz4rk'
    assert_includes content_file_arg, 'filename=FeedingManual.pdf'
    assert_includes content_file_arg, 'type=application/pdf'
  end

  test 'duplicate_content_error_reason detects filename and title collisions' do
    client = DlmsClient.new(base_url: 'http://example.test')

    assert_equal 'duplicate_filename', client.duplicate_content_error_reason(
      'error' => { 'content_file' => ['Filename already exists.'] }
    )
    assert_equal 'duplicate_title', client.duplicate_content_error_reason(
      'error' => { 'title' => ['Content with this title already exists.'] }
    )
    assert_nil client.duplicate_content_error_reason('error' => { 'description' => ['is invalid'] })
  end

  test 'upload_content rejects unexpected success responses without an id' do
    client = DlmsClient.new(base_url: 'http://example.test')

    client.define_singleton_method(:execute_curl) do |*args|
      ['{"id":null,"title":"TestDocument"}' + "\n201", '', Struct.new(:success?).new(true)]
    end

    error = assert_raises(DlmsClient::RequestError) do
      client.upload_content(
        file_path: '/tmp/fake-file',
        original_filename: 'FeedingManual.pdf',
        content_type: 'application/pdf',
        fields: { 'title' => 'TestDocument', 'active' => 'True' }
      )
    end

    assert_equal 'DLMS upload response missing content id', error.message
    assert_equal({ 'id' => nil, 'title' => 'TestDocument' }, error.body)
  end

  test 'post_form accepts symbol keys when creating metadata' do
    client = DlmsClient.new(base_url: 'http://example.test')
    captured_request = nil

    client.define_singleton_method(:parse_response) do |_uri, request|
      captured_request = request
      { 'id' => 54184, 'name' => 'THISISATEST', 'type' => 1 }
    end

    response = client.send(:post_form, '/api/metadata/', fields: { name: 'THISISATEST', type: 1 })
    body_data = captured_request.instance_variable_get(:@body_data)

    assert_equal 54184, response['id']
    assert_equal [['name', 'THISISATEST'], ['type', '1']], body_data
    assert_equal 'multipart/form-data', captured_request.content_type
  end

  test 'find_metadata encodes metadata type as a path segment' do
    client = DlmsClient.new(base_url: 'http://example.test')
    captured_path = nil
    captured_query = nil

    client.define_singleton_method(:get_json) do |path, query: nil|
      captured_path = path
      captured_query = query
      { 'data' => { 'results' => [] } }
    end

    client.send(:find_metadata, type_name: 'Rights Holder', name: 'CC By NC ND')

    assert_equal '/api/metadata/Rights%20Holder/get/', captured_path
    assert_equal({ name: 'CC By NC ND' }, captured_query)
  end
end
