require 'test_helper'

class UserDetailsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get import_csv_or_xlsx" do
    get :import_csv_or_xlsx
    assert_response :success
  end

end
