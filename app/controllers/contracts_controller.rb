class ContractsController < ApplicationController
  before_action :set_project, only: %i[ project_contracts show edit update destroy new create ]
  before_action :set_contract, only: %i[ show edit update destroy ]
  before_action :ensure_project_owner!, only: %i[ new create edit update destroy ]

  # GET /contracts or /contracts.json
  def index
    @contracts = Contract.all
  end

  def project_contracts
    @contracts = @project.contracts
  end
  # GET /contracts/1 or /contracts/1.json
  def show
  end

  # GET /contracts/new
  def new
    @contract = @project.contracts.build
  end

  # GET /contracts/1/edit
  def edit
  end

  # POST /contracts or /contracts.json
  def create
    @contract = @project.contracts.build(contract_params)

    respond_to do |format|
      if @contract.save
        format.html { redirect_to project_contract_path(@project, @contract), notice: "Contract was successfully created." }
        format.json { render :show, status: :created, location: @contract }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contracts/1 or /contracts/1.json
  def update
    respond_to do |format|
      if @contract.update(contract_params)
        format.html { redirect_to @contract, notice: "Contract was successfully updated." }
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
      format.html { redirect_to contracts_path, status: :see_other, notice: "Contract was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find_by(abbreviation: params[:project_abbreviation])
    end

    def set_contract
      @contract = Contract.find_by(id: params[:id], project_id: @project.id)
    end

    def ensure_project_owner!
      unless @project.user_id == Current.user.id
        redirect_to project_path(@project), alert: "You are not authorized to perform this action."
      end
    end

    # Only allow a list of trusted parameters through.
    def contract_params
      params.require(:contract).permit(:name, :version, :app_id, :round_valid_from, :address)
    end
end
