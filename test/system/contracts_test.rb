require "application_system_test_case"

class ContractsTest < ApplicationSystemTestCase
  setup do
    @contract = contracts(:one)
  end

  test "visiting the index" do
    visit contracts_url
    assert_selector "h1", text: "Contracts"
  end

  test "should create contract" do
    visit contracts_url
    click_on "New contract"

    fill_in "Address", with: @contract.address
    fill_in "App", with: @contract.app_id
    fill_in "Name", with: @contract.name
    fill_in "Project", with: @contract.project_id
    fill_in "Round valid from", with: @contract.round_valid_from
    fill_in "Version", with: @contract.version
    click_on "Create Contract"

    assert_text "Contract was successfully created"
    click_on "Back"
  end

  test "should update Contract" do
    visit contract_url(@contract)
    click_on "Edit this contract", match: :first

    fill_in "Address", with: @contract.address
    fill_in "App", with: @contract.app_id
    fill_in "Name", with: @contract.name
    fill_in "Project", with: @contract.project_id
    fill_in "Round valid from", with: @contract.round_valid_from
    fill_in "Version", with: @contract.version
    click_on "Update Contract"

    assert_text "Contract was successfully updated"
    click_on "Back"
  end

  test "should destroy Contract" do
    visit contract_url(@contract)
    click_on "Destroy this contract", match: :first

    assert_text "Contract was successfully destroyed"
  end
end
