require "test_helper"

class ContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @contract = contracts(:one)
  end

  test "should get index" do
    get contracts_url
    assert_response :success
  end

  test "should get new" do
    get new_contract_url
    assert_response :success
  end

  test "should create contract" do
    assert_difference("Contract.count") do
      post contracts_url, params: { contract: { address: @contract.address, app_id: @contract.app_id, name: @contract.name, project_id: @contract.project_id, round_valid_from: @contract.round_valid_from, version: @contract.version } }
    end

    assert_redirected_to contract_url(Contract.last)
  end

  test "should show contract" do
    get contract_url(@contract)
    assert_response :success
  end

  test "should get edit" do
    get edit_contract_url(@contract)
    assert_response :success
  end

  test "should update contract" do
    patch contract_url(@contract), params: { contract: { address: @contract.address, app_id: @contract.app_id, name: @contract.name, project_id: @contract.project_id, round_valid_from: @contract.round_valid_from, version: @contract.version } }
    assert_redirected_to contract_url(@contract)
  end

  test "should destroy contract" do
    assert_difference("Contract.count", -1) do
      delete contract_url(@contract)
    end

    assert_redirected_to contracts_url
  end
end
