require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get join" do
    get users_join_url
    assert_response :success
  end
end