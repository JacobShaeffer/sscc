import { Controller } from '@hotwired/stimulus';

export const string_identifier = 'accordion';

export default class extends Controller {
    static targets = [ "collapseButton", "collapseContent" ];
    static values = { 
        type: String 
    };

    initialize() {
		// console.log("accordion controller initialized")
        if (this.getCookie('collapse'+this.typeValue) == 'open') {
            this.collapseContentTarget.classList.add("show");
            this.collapseButtonTarget.classList.remove("collapsed");
        }
    }

    /**
     * Get the value of a cookie
     * Source: https://gist.github.com/wpsmith/6cf23551dd140fb72ae7
     * @param  {String} name  The name of the cookie
     * @return {String}       The cookie value
     */
    getCookie (name) {
        let value = `; ${document.cookie}`;
        let parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
    }

    removeCookie (name) {
        document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    }
    addCookie (name, value, hours) {
        let expires = '';
        if (hours) {
            let date = new Date();
            date.setTime(date.getTime() + (hours*60*60*1000));
            expires = '; expires=' + date.toUTCString();
        }
        document.cookie = name + '=' + value + expires + '; path=/';
    }


    toggleCollapse(event) {
        let cookieName = 'collapse'+this.typeValue;
        if (this.collapseContentTarget.classList.contains("show")) {
            this.collapseContentTarget.classList.remove("show");
            this.collapseButtonTarget.classList.add("collapsed");

            // Cookies.remove(cookieName);
            this.removeCookie(cookieName);

            // console.log(cookieName, " -- cookie removed");
            // console.log("all cookies: ", Cookies.get());
        } else {
            this.collapseContentTarget.classList.add("show");
            this.collapseButtonTarget.classList.remove("collapsed");
            // Cookies.set(cookieName, 'open', { expires: expDate });
            this.addCookie(cookieName, 'open', 4);

            // console.log('collapse'+this.typeValue, " -- cookie added");
            // console.log("all cookies: ", Cookies.get());
        }
    }
}