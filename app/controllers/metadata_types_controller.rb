class MetadataTypesController < ApplicationController
  before_action :set_metadata_type, only: %i[ show edit update destroy ]
	before_action :authenticate_user!

  # GET /metadata_types or /metadata_types.json
  def index
    authorize MetadataType
    @metadata_types = MetadataType.all
  end

  def list
    authorize MetadataType
    @metadata_types = MetadataType.all
  end

  # GET /metadata_types/1/edit
  def edit
    authorize MetadataType
  end

  # POST /metadata_types or /metadata_types.json
  def create
    authorize MetadataType
    @metadata_type = MetadataType.new(metadata_type_params.merge(user: current_user))

    respond_to do |format|
      if @metadata_type.save
        format.html { redirect_to list_metadata_types_path, notice: "Metadata type was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metadata_types/1 or /metadata_types/1.json
  def update
    authorize MetadataType
    respond_to do |format|
      if @metadata_type.update(metadata_type_params)
				format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata_types/1 or /metadata_types/1.json
  def destroy
    authorize MetadataType
    @metadata_type.destroy

    respond_to do |format|
      format.html { redirect_to list_metadata_types_url, notice: "Metadata type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def search
    authorize MetadataType
    @target = params[:target]
    @metadata_types = MetadataType.where("name LIKE ?", "%#{params[:search]}%")
		print "----------------------------------------------------\n"
		print @metadata_types.inspect
		print "\n----------------------------------------------------\n"
    respond_to do |format|
      format.turbo_stream
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metadata_type
      @metadata_type = MetadataType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def metadata_type_params
      params.require(:metadata_type).permit(:name)
    end
end
