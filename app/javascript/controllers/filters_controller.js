import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
    static targets = ['form'];

    filter() {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            Rails.fire(this.formTarget, 'submit');
        }, 200);
    }
}