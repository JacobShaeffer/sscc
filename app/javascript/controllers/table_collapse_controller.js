import { Controller } from '@hotwired/stimulus';

export const string_identifier = 'table_collapse';

export default class extends Controller {
    static targets = ['collapse'];

    toggle(event) {
        this.collapseTarget.classList.toggle('show');
    }
}