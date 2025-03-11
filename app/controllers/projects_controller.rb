class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update destroy ]
  before_action :ensure_owner!, only: %i[ edit update destroy ]

  # GET /projects or /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1 or /projects/1.json
  def show
    @contracts = @project.contracts
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects or /projects.json
  def create
    @project = Project.new(project_params)
    @project.user_id = Current.user.id
    respond_to do |format|
      if @project.save
        format.html { redirect_to project_path(@project.abbreviation), notice: "Project was successfully created." }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    Rails.logger.debug "Raw params: #{params.inspect}"
    Rails.logger.debug "Project params: #{project_params.inspect}"
    Rails.logger.debug "Project before update: #{@project.attributes.inspect}"
    
    respond_to do |format|
      result = @project.update(project_params)
      Rails.logger.debug "Update result: #{result}"
      
      if result
        format.html { redirect_to project_path(@project.abbreviation), notice: "Project was successfully updated." }
        format.json { render :show, status: :ok, location: @project }
      else
        Rails.logger.debug "Project errors: #{@project.errors.full_messages.inspect}"
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1 or /projects/1.json
  def destroy
    @project.destroy!

    respond_to do |format|
      format.html { redirect_to projects_path, status: :see_other, notice: "Project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /my-projects
  def my_projects
    @projects = Current.user.projects.order(created_at: :desc)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find_by(abbreviation: params[:abbreviation])
      unless @project
        redirect_to projects_path, alert: "Project not found."
        return
      end
    end

    # Ensure the current user owns the project
    def ensure_owner!
      unless @project && @project.user_id == Current.user.id
        redirect_to projects_path, alert: "You are not authorized to perform this action."
      end
    end

    # Only allow a list of trusted parameters through.
    def project_params
      params.require(:project).permit(:name, :abbreviation, :description, :verified, :logo)
    end
end
