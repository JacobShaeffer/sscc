import { Controller } from '@hotwired/stimulus';

export const string_identifier = 'accordion';

export default class extends Controller {
    static targets = [ "collapseButton", "collapseContent" ];
    static values = { 
        type: String 
    };

    //TODO: change this to use a custom cookieObject and use JSON.stringify/parse to interact with it
    // and make the cookie name unique to the app aka sscc_collapse

    initialize() {
        if ($.cookie('collapse'+this.typeValue) == 'open') {
            this.collapseContentTarget.classList.add("show");
            this.collapseButtonTarget.classList.remove("collapsed");
        }
    }

    toggleCollapse(event) {
        let cookieName = 'collapse'+this.typeValue;
        if (this.collapseContentTarget.classList.contains("show")) {
            this.collapseContentTarget.classList.remove("show");
            this.collapseButtonTarget.classList.add("collapsed");
            $.removeCookie(cookieName);

            console.log(cookieName, " -- cookie removed");
            console.log("all cookies: ", $.cookie());
        } else {
            this.collapseContentTarget.classList.add("show");
            this.collapseButtonTarget.classList.remove("collapsed");
            let expDate = new Date();
            expDate.setTime(expDate.getTime() + (4 * 60 * 60 * 1000));// 4 hours
            $.cookie(cookieName, 'open', { expires: expDate });

            console.log('collapse'+this.typeValue, " -- cookie added");
            console.log("all cookies: ", $.cookie());
        }
    }
}