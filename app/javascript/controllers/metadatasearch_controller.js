import { Controller } from '@hotwired/stimulus';
import { get } from "@rails/request.js"

export const string_identifier = 'metadatasearch';

export default class extends Controller {
    static targets = ["name", "nameinput"];
	static values = {
		type: String,
		url: String,
		target: String,
		count: Number
	}

	initialize(){
		console.log("metadatasearch controller initialized");
		console.log(this.countValue);
	}

	connect () {
		console.log("metadata controller connected");
	}

	onShowMore(){
		this.countValue += 5;
		this.autoComplete(this.nameinputTarget.value);//FIXME: this should get the correct value to pass to autocomplete
	}

	onSearchInput(event) {
        this.nameinputTarget.value = event.target.value;
		this.autoComplete(event.target.value);
	}

	onClear() {
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
		params.append("count", this.countValue);

		get(`${this.urlValue}?${params}`, {
			responseKind: "turbo-stream", 
		})
	}
}