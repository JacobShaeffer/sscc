import { Controller } from "@hotwired/stimulus"

export const string_identifier = "fileSelect";

export default class extends Controller {
	static values = {
		extensions: Array,
		ae: String,
	}

	initialize() {
		// Called once, when the controller is first instantiated
		// console.log("fileSelect controller initialized")
	}

	onFileSelected(event) {
		// Check the file type here and respond to the form with a stream to do real-time validation????
		var allowedExtensions = this.extensionsValue;
		var errorMessageExt = ""
		var allowedExtensionsExt = "("
		for (var i = 0; i < allowedExtensions.length; i++) {
			errorMessageExt += allowedExtensions[i];
			allowedExtensionsExt += "\." + allowedExtensions[i];
			if (i < allowedExtensions.length - 1) {
				if (i == allowedExtensions.length - 2) {
					errorMessageExt += " or ";
				} else {
					errorMessageExt += ", ";
				}
				allowedExtensionsExt += "|";
			}
		}
		allowedExtensionsExt += ")";

		var errorMessage = `File type not supported. Please upload a ${errorMessageExt} file.`;
		// var allowedExtensionsRegex = /(\.pdf|\.mp3|\.mp4)$/i;
		var allowedExtensionsRegex = new RegExp(allowedExtensionsExt + "$", "i");

		// test if the file is an allowed extension
		if (!allowedExtensionsRegex.test(event.target.value)) {
			alert(errorMessage);
			event.target.value = '';
			return false;
		}

		let file_name_regex = /^.*[\\\/]/;
		let file_name = event.target.value.replace(file_name_regex, '');
		$('#Selected-File-Display').val(file_name);
	}
}
