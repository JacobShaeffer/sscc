import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export const string_identifier = "multiSelect";

export default class extends Controller {
	static targets = ["searchInput", "checkbox"]
	static values = {
		type: String
	}

    // initialize() {
    // 	// Called once, when the controller is first instantiated
	// 	console.log("multiselect controller initialized")
	// }

	onAddSelected(event) {
		let name = this.searchInputTarget.value;
		this.searchInputTarget.value = "";
		this.autoComplete(this.typeValue, "");

		let params = new URLSearchParams();

		let target = `metadataInput_${this.typeValue}`;

		params.append("target", target);
		params.append("metadata_type_id", this.typeValue);
		params.append("name", name);

		get(`/contents/add_new_metadatum?${params}`, {
			responseKind: "turbo-stream", 
		})
	}

	onItemSelected(event) {
		// console.log("onItemSelected", event.target.id);
		var target_id = event.target.id.substr(13);
		var badge_id = "metadatum_badge_" + target_id;
		this.toggleCheckBox(target_id);
		// console.log("badge_id", badge_id)
		document.getElementById(badge_id).classList.toggle("hidden");
		event.target.classList.toggle("active");

		this.searchInputTarget.value = "";
		this.autoComplete(this.typeValue, "");
	}

	onBadgeClicked(event) {
		// console.log("onBadgeClicked", event.target.id);
		var target_id = event.target.id.substr(21);
		// console.log("target_id", target_id);
		var listItem_id = "selector_for=" + target_id;
		this.toggleCheckBox(target_id);
		let selector_for = document.getElementById(listItem_id);
		if (selector_for) {
			selector_for.classList.toggle("active");
		}
		event.target.parentElement.classList.toggle("hidden");
	}

	onSearchFocusIn(event) {
		// console.log("onSearchFocusIn", event.target.id);
		this.autoComplete(this.typeValue, '');
		document.getElementById(event.target.id + "_list").classList.toggle("hidden");
	}

	onSearchFocusOut(event) {
		// console.log("onSearchFocusOut", event.target.id);
		document.getElementById(event.target.id + "_list").classList.toggle("hidden");
	}

	onSearchInput(event) {
		// console.log("onSearchInput")
		this.autoComplete(this.typeValue, event.target.value);
	}

	onSearchInputClick(){
		// console.log("onSearchInputClick")
		this.searchInputTarget.focus();
	}

	// Private

	autoComplete(metadata_type_id, search){
		let params = new URLSearchParams();

		let selected_ids = this.checkboxTargets.filter((checkbox) => 
			checkbox.checked).map((checkbox) => checkbox.value).join(",");

		let target = `metadataInput_${metadata_type_id}_list`;

		params.append("target", target);
		params.append("metadata_type_id", metadata_type_id);
		params.append("search", search);
		params.append("selected_ids", selected_ids);

		get(`/contents/search?${params}`, {
			responseKind: "turbo-stream", 
		})
	}

	toggleCheckBox(target_id){
		var checkbox_id = "content_metadatum_ids_" + target_id;
		var isChecked = document.getElementById(checkbox_id).checked;
		document.getElementById(checkbox_id).checked = !isChecked;
	}
}