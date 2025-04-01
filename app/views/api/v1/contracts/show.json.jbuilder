json.extract! @contract, :id, :name, :version, :app_id, :round_valid_from, :address, JSON.parse(:arc56)
json.project_abbreviation @contract.project.abbreviation 