class MetadataTypes::MetadataController < ApplicationController
  before_action :set_metadatum, only: %i[ edit update destroy ]
  before_action :set_metadata_type, only: %i[ new edit create destory ]

  # GET /metadata/new
  def new
    @metadatum = Metadatum.new
  end

  # GET /metadata/1/edit
  def edit
  end

  # POST /metadata or /metadata.json
  def create
    @metadatum = Metadatum.new(metadatum_params)
    @metadatum.metadata_type = @metadata_type

    respond_to do |format|
      if @metadatum.save
        format.html { redirect_to @metadata_type, notice: "Metadatum was successfully created." }
        format.json { render :show, status: :created, location: @metadata_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @metadata_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metadata/1 or /metadata/1.json
  def update
    respond_to do |format|
      if @metadatum.update(metadatum_params)
        format.html { redirect_to metadata_type_path(@metadatum.metadata_type_id), notice: "Metadatum was successfully updated." }
        format.json { render :show, status: :ok, location: @metadatum }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @metadatum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata/1 or /metadata/1.json
  def destroy
    print("destroying metadatum")
    title = @metadatum.name

    if @metadatum.destroy
      flash[:notice] = "\"#{title}\" was deleted successfully."
      redirect_to metadata_type_path(params[:metadata_type_id])
    else
      flash.now[:alert] = "There was an error deleting the metadatum."
      render :show
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
