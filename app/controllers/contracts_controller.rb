class ContractsController < ApplicationController
  before_action :set_project, only: %i[ project_contracts show edit update destroy new create upgrade create_upgrade ]
  before_action :set_contract, only: %i[ show edit update destroy upgrade create_upgrade ]
  before_action :ensure_project_owner!, only: %i[ new create edit update destroy upgrade create_upgrade ]

  # GET /contracts or /contracts.json
  def index
    @contracts = @project.contracts
    @breadcrumbs = [
      { name: "Home", path: root_path },
      { name: "Projects", path: projects_path },
      { name: @project.name, path: project_path(@project.abbreviation) },
      { name: "Contracts", path: project_contracts_path(@project.abbreviation) }
    ]
  end

  def project_contracts
    @contracts = @project.contracts
  end

  # GET /contracts/1 or /contracts/1.json
  def show
    @breadcrumbs = [
      { name: "Home", path: root_path },
      { name: "Projects", path: projects_path },
      { name: @project.name, path: project_path(@project.abbreviation) },
      { name: @contract.name, path: project_contract_path(@project.abbreviation, @contract) }
    ]
    @all_versions = @contract.all_versions
  end

  # GET /contracts/new
  def new
    @contract = @project.contracts.new
    @breadcrumbs = [
      { name: "Home", path: root_path },
      { name: "Projects", path: projects_path },
      { name: @project.name, path: project_path(@project.abbreviation) },
      { name: "Contracts", path: project_contracts_path(@project.abbreviation) },
      { name: "New Contract", path: new_project_contract_path(@project.abbreviation) }
    ]
  end

  # GET /contracts/1/edit
  def edit
    @breadcrumbs = [
      { name: "Home", path: root_path },
      { name: "Projects", path: projects_path },
      { name: @project.name, path: project_path(@project.abbreviation) },
      { name: "Edit Contract", path: edit_project_contract_path(@project.abbreviation, @contract) }
    ]
  end

  # POST /contracts or /contracts.json
  def create
    @contract = @project.contracts.build(contract_params)
    
    # Set default version if not provided
    @contract.version = 0 if @contract.version.nil?

    # Handle JSON file upload
    if params[:contract][:arc56].present?
      begin
        uploaded_file = params[:contract][:arc56]
        json_content = uploaded_file.read
        @contract.arc56 = sanitize_json(json_content)
      rescue => e
        Rails.logger.error "Error reading JSON file: #{e.message}"
      end
    end

    respond_to do |format|
      if @contract.save
        format.html { redirect_to project_contract_path(@project.abbreviation, @contract), notice: "Contract was successfully created." }
        format.json { render :show, status: :created, location: @contract }
      else
        # Add detailed error logging
        Rails.logger.error "Contract creation failed: #{@contract.errors.full_messages.join(', ')}"
        Rails.logger.error "Contract params: #{contract_params.inspect}"
        Rails.logger.error "Project: #{@project.inspect}"
        
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /projects/:project_abbreviation/contracts/:id/upgrade
  def upgrade
    @new_contract = Contract.new
  end

  # POST /projects/:project_abbreviation/contracts/:id/create_upgrade
  def create_upgrade
    respond_to do |format|
      begin
        # Prepare upgrade params
        upgrade_params = contract_params.merge(project_id: @project.id)
        
        # Handle JSON file upload
        if params[:contract][:arc56].present?
          uploaded_file = params[:contract][:arc56]
          json_content = uploaded_file.read
          upgrade_params[:arc56] = json_content
        end
        
        @new_contract = @contract.create_version(upgrade_params)
        
        format.html { redirect_to project_contract_path(@project.abbreviation, @new_contract), notice: "Contract was successfully upgraded." }
        format.json { render :show, status: :created, location: @new_contract }
      rescue => e
        @new_contract = Contract.new(contract_params)
        Rails.logger.error "Upgrade failed: #{e.message}"
        Rails.logger.error "Contract params: #{contract_params.inspect}"
        Rails.logger.error "Project: #{@project.inspect}"
        format.html { render :upgrade, status: :unprocessable_entity }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contracts/1 or /contracts/1.json
  def update
    respond_to do |format|
      if @contract.update(contract_params)
        format.html { redirect_to project_contract_path(@project.abbreviation, @contract), notice: "Contract was successfully updated." }
        format.json { render :show, status: :ok, location: @contract }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contracts/1 or /contracts/1.json
  def destroy
    @contract.destroy!

    respond_to do |format|
      format.html { redirect_to project_path(@project.abbreviation), status: :see_other, notice: "Contract was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def download_json
    # Make sure we have the contract
    unless @contract && @contract.arc56.present?
      redirect_to project_contract_path(@project.abbreviation, @contract), 
                  alert: "No ARC56 specification available for download"
      return
    end
    
    # Set the filename based on the contract name and version
    filename = "#{@contract.name.parameterize}-v#{@contract.version}.json"
    
    # Send the data as a downloadable file
    send_data @contract.arc56, 
              type: 'application/json', 
              disposition: 'attachment',
              filename: filename
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find_by(abbreviation: params[:project_abbreviation])
      unless @project
        Rails.logger.error "Project not found with abbreviation: #{params[:project_abbreviation]}"
        Rails.logger.error "All params: #{params.inspect}"
        redirect_to projects_path, alert: "Project not found"
      end
    end

    def set_contract
      @contract = Contract.find_by(id: params[:id], project_id: @project.id)
      unless @contract
        redirect_to project_path(@project.abbreviation), alert: "Contract not found"
      end
    end

    def ensure_project_owner!
      unless @project && @project.user_id == Current.user.id
        redirect_to project_path(@project&.abbreviation || projects_path), 
                    alert: "You are not authorized to perform this action."
      end
    end

    # Only allow a list of trusted parameters through.
    def contract_params
      params.require(:contract).permit(:name, :version, :app_id, :round_valid_from, :address, :project_id, :arc56)
    end

    def sanitize_json(json_content)
      begin
        parsed_json = JSON.parse(json_content)
        Rails.logger.info "Parsed JSON: #{parsed_json}"
        JSON.pretty_generate(parsed_json)
      rescue JSON::ParserError => e
        Rails.logger.error "Invalid JSON format: #{e.message}"
        nil
      end
    end
end
