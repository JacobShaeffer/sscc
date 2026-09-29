require 'test_helper'

class MetadatumTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'metadatum-model@example.com',
      name: 'Metadatum Model User',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )
    @metadata_type = MetadataType.create!(name: 'Subject', order: 1, user: @user)
  end

  test 'name rejects leading and trailing whitespace' do
    [" ", "\t", "\n", "\u00A0"].each do |whitespace|
      ["#{whitespace}Science", "Science#{whitespace}"].each do |invalid_name|
        metadatum = Metadatum.new(name: invalid_name, metadata_type: @metadata_type, user: @user)

        assert_not metadatum.valid?, "expected name to reject #{invalid_name.inspect}"
        assert_includes metadatum.errors[:name], 'must not have leading or trailing whitespace'
      end
    end
  end

  test 'name allows internal whitespace' do
    metadatum = Metadatum.new(name: 'Science and Technology', metadata_type: @metadata_type, user: @user)

    assert metadatum.valid?
  end
end
