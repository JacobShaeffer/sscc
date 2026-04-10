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

    connect() {
		FilePond.registerPlugin(FilePondPluginFileValidateType);
		FilePond.registerPlugin(FilePondPluginFileValidateSize);

		this.input = this.element.querySelector('input[type="file"]');
		this.form = this.element.closest('form');
		this.submit = this.form?.querySelector('input[type="submit"], button[type="submit"]');

		if (!this.input || !this.form) return;

		this.inputName = this.input.name;
		this.input.name = '';

		this.pond = FilePond.create(this.input, {
			acceptedFileTypes: this.extensionsValue,
			maxFileSize: '265MB',
			credits: ['https://pqina.nl/filepond/', 'Powered by FilePond'],
			files: this.existingFiles(),
			onaddfilestart: () => {
				this.setSubmitDisabled(true);
			},
			onprocessfile: (error) => {
				if (error) {
					console.log("error");
					console.log(error);
				}
				else{
					this.setSubmitDisabled(false);
				}
			},
			onrestore: () => {
				this.setSubmitDisabled(false);
			},
			server: {
				process: (fieldName, file, metadata, load, error, progress, abort) => {
					const uploader = new DirectUpload(file, this.input.dataset.directUploadUrl, {
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
							this.replaceHiddenField(blob.signed_id);
							load(blob.signed_id)
						}
					})

					return {
						abort: () => abort()
					}
				},
				load: (source, load, error, progress, abort) => {
					const sourceUrl = typeof source === 'string' ? source : source?.url;

					if (!sourceUrl) {
						error('Missing source URL');
						return {
							abort: () => abort(),
						};
					}

					fetch(sourceUrl)
						.then(response => response.blob())
						.then(load);
					
					return {
						abort: () => {
							abort();
						}
					};
				},
				revert: {
					url: '/filepond/remove'
				},
				headers: {
					'X-CSRF-Token': document.head.querySelector("[name='csrf-token']").content
				}
			}
		});
    }

	disconnect() {
		this.pond?.destroy();
	}

	setSubmitDisabled(disabled) {
		if (this.submit) {
			this.submit.disabled = disabled;
		}
	}

	replaceHiddenField(signedId) {
		const existingHiddenField = this.form.querySelector('[data-filepond-hidden-field="true"]');
		if (existingHiddenField) existingHiddenField.remove();

		const hiddenField = document.createElement('input');
		hiddenField.setAttribute('type', 'hidden');
		hiddenField.setAttribute('value', signedId);
		hiddenField.setAttribute('data-filepond-hidden-field', 'true');
		hiddenField.name = this.inputName;
		this.form.appendChild(hiddenField);
	}

	existingFiles() {
		const fileUrl = this.input.dataset.filepondFileUrl;
		const fileName = this.input.dataset.filepondFileName;
		const fileSize = this.input.dataset.filepondFileSize;
		const fileType = this.input.dataset.filepondFileType;

		if (!fileUrl || !fileName) return [];

		return [{
			source: fileUrl,
			options: {
				type: 'local',
				file: {
					name: fileName,
					size: fileSize,
					type: fileType,
				}
			}
		}];
	}
}
