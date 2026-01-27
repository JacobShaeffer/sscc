import { Controller } from '@hotwired/stimulus';
import { get } from "@rails/request.js"

export const string_identifier = 'metadatareplace';

export default class extends Controller {
    static targets = ["replaceWithId"];
    static values = {
        url: String
    }

    replace(event) {
        event.preventDefault();

        let params = new URLSearchParams({
            replace_with: this.replaceWithIdTarget.value,
        });

        get(`${this.urlValue}?${params}`, {
            responseKind: "turbo-stream",
        });

    }
}