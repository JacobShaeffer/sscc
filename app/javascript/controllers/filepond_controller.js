import { Controller } from '@hotwired/stimulus';
import * as FilePond from "filepond";
import {DirectUpload} from "activestorage"

export const string_identifier = 'filepond';

export default class extends Controller {
    static targets = [];

    initialize() {
      // Called once, when the controller is first instantiated
			console.log("filepond controller initialized")
    }

    connect() {
      // Called every time the controller is connected to the DOM
			console.log("filepond controller connected")

			const input = document.querySelector('input[type="file"]');
			console.log("this is a test", input);
			if(input){
				console.log("there is an input")
				FilePond.create( input );
			}

			const directUploadUrl = input.dataset.directUploadUrl

			FilePond.setOptions({
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
						headers: {
					'X-CSRF-Token': document.head.querySelector("[name='csrf-token']").content
					}
				}
			})
    }

    disconnect() {
        // Called when the controller is disconnected from the DOM
    }
}