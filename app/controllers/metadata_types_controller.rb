class MetadataTypesController < ApplicationController
  before_action :set_metadata_type, only: %i[ show edit update destroy ]
	before_action :authenticate_user!

  # GET /metadata_types or /metadata_types.json
  def index
    @metadata_types = MetadataType.all
    # These do not prevent a malevolent actor from performing these actions
    # but they do prevent the buttons from being displayed.
    @show_create = true
    @show_edit = true
    @show_delete = true
  end

  def list
    @metadata_types = MetadataType.all
  end

  # GET /metadata_types/1/edit
  def edit
		# respond_to do |format|
		# 	format.turbo_stream
		# end
    @metadata_types = MetadataType.all
  end

  # POST /metadata_types or /metadata_types.json
  def create
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
    respond_to do |format|
      if @metadata_type.update(metadata_type_params)
				format.turbo_stream
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata_types/1 or /metadata_types/1.json
  def destroy
    @metadata_type.destroy

    respond_to do |format|
      format.html { redirect_to list_metadata_types_url, notice: "Metadata type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def search
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
