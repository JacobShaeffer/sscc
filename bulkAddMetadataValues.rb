require 'csv'

File.open("upload.csv", "r") do |f|
    CSV.foreach(f, :headers => true) do |row|
        user = User.first()
        metadata_type = MetadataType.find_by(name: row[0])
        metadatum = Metadatum.new(name: row[1], metadata_type: metadata_type, user: user)
        metadatum.save
    end
end
