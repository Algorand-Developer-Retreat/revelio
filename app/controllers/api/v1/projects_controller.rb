module Api
  module V1
    class ProjectsController < ApplicationController
      skip_before_action :authenticate, only: :index
      
      # GET /api/v1/projects
      def index
        projects = Project.all.order(name: :asc)
        
        response_data = projects.map do |project|
          project_data = project.as_json(only: [:id, :name, :abbreviation, :description, :verified])
          
          # Add logo URL if present
          if project.logo.attached?
            project_data['logo_url'] = Rails.application.routes.url_helpers.rails_blob_url(project.logo, only_path: true)
          end
          
          # Add contract count
          project_data['contract_count'] = project.contracts.count
          
          project_data
        end
        
        render json: response_data
      end
    end
  end
end 