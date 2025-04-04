module Api
  module V1
    class ContractsController < ApplicationController
      before_action :set_contract, only: [:show, :by_round]
      skip_before_action :authenticate, only: [:show, :by_round, :project_contracts]
      # GET /api/v1/contracts/:app_id
      def show
        response_data = @contract.as_json
        
        # Ensure arc56 is properly parsed
        if @contract.arc56.present?
          begin
            response_data['arc56'] = JSON.parse(@contract.arc56.is_a?(String) ? @contract.arc56 : @contract.arc56.to_json)
          rescue JSON::ParserError => e
            Rails.logger.error "Error parsing arc56 JSON in API response: #{e.message}"
          end
        end
        
        response_data['project_abbreviation'] = @contract.project.abbreviation
        render json: response_data
      end

      # GET /api/v1/contracts/:app_id/by_round/:round_number
      def by_round
        contract_at_round = @contract.where(round_valid_from: params[:round_number]).first
        if contract_at_round
          render json: contract_at_round.as_json.merge(project_abbreviation: contract_at_round.project.abbreviation)
        else
          render json: { error: "Contract not found for round #{params[:round_number]}" }, status: :not_found
        end
      end
      
      # GET /api/v1/contracts/project/:abbreviation
      def project_contracts
        project = Project.find_by(abbreviation: params[:abbreviation])
        
        if project
          contracts = project.contracts.order(created_at: :desc)
          
          response_data = contracts.map do |contract|
            contract_data = contract.as_json
            
            # Parse arc56 JSON for each contract
            if contract.arc56.present?
              begin
                contract_data['arc56'] = JSON.parse(contract.arc56.is_a?(String) ? contract.arc56 : contract.arc56.to_json)
              rescue JSON::ParserError => e
                Rails.logger.error "Error parsing arc56 JSON in API response: #{e.message}"
              end
            end
            
            contract_data['project_abbreviation'] = project.abbreviation
            contract_data
          end
          
          render json: response_data
        else
          render json: { error: "Project not found" }, status: :not_found
        end
      end

      private

      def set_contract
        @contract = Contract.find_by(app_id: params[:id])
        render json: { error: "Contract not found" }, status: :not_found unless @contract
      end
    end
  end
end 