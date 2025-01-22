import { Controller } from '@hotwired/stimulus';
import * as FilePond from "filepond";
import FilePondPluginFileValidateType from 'filepond-plugin-file-validate-type';
import FilePondPluginFileValidateSize from 'filepond-plugin-file-validate-size';
import {DirectUpload} from "activestorage";

export const string_identifier = 'filepond';

export default class extends Controller {
	static values = {
		extensions: Array,
	}

    initialize() {
    	// Called once, when the controller is first instantiated
		// console.log("filepond controller initialized")
		FilePond.registerPlugin(FilePondPluginFileValidateType);
		FilePond.registerPlugin(FilePondPluginFileValidateSize);

		var directUploadUrl;
		const input = document.querySelector('input[type="file"]');
		if (input) {
			directUploadUrl = input.dataset.directUploadUrl;
		}

		const submit = document.querySelector('input[type="submit"]');

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
					// console.log("file: ", file);
					// this file object has a property called serverId which is the id of the blob
					// this can be used to show the content on the page after it's been uploaded
					//
					// The rails way to do this is the following:
					//url_for(user.avatar)
					//# => https://www.example.com/rails/active_storage/blobs/redirect/:signed_id/my-avatar.png
					// but I don't know if we can do this in the controller unless it's through turbo, but even then 
					// we would have to specify the controller and I don't know if we can do that

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