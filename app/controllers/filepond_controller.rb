class FilepondController < ApplicationController

    def remove 
        signed_id = request.raw_post

        blob = ActiveStorage::Blob.find_signed(signed_id)
        if blob
            blob.purge
            head :ok
        else
            head :not_found
        end
    end

end
