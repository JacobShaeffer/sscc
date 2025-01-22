class ContentsController < ApplicationController
  include Filterable
  before_action :set_content, only: %i[ show edit update destroy ]
  before_action :set_searchable_columns, only: %i[ index list ]
	before_action :authenticate_user!

  # GET /contents or /contents.json
  def index
    authorize Content

    clear_filters!(Content)
    session["#{Content.to_s.underscore}_filters"] = {"columns" => ["title", "display_title", "user"]}
    @pagy, @contents = pagy(Content.order(created_at: :desc), items: 10)
  end
  
  
  # GET /contents/1 or /contents/1.json
  def show
    authorize @content
    @metadata_types = MetadataType.all.order(:order)
    @metadata = {}
    @metadata_types.each do |metadata_type|
      @metadata[metadata_type] = @content.metadata.where(metadata_type_id: metadata_type.id)
    end
  end

  # GET /contents/new
  def new
    authorize Content
    @content = Content.new
    @metadata_types = MetadataType.all.order(:order)
    @metadata = {}
  end

  # GET /contents/1/edit
  def edit
    authorize @content
    @metadata_types = MetadataType.all.order(:order)
    @metadata = {}
    @metadata_types.each do |metadata_type|
      @metadata[metadata_type] = @content.metadata.where(metadata_type_id: metadata_type.id)
    end
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
    authorize @content
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
    @metadata_type = MetadataType.find(params[:metadata_type_id])
    @metadata = @metadata_type.metadata.where("lower(name) LIKE lower(?)", "%#{params[:search]}%")
    respond_to do |format|
      format.turbo_stream
    end
  end

  def add_new_metadatum
    authorize Content
    #Add a new metadatum to the database while createing a content record
    @metadata_type = MetadataType.find(params[:metadata_type_id])
    @target = params[:target]
    @metadatum = @metadata_type.metadata.create(name: params[:name], user: current_user)
    respond_to do |format|
      if @metadatum.save
        format.turbo_stream
      else
        @target = @target + "_container"
        format.turbo_stream { render "add_new_metadatum_error"}
      end
    end
  end

  def list
    authorize Content

    contents_scope = filter!(Content)

    @pagy, @contents = pagy(contents_scope.order(created_at: :desc), items: 10)
    render(partial: "content", locals: { contents: @contents, pagy: @pagy })
  end

  def download
    authorize Content
    raw_names = Dir[ Rails.root.join("tmp", "bulk_content_download_*.zip") ]
    @filenames = raw_names.map { |path| File.basename(path) }
    require 'yaml'
    #@runnning_jobs = Delayed::Job.all.map(|job| YAML.load_stream(job.handler)[0].job_data["job_id"])
    if Delayed::Job.all.size > 0
      @jobs = Delayed::Job.all.map do |job|
        handler = YAML.load_stream(job.handler)[0]
        if handler.job_data["job_class"].include?("ContentDownloadJob")
          [handler.job_data["job_id"], job.locked_at]
        end
      end.compact
      # @jobs = Delayed::Job.all.map{ |job| [YAML.load_stream(job.handler)[0].job_data["job_id"], job.locked_at] }
    end
  end

  def create_download
    @job_id = ContentDownloadJob.perform_later().job_id
    #figure out how to use job_id to check the status of the job???
    # or use the existance of the unfinished zip as a status indicator
  end

  def delete_download
    authorize Content
    zip_filename = params[:filename]
    puts(zip_filename)
    raw_names = Dir[ Rails.root.join("tmp", "bulk_content_download_*.zip") ]
    full_path = Rails.root.join('tmp', zip_filename)

    if full_path in raw_names
      puts(full_path)
      puts(File.exist?(full_path))
      File.delete(full_path) if File.exist?(full_path)
    end

  end

  def download_spreadsheet
    authorize Content
    send_data Content.order(created_at: :desc).to_xlsx, filename: "ContentCuration-metadata-#{Date.today}.xlsx"
  end

  def download_zip
    authorize Content
    zip_filename = params[:filename]
    send_file Rails.root.join('tmp', zip_filename)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_content
      @content = Content.find(params[:id])
    end

    def set_searchable_columns
      @searchable_columns = Content::SEARCHABLE_COLUMNS
    end

    # Only allow a list of trusted parameters through.
    def content_params
      params.require(:content).permit(:title, :display_title, :file, :description, :year_of_publication, :additional_notes, :copyright_permission_id, metadatum_ids: [])
    end

end
