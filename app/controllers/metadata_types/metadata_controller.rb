class MetadataTypes::MetadataController < ApplicationController
  before_action :set_metadatum, only: %i[edit update destroy review info replace]
  before_action :set_metadata_type
  before_action :authenticate_user!

  # GET /metadata/1/edit
  def edit
    authorize @metadatum
  end

  # POST /metadata or /metadata.json
  def create
    @metadatum = Metadatum.new(metadatum_params.merge(user: current_user))
    authorize @metadata
    @metadatum.errors.add('Wrong permission level') unless current_user.read_attribute_before_type_cast(:role) >= @metadata_type.access_level
    @metadatum.metadata_type = @metadata_type
    @metadatum.needs_review = false if current_user.admin? || current_user.intern_plus?
    @target = "metadataTable_#{params[:metadata_type_id]}"

    respond_to do |format|
      if @metadatum.save
        flash.now[:notice] = "#{@metadatum.metadata_type.name} \"#{@metadatum.name}\" was created successfully."
        @metadata = MetadataType.find(params[:metadata_type_id]).metadata
        format.turbo_stream
      else
        format.turbo_stream { render 'create_error' }
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
      flash.now[:alert] = 'There was an error deleting the metadatum.'
      render :show
    end
  end

  def replace
    authorize @metadatum
    title = @metadatum.name
    replace_with_id = params[:replace_with]
    replace_with_metadatum = Metadatum.find(replace_with_id)

    # Validate that both metadata are of the same type
    if @metadatum.metadata_type_id != replace_with_metadatum.metadata_type_id
      flash.now[:alert] = 'Error: Cannot replace metadatum. Both metadata must be of the same metadata type.'
      @target = "metadatum_#{@metadatum.id}"
      respond_to do |format|
        format.turbo_stream { render 'error' }
      end
      return
    end

    # Find all content_metadata associations for the original metadatum
    content_metadata_to_replace = @metadatum.content_metadata.includes(:content)

    # Use a transaction to ensure data consistency
    Metadatum.transaction do
      content_metadata_to_replace.each do |content_metadatum|
        content = content_metadatum.content

        # Check if the content already has the replacement metadatum
        existing_association = ContentMetadatum.find_by(
          content_id: content.id,
          metadatum_id: replace_with_metadatum.id
        )

        if existing_association
          # If it already exists, just remove the old association
          content_metadatum.destroy
        else
          # Otherwise, update the association to point to the replacement metadatum
          content_metadatum.update(metadatum_id: replace_with_metadatum.id)
        end
      end

      # Now delete the original metadatum (this will also destroy remaining content_metadata via dependent: :destroy)
      @metadatum.destroy
    end

    flash.now[:notice] = "\"#{title}\" was deleted and replaced by \"#{replace_with_metadatum.name}\"."
    @target = "metadatum_#{@metadatum.id}"
    respond_to do |format|
      format.turbo_stream { render 'destroy' }
    end
  rescue ActiveRecord::RecordNotFound
    flash.now[:alert] = 'Error: Could not find replacement metadatum.'
    respond_to do |format|
      format.turbo_stream { render 'error' }
    end
  rescue StandardError => e
    flash.now[:alert] = "Error replacing metadatum: #{e.message}"
    respond_to do |format|
      format.turbo_stream { render 'error' }
    end
  end

  def search
    authorize Metadatum
    @target = params[:target]
    @metadatum_count = params[:count].to_i
    @metadata = @metadata_type.metadata.where('lower(name) LIKE lower(?)',
                                              "%#{params[:search]}%").order(Arel.sql('length(name), name'))

    needs_review = if params[:status] == 'all'
                     0
                   else
                     params[:status] == 'needs_review' ? 1 : 2
                   end
    if needs_review != 0
      tf = needs_review == 1 ? 'true' : 'false'
      @metadata = @metadata.where("needs_review = #{tf}")
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def review
    authorize @metadatum
    @metadatum.needs_review = !@metadatum.needs_review

    respond_to do |format|
      if @metadatum.save
        # flash.now[:notice] = "#{@metadatum.metadata_type.name} \"#{@metadatum.name}\" was created successfully."
        @metadata = MetadataType.find(params[:metadata_type_id]).metadata
        format.turbo_stream
      else
        format.turbo_stream { render 'create_error' }
        # format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def info
    authorize @metadatum
    @added_by = (@metadatum.respond_to?(:user) ? (@metadatum.user&.name || 'Unknown') : 'Unknown')
    @reviewed = (if @metadatum.respond_to?(:needs_review)
                   @metadatum.needs_review ? 'needs review' : 'reviewed'
                 else
                   'N/A'
                 end)
    @usage_count = (@metadatum.respond_to?(:contents) ? @metadatum.contents.count : 0)
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
