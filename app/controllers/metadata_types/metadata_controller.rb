class MetadataTypes::MetadataController < ApplicationController
  before_action :set_metadatum, only: %i[ edit update destroy review ]
  before_action :set_metadata_type
	before_action :authenticate_user!

  # GET /metadata/1/edit
  def edit
    authorize @metadatum
  end

  # POST /metadata or /metadata.json
  def create
    @metadatum = Metadatum.new(metadatum_params.merge(user: current_user))
    authorize @metadatum
    @metadatum.metadata_type = @metadata_type
    if( current_user.admin? || current_user.editor? )
      @metadatum.needs_review = false
    end
    @target = "metadataTable_#{params[:metadata_type_id]}"

    respond_to do |format|
      if @metadatum.save
        flash.now[:notice] = "#{@metadatum.metadata_type.name} \"#{@metadatum.name}\" was created successfully."
        @metadata = MetadataType.find(params[:metadata_type_id]).metadata
        format.turbo_stream
      else
        format.turbo_stream { render "create_error" }
        # format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metadata/1 or /metadata/1.json
  def update
    authorize @metadatum
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
    authorize @metadatum
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
    @metadatum_count = params[:count].to_i
    @metadata = @metadata_type.metadata.where("lower(name) LIKE lower(?)", "%#{params[:search]}%").order(Arel.sql("length(name), name"))

    needs_review = params[:status] == "all" ? 0 : params[:status] == "needs_review" ? 1 : 2
    if(needs_review != 0)
      tf = needs_review == 1 ? "true" : "false"
      @metadata = @metadata.where("needs_review = #{tf}")
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def review 
    authorize @metadatum
    @metadatum.needs_review = false

    respond_to do |format|
      if @metadatum.save
        flash.now[:notice] = "#{@metadatum.metadata_type.name} \"#{@metadatum.name}\" was created successfully."
        @metadata = MetadataType.find(params[:metadata_type_id]).metadata
        format.turbo_stream
      else
        format.turbo_stream { render "create_error" }
        # format.html { render :new, status: :unprocessable_entity }
      end
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
