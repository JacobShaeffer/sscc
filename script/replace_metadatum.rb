# script/replace_metadatum.rb

metadatum_id = ARGV.fetch(0)
replace_with_id = ARGV.fetch(1)

metadatum = Metadatum.find(metadatum_id)
replace_with_metadatum = Metadatum.find(replace_with_id)

if metadatum.metadata_type_id != replace_with_metadatum.metadata_type_id
	raise "Cannot replace metadatum: both metadata must be of the same metadata type"
end

Metadatum.transaction do
	metadatum.content_metadata.find_each do |content_metadatum|
		existing_association = ContentMetadatum.find_by(
			content_id: content_metadatum.content_id,
			metadatum_id: replace_with_metadatum.id
		)

		if existing_association
			content_metadatum.destroy!
		else
			content_metadatum.update!(metadatum_id: replace_with_metadatum.id)
		end
	end

	metadatum.destroy!
end

puts "Replaced Metadatum #{metadatum_id} with #{replace_with_id}"