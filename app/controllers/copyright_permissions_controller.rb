class CopyrightPermissionsController < ApplicationController
  include Filterable
  before_action :set_copyright_permission, only: %i[ show edit update destroy ]
  before_action :set_searchable_columns, only: %i[ index list ]
	before_action :authenticate_user!

  def index
    authorize CopyrightPermission

    clear_filters!(CopyrightPermission)
    session["#{CopyrightPermission.to_s.underscore}_filters"] = {"columns" => ["organization_name", "organization_website", "date_contacted", "date_of_response", "granted"]}
    @pagy, @copyright_permissions = pagy(CopyrightPermission.all, items: 10)
  end

  # GET /copyright_permissions/1 or /copyright_permissions/1.json
  def show
    authorize @copyright_permission
  end

  # GET /copyright_permissions/new
  def new
    @copyright_permission = CopyrightPermission.new
    authorize @copyright_permission
    @organizations = Organization.all
  end

  # GET /copyright_permissions/1/edit
  def edit
    authorize @copyright_permission
  end

  # POST /copyright_permissions or /copyright_permissions.json
  def create
    @copyright_permission = CopyrightPermission.new(copyright_permission_params.merge(user: current_user))
    authorize @copyright_permission

    respond_to do |format|
      if @copyright_permission.save
        format.html { redirect_to copyright_permission_url(@copyright_permission), notice: "Copyright permission was successfully created." }
        format.json { render :show, status: :created, location: @copyright_permission }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @copyright_permission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /copyright_permissions/1 or /copyright_permissions/1.json
  def update
    authorize @copyright_permission
    respond_to do |format|
      if @copyright_permission.update(copyright_permission_params)
        format.html { redirect_to copyright_permission_url(@copyright_permission), notice: "Copyright permission was successfully updated." }
        format.json { render :show, status: :ok, location: @copyright_permission }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @copyright_permission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /copyright_permissions/1 or /copyright_permissions/1.json
  def destroy
    authorize @copyright_permission
    @copyright_permission.destroy

    respond_to do |format|
      format.html { redirect_to copyright_permissions_url, notice: "Copyright permission was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def list
    authorize CopyrightPermission

    copyright_permissions_scope = filter!(CopyrightPermission)

    @pagy, @copyright_permissions = pagy(copyright_permissions_scope, items: 10)
    render(partial: 'copyright_permissions', locals: { copyright_permissions: @copyright_permissions, pagy: @pagy })
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_copyright_permission
      @copyright_permission = CopyrightPermission.find(params[:id])
    end

    def set_searchable_columns
      @searchable_columns = CopyrightPermission::SEARCHABLE_COLUMNS
    end

    # Only allow a list of trusted parameters through.
    def copyright_permission_params
      params.require(:copyright_permission).permit(:notes, :organization_name, :organization_website, :organization_contact_information, :granted, :date_contacted, :date_of_response, :communication)
    end
end
