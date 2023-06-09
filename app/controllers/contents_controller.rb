class ContentsController < ApplicationController
  before_action :set_content, only: %i[ show edit update destroy ]
	before_action :authenticate_user!

  # GET /contents or /contents.json
  def index
    authorize Content
    @contents = Content.all
  end

  # GET /contents/1 or /contents/1.json
  def show
    authorize Content
  end

  # GET /contents/new
  def new
    authorize Content
    @content = Content.new
  end

  # GET /contents/1/edit
  def edit
    authorize @content
    @metadata_types = MetadataType.all
    @content.file.cache! unless @content.file.file.nil?
  end

  # POST /contents or /contents.json
  def create
    # content_params[:metadatum_ids].reject!(&:blank?) if content_params[:metadatum_ids]
    @content = Content.new(content_params.merge(user: current_user))
    authorize @content

    respond_to do |format|
      if @content.save
        format.html { redirect_to content_url(@content), notice: "Content was successfully created." }
        format.json { render :show, status: :created, location: @content }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contents/1 or /contents/1.json
  def update
    authorize @content
    respond_to do |format|
      if @content.update(content_params)
        format.html { redirect_to content_url(@content), notice: "Content was successfully updated." }
        format.json { render :show, status: :ok, location: @content }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contents/1 or /contents/1.json
  def destroy
    authorize Content
    @content.destroy

    respond_to do |format|
      format.html { redirect_to contents_url, notice: "Content was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def search
    authorize Content
    #Search for metadata that matches the search string
    #Used in multi_select turbo controller for Content#new
    @target = params[:target]
    @selected = params[:selected_ids].nil? ? [] : params[:selected_ids].split(',')
    metadata_type = MetadataType.find(params[:metadata_type_id])
    @metadata = metadata_type.metadata.where("name LIKE ?", "%#{params[:search]}%")
    respond_to do |format|
      format.turbo_stream
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_content
      @content = Content.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def content_params
      params.require(:content).permit(:title, :display_title, :file, :file_cache, :description, :year_of_publication, :copyright_notes, :copyright_permission_id, metadatum_ids: [])
    end
end
