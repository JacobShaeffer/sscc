require 'test_helper'

class ContentPolicyTest < ActiveSupport::TestCase
  test 'admin can use DLMS transfer actions' do
    admin = User.create!(
      email: 'admin-policy@example.com',
      name: 'Admin Policy',
      password: 'password123',
      password_confirmation: 'password123',
      role: :admin
    )

    policy = ContentPolicy.new(admin, Content)

    assert policy.create_dlms_transfer?
    assert policy.download_dlms_report?
  end

  test 'non-admin cannot use DLMS transfer actions' do
    volunteer = User.create!(
      email: 'volunteer-policy@example.com',
      name: 'Volunteer Policy',
      password: 'password123',
      password_confirmation: 'password123',
      role: :volunteer
    )

    policy = ContentPolicy.new(volunteer, Content)

    assert_not policy.create_dlms_transfer?
    assert_not policy.download_dlms_report?
  end
end
