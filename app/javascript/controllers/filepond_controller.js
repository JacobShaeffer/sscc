import { Controller } from '@hotwired/stimulus';
import * as FilePond from "filepond";
import FilePondPluginFileValidateType from 'filepond-plugin-file-validate-type';
import FilePondPluginFileValidateSize from 'filepond-plugin-file-validate-size';
import {DirectUpload} from "activestorage"

export const string_identifier = 'filepond';

export default class extends Controller {
	static values = {
		extensions: Array,
	}

    initialize() {
      // Called once, when the controller is first instantiated
		console.log("filepond controller initialized")
		FilePond.registerPlugin(FilePondPluginFileValidateType);
		FilePond.registerPlugin(FilePondPluginFileValidateSize);

		const input = document.querySelector('input[type="file"]');
		if(input){
			FilePond.create( input );
			
			const credit = document.querySelector('.filepond--credits');
			if (credit) {
				credit.remove();
			}
		}

		const directUploadUrl = input.dataset.directUploadUrl

		// acceptedFileTypes: ['image/png', 'image/jpeg', 'application/pdf'],
		FilePond.setOptions({
			acceptedFileTypes: this.extensionsValue,
			maxFileSize: '265MB',
			server: {
				process: (fieldName, file, metadata, load, error, progress, abort, transfer, options) => {
					const uploader = new DirectUpload(file, directUploadUrl, {
						directUploadWillStoreFileWithXHR: (request) => {
						request.upload.addEventListener(
							'progress',
							event => progress(event.lengthComputable, event.loaded, event.total)
						)
						}
					})
					uploader.create((errorResponse, blob) => {
						if (errorResponse) {
						error(`Something went wrong: ${errorResponse}`)
						} else {
						const hiddenField = document.createElement('input')
						hiddenField.setAttribute('type', 'hidden')
						hiddenField.setAttribute('value', blob.signed_id)
						hiddenField.name = input.name
						document.querySelector('form').appendChild(hiddenField)
						load(blob.signed_id)
						}
					})

					return {
						abort: () => abort()
					}
				},
				revert: {
					url: '/filepond/remove'
				},
				headers: {
					'X-CSRF-Token': document.head.querySelector("[name='csrf-token']").content
				}
			}
		})
	}

    connect() {
      // Called every time the controller is connected to the DOM
			console.log("filepond controller connected")
    }

    disconnect() {
        // Called when the controller is disconnected from the DOM
    }
}