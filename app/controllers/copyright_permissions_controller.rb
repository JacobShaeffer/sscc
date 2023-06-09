class CopyrightPermissionsController < ApplicationController
  before_action :set_copyright_permission, only: %i[ show edit update destroy ]
	before_action :authenticate_user!

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
      format.html { redirect_to copyright_index_url, notice: "Copyright permission was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_copyright_permission
      @copyright_permission = CopyrightPermission.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def copyright_permission_params
      params.require(:copyright_permission).permit(:notes, :organization_id, :granted, :date_contacted, :date_of_response, :communication, :communication_cache)
    end
end
