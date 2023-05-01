import { Controller } from "@hotwired/stimulus"

export const string_identifier = "autoComplete";

export default class extends Controller {
	// static targets = ["input", "list"];

	connect() {
		console.log("Hello, Stimulus!", string_identifier);
	}

	onItemSelected(event) {
		console.log("onItemSelected", event.target.id);
		var checkbox_id = "content_metadatum_ids_" + event.target.id.substr(13);
		var isChecked = document.getElementById(checkbox_id).checked;
		document.getElementById(checkbox_id).checked = !isChecked;
		event.target.classList.toggle("active");
	}
}
