class MetadataTypes::MetadataController < ApplicationController
  before_action :set_metadatum, only: %i[ edit update destroy ]
  before_action :set_metadata_type
	before_action :authenticate_user!

  # GET /metadata/1/edit
  def edit
    authorize Metadatum
  end

  # POST /metadata or /metadata.json
  def create
    authorize Metadatum
    @metadatum = Metadatum.new(metadatum_params.merge(user: current_user))
    @metadatum.metadata_type = @metadata_type

    respond_to do |format|
      if @metadatum.save
        flash.now[:notice] = "#{@metadatum.metadata_type.name} \"#{@metadatum.name}\" was created successfully."
        # format.html { redirect_to @metadata_type, notice: "Metadatum was successfully created." }
        @target = "metadataTable_#{params[:metadata_type_id]}"
        @metadata = MetadataType.find(params[:metadata_type_id]).metadata
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metadata/1 or /metadata/1.json
  def update
    authorize Metadatum
    respond_to do |format|
      if @metadatum.update(metadatum_params)
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata/1 or /metadata/1.json
  def destroy
    authorize Metadatum
    title = @metadatum.name

    if @metadatum.destroy
      flash.now[:notice] = "\"#{title}\" was deleted successfully."
      @target = "metadatum_#{@metadatum.id}"
      respond_to do |format|
        format.turbo_stream
      end
    else
      flash.now[:alert] = "There was an error deleting the metadatum."
      render :show
    end
  end

  def search
    authorize Metadatum
    @target = params[:target]
    @metadata = @metadata_type.metadata.where("name LIKE ?", "%#{params[:search]}%")
    respond_to do |format|
      format.turbo_stream
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metadatum
      @metadatum = Metadatum.find(params[:id])
    end

    def set_metadata_type
      @metadata_type = MetadataType.find(params[:metadata_type_id])
    end

    # Only allow a list of trusted parameters through.
    def metadatum_params
      params.require(:metadatum).permit(:name, :metadata_type_id)
    end
end
