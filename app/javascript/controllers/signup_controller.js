import { Controller } from '@hotwired/stimulus';

export const string_identifier = 'signup';

export default class extends Controller {
    connect() {
        console.log("Signup controller connected");
    }

    setRole(event) {
        const role = event.currentTarget.dataset.role;
        console.log("Redirecting to join page with role:", role);
        
        // Redirect to the join page with the role parameter
        window.location.href = `/join?role=${role}`;
    }
}
