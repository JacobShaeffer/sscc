class ContentDownloadJob < ApplicationJob
    queue_as :default

    around_perform :around_cleanup

    def perform()
        require 'zip'

        # zip_filename = "bulk_content_download_#{Time.now.strftime('%m-%d-%y %H:%M')}.zip"
        # zipfile_path = Rails.root.join('tmp', zip_filename)

        # Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        #     Content.all.each do |content|
        #         path = ActiveStorage::Blob.service.send(:path_for, content.file.key)
        #         file_name = content.file.filename.sanitized()
        #        # if File.exist?(path)
        #         #     case content.file.content_type
        #         #     when "application/pdf"
        #         #         file_name = "#{file_name}.pdf"
        #         #     when "video/mp4"
        #         #         file_name = "#{file_name}.mp4"
        #         #     when "audio/mpeg"
        #         #         file_name = "#{file_name}.mp3"
        #         #     end
        #         # end
        #         zipfile.add(file_name, path) 
        #     end
        # end

        # Download all files to a temp directory
        folder_path = Rails.root.join('tmp', 'unzipped')
        Content.all.each do |content|
          filename = content.file.filename.to_s
          File.open(folder_path.join(filename), 'wb') do |file|
            content.file.download { |chunk| file.write(chunk) }
          end
        end
    
    end

    private 

    def around_cleanup
        puts "Before Perform"
        yield
        puts "After Perform"
    end
    
end