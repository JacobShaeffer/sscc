class ContentDownloadJob < ApplicationJob
  queue_as :default

  def perform(content_ids)
    require 'zip'
    
    # Create base names for folder and zip
    timestamp = Time.now.strftime('%m-%d-%y %H:%M')
    folder_name = "bulk_content_download_#{timestamp}"
    zip_filename = "#{folder_name}.zip"
    
    # Setup paths
    folder_path = Rails.root.join('tmp', folder_name)
    zip_path = Rails.root.join('tmp', zip_filename)
    
    # Create temp directory
    FileUtils.mkdir_p(folder_path)
    
    # Download files to temp directory
    Content.where(id: content_ids).each do |content|
      filename = content.file.filename.to_s
      File.open(folder_path.join(filename), 'wb') do |file|
        content.file.download { |chunk| file.write(chunk) }
      end
    end
    
    # Create zip file
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir["#{folder_path}/*"].each do |file|
        zipfile.add(File.basename(file), file)
      end
    end
    
    # Clean up temp directory
    FileUtils.rm_rf(folder_path)
  end

end