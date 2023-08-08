class CommunicationUploader < CarrierWave::Uploader::Base
  storage :file

  before :store, :remember_cache_id
  after :store, :delete_tmp_dir

  def remember_cache_id(new_file)
    @cache_id_was = cache_id
  end

  def delete_tmp_dir(new_file)
    # regex matches cache_id format: 1234567890-1234567890-1234-1234 (or 1234567890-1234567890-1234) 
    # where the first two groups can be any length and the last two groups are length 4, and one of the last two groups is optional
    if @cache_id_was.present? && @cache_id_was =~ /\A[\d]+\-[\d]+(\-[\d]{4})?\-[\d]{4}\z/
      FileUtils.rm_rf(File.join(root, cache_dir, @cache_id_was))
    end
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w(pdf png jpg jpeg)
  end

  def content_type_allowlist
    %w(application/pdf image/png image/jpg image/jpeg)
  end

end
