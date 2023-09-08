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

		var directUploadUrl;
		const input = document.querySelector('input[type="file"]');
		if (input) {
			directUploadUrl = input.dataset.directUploadUrl;
		}

		const submit = document.querySelector('input[type="submit"]');

		// acceptedFileTypes: ['image/png', 'image/jpeg', 'application/pdf'],
		FilePond.setOptions({
			acceptedFileTypes: this.extensionsValue,
			maxFileSize: '265MB',
			credits: ['https://pqina.nl/filepond/', 'Powered by FilePond'],
			onaddfilestart: (file) => {
				submit.disabled = true;
			},
			onprocessfile: (error, file) => {
				if (error) {
					console.log("error");
					console.log(error);
				}	
				else {
					submit.disabled = false;
				}
			},
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

		if (input) {
			FilePond.create( input );
		}
	}
}