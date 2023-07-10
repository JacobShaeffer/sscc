import { Controller } from "@hotwired/stimulus"

export const string_identifier = "fileSelect";

export default class extends Controller {
	onFileSelected(event) {
		console.log('event', event);
		console.log('target', event.target);
		console.log('target value', event.target.value);
		// Check the file type here and respond to the form with a stream to do real-time validation????

		var errorMessage = "File type not supported. Please upload a pdf, mp3, or mp4 file.";
		var allowedExtensions = /(\.pdf|\.mp3|\.mp4)$/i;

		console.log('test: ', allowedExtensions.test(event.target.value));

		// test if the file is an allowed extension
		if (!allowedExtensions.test(event.target.value)) {
			alert(errorMessage);
			event.target.value = '';
			return false;
		}

		let file_name_regex = /^.*[\\\/]/;
		let file_name = event.target.value.replace(file_name_regex, '');
		$('#Selected-File-Display').val(file_name);
	}
}
