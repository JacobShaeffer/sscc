import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export const string_identifier = "multiSelect";

export default class extends Controller {
	static targets = ["searchInput", "checkbox"]
	static values = {
		type: String
	}

	onItemSelected(event) {
		console.log("onItemSelected", event.target.id);
		var target_id = event.target.id.substr(13);
		var badge_id = "metadatum_badge_" + target_id;
		this.toggleCheckBox(target_id);
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
		document.getElementById(listItem_id).classList.toggle("active");
		event.target.parentElement.classList.toggle("hidden");
	}

	onSearchFocusIn(event) {
		// console.log("onSearchFocusIn", event.target.id);
		document.getElementById(event.target.id + "_list").classList.toggle("hidden");
	}

	onSearchFocusOut(event) {
		// console.log("onSearchFocusOut", event.target.id);
		document.getElementById(event.target.id + "_list").classList.toggle("hidden");
	}

	onSearchInput(event) {
		this.autoComplete(this.typeValue, event.target.value);
	}

	onSearchInputClick(){
		this.searchInputTarget.focus();
	}

	// Private
	target_id(metadata_type){
		let target = `metadataInput_${metadata_type}_list`;
		return target
	}

	autoComplete(metadata_type_id, search){
		let params = new URLSearchParams();

		// console.log("checkboxes", this.checkboxTargets);
		// this.checkboxTargets.forEach((checkbox) => {
		// 	console.log("checkbox", checkbox.value, checkbox.checked);
		// })
		let selected_ids = this.checkboxTargets.filter((checkbox) => 
			checkbox.checked).map((checkbox) => checkbox.value).join(",")
		// console.log("selected_ids", selected_ids);

		params.append("target", this.target_id(metadata_type_id));
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