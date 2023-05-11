import { Controller } from '@hotwired/stimulus';
import { get, post } from "@rails/request.js"

export const string_identifier = 'metadatasearch';

export default class extends Controller {
    static targets = ["name", "nameinput"];
	static values = {
		type: String
	}

	onSearchInput(event) {
        this.nameinputTarget.value = event.target.value;
		this.autoComplete(this.typeValue, event.target.value);
	}

	onClear() {
		this.nameTarget.value = "";
		this.nameinputTarget.value = "";
		this.autoComplete(this.typeValue, "");
	}

	// Private
	target_id(metadata_type){
		return `metadataTable_${metadata_type}`;
	}

	autoComplete(metadata_type_id, search){
		let params = new URLSearchParams();

		params.append("target", this.target_id(metadata_type_id));
		params.append("search", search);

		get(`/metadata_types/${metadata_type_id}/metadata/search?${params}`, {
			responseKind: "turbo-stream", 
		})
	}
}