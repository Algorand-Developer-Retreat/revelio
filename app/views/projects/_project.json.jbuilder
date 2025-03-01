json.extract! project, :id, :name, :abbreviation, :verified, :user_id, :created_at, :updated_at
json.url project_url(project, format: :json)
