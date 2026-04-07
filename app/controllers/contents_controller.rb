class ContentsController < ApplicationController
  include Filterable
  before_action :set_content, only: %i[show edit update destroy]
  before_action :set_filterable_columns, only: %i[index list]
  before_action :authenticate_user!

  # GET /contents or /contents.json
  def index
    authorize Content

    # clear_filters!(Content)

    # log("This is a test")
    # warn("this is a warning")
    # err("this is an error")

    if session["#{Content.to_s.underscore}_filters"].blank?
      session["#{Content.to_s.underscore}_filters"] = { 'columns' => %w[title display_title user] }
    end
    items_per_page = session.dig('content_filters', :items_per_page.to_s)

    @pagy, @contents = pagy(Content.order(created_at: :desc), items: items_per_page || 10)
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
    authorize Content
    # content_params[:metadatum_ids].reject!(&:blank?) if content_params[:metadatum_ids]
    err('content params')
    log(content_params)
    @content = Content.new(content_params.merge(user: current_user))

    respond_to do |format|
      if @content.save
        format.html { redirect_to content_url(@content), notice: 'Content was successfully created.' }
        format.json { render :show, status: :created, location: @content }
      else
        @metadata_types = MetadataType.all.order(:order)
        @metadata = {}

        # put the file back
        log(content_params)
        if content_params[:file].present?
          @content.file.attach(content_params[:file])
          warn(content_params[:file])
        else
          err('content file not present')
        end

        # put the metadata back
        if content_params[:metadatum_ids].present?
          @metadata_types.each do |metadata_type|
            @metadata[metadata_type] = Metadatum.where(
              id: content_params[:metadatum_ids],
              metadata_type_id: metadata_type.id
            )
          end
        end

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
        format.html { redirect_to content_url(@content), notice: 'Content was successfully updated.' }
        format.json { render :show, status: :ok, location: @content }
      else
        @metadata_types = MetadataType.all.order(:order)
        @metadata = {}
        @metadata_types.each do |metadata_type|
          @metadata[metadata_type] = @content.metadata.where(metadata_type_id: metadata_type.id)
        end
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
      format.html { redirect_to contents_url, notice: 'Content was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    authorize Content
    # Search for metadata that matches the search string
    # Used in multi_select turbo controller for Content#new
    @target = params[:target]
    @selected = params[:selected_ids].nil? ? [] : params[:selected_ids].split(',')
    @metadata_type = MetadataType.find(params[:metadata_type_id])
    @should_show_add_new_for_given_metadata_type = current_user.read_attribute_before_type_cast(:role) >= @metadata_type.access_level
    @metadata = @metadata_type.metadata.where('lower(name) LIKE lower(?)',
                                              "%#{params[:search]}%").order(Arel.sql('length(name), name'))
    @metadatum_count = params[:metadatum_count].to_i
    respond_to do |format|
      format.turbo_stream
    end
  end

  def add_new_metadatum
    authorize Content
    # Add a new metadatum to the database while createing a content record
    @metadata_type = MetadataType.find(params[:metadata_type_id])
    @target = params[:target]
    @metadatum = @metadata_type.metadata.create(name: params[:name], user: current_user)
    @metadatum.needs_review = false if current_user.admin? || current_user.intern_plus?
    respond_to do |format|
      if @metadatum.save
        format.turbo_stream { render 'add_metadatum' }
      else
        @target += '_container'
        format.turbo_stream { render 'add_new_metadatum_error' }
      end
    end
  end

  def add_existing_metadatum
    authorize Content
    # Add a new metadatum to the database while createing a content record
    @target = params[:target]
    @metadata_type = MetadataType.find(params[:metadata_type_id])
    @metadatum = @metadata_type.metadata.find(params[:metadatum_id])
    respond_to do |format|
      format.turbo_stream { render 'add_metadatum' }
    end
  end

  def list
    authorize Content

    contents_scope = filter!(Content)

    items_per_page = session.dig('content_filters', :items_per_page.to_s)

    @pagy, @contents = pagy(contents_scope.order(created_at: :desc), items: items_per_page || 10)
    render(partial: 'content', locals: { contents: @contents, pagy: @pagy })
  end

  def download
    authorize Content
    @zip_filenames = tmp_filenames('bulk_content_download_*.zip')
    @dlms_report_filenames = tmp_filenames('dlms_content_transfer_*.json')
    @zip_jobs = delayed_jobs_for('ContentDownloadJob')
    @dlms_jobs = delayed_jobs_for('ContentDlmsTransferJob')
  end

  def create_download
    authorize Content
    contents_scope = filter!(Content)
    @job_id = ContentDownloadJob.perform_later(contents_scope.pluck(:id)).job_id
  end

  def create_dlms_transfer
    authorize Content
    contents_scope = filter!(Content)
    filters_snapshot = session.fetch('content_filters', {}).deep_dup

    @job_id = ContentDlmsTransferJob.perform_later(
      content_ids: contents_scope.pluck(:id),
      filters: filters_snapshot,
      queued_at: Time.current.iso8601,
      base_url: DlmsClient.default_base_url
    ).job_id
  end

  def delete_download
    authorize Content
    zip_filename = params[:filename]
    raw_names = Dir[Rails.root.join('tmp/bulk_content_download_*.zip')]
    full_path = Rails.root.join('tmp', zip_filename)

    return unless raw_names.include?(full_path.to_s)

    File.delete(full_path) if File.exist?(full_path)
  end

  def download_spreadsheet
    authorize Content
    contents_scope = filter!(Content)
    send_data contents_scope.order(created_at: :desc).to_xlsx, filename: "ContentCuration-metadata-#{Date.today}.xlsx"
  end

  def download_zip
    authorize Content
    zip_filename = params[:filename]
    path = Rails.root.join('tmp', zip_filename)
    send_file path,
              filename: zip_filename,
              type: 'application/zip',
              disposition: 'attachment',
              stream: false, # <= important: don't stream from Rails
              buffer_size: 4096
  end

  def download_dlms_report
    authorize Content
    filename = params[:filename].to_s
    path = Rails.root.join('tmp', filename)

    return head(:not_found) unless filename.match?(/\Adlms_content_transfer_.*\.json\z/) && File.exist?(path)

    send_file path,
              filename: filename,
              type: 'application/json',
              disposition: 'attachment',
              stream: false,
              buffer_size: 4096
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_content
    @content = Content.find(params[:id])
  end

  def set_filterable_columns
    @filterable_columns = Content::FILTERABLE_COLUMNS
  end

  def tmp_filenames(pattern)
    Dir[Rails.root.join("tmp/#{pattern}")]
      .map { |path| File.basename(path) }
      .sort
      .reverse
  end

  def delayed_jobs_for(job_class_name)
    require 'yaml'

    Delayed::Job.all.map do |job|
      handler = YAML.load_stream(job.handler)[0]
      next unless handler.job_data['job_class'].include?(job_class_name)

      [handler.job_data['job_id'], job.locked_at]
    end.compact
  end

  # Only allow a list of trusted parameters through.
  # These params are for creating/updating a Content
  # If you are looking for search params, look in Content model
  def content_params
    params.require(:content).permit(:title, :display_title, :file, :description, :year_of_publication,
                                    :additional_notes, metadatum_ids: [])
  end
end
