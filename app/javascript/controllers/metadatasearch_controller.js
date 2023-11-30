import { Controller } from '@hotwired/stimulus';
import { get } from "@rails/request.js"

export const string_identifier = 'metadatasearch';

export default class extends Controller {
    static targets = ["name", "nameinput"];
	static values = {
		type: String,
		url: String,
		target: String
	}

	connect () {
		console.log("metadata controller connected");
	}

	onSearchInput(event) {
        this.nameinputTarget.value = event.target.value;
		this.autoComplete(event.target.value);
	}

	onClear() {
		this.nameTarget.value = "";
		this.nameinputTarget.value = "";
		this.autoComplete("");
		let errorMsg = document.getElementById(this.typeValue + "_error");
		if (errorMsg) {
			errorMsg.remove();
		}
	}

	autoComplete(search){
		let params = new URLSearchParams();

		params.append("target", this.targetValue + this.typeValue);
		params.append("search", search);

		get(`${this.urlValue}?${params}`, {
			responseKind: "turbo-stream", 
		})
	}
}