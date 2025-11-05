import { Controller } from '@hotwired/stimulus';
import { get } from "@rails/request.js"

export const string_identifier = 'metadatum_replace';

export default class extends Controller {
    static targets = ["replaceWithId"];
    static values = {
        url: String
    }

    replace(event) {
        event.preventDefault();
        console.log("metadatumReplace#replace", );
        console.log("replace_with_id: ", this.replaceWithIdTarget.value);
        console.log(this.urlValue);

        let params = new URLSearchParams({
            replace_with: this.replaceWithIdTarget.value,
        });

        get(`${this.urlValue}?${params}`, {
            responseKind: "turbo-stream",
        });

    }
}