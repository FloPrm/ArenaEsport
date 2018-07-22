require 'test_helper'

class GameAccountsControllerTest < ActionController::TestCase
  setup do
    @game_account = game_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:game_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create game_account" do
    assert_difference('GameAccount.count') do
      post :create, game_account: {  }
    end

    assert_redirected_to game_account_path(assigns(:game_account))
  end

  test "should show game_account" do
    get :show, id: @game_account
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @game_account
    assert_response :success
  end

  test "should update game_account" do
    patch :update, id: @game_account, game_account: {  }
    assert_redirected_to game_account_path(assigns(:game_account))
  end

  test "should destroy game_account" do
    assert_difference('GameAccount.count', -1) do
      delete :destroy, id: @game_account
    end

    assert_redirected_to game_accounts_path
  end
end
