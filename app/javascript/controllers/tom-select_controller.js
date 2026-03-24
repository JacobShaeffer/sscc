import { Controller } from '@hotwired/stimulus';
import TomSelect from 'tom-select'

export default class extends Controller {
    static targets = [];
    static values = {
        url: String,
        field: String
    }

    initialize() {
        console.log("TomSelect - initialize")
    }

    connect() {
        console.log(this.urlValue);
        // Called every time the controller is connected to the DOM
        console.log("TomSelect - connect")

        const baseUrl = this.urlValue;
        const field = this.fieldValue;

        new TomSelect("#title",{
            plugins: {
                'remove_button': {
                    title: 'Remove this item',
                },
                'clear_button': {
                    title: 'Remove all selected options',
                },
            },
            create: false,
            valueField: 'name',
            labelField: 'name',
            searchField: 'name',
            load: (query, callback) => {
                if (!query.length) return callback()
                const url = `${baseUrl}?q=${encodeURIComponent(query)}&field=${encodeURIComponent(field)}`

                fetch(url)
                .then(r => r.json())
                .then(json => callback(json.items))
                .catch(() => callback())
            }
        });
    }

    disconnect() {
        // Called when the controller is disconnected from the DOM
    }
}