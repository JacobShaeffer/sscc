import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  file(event) {
    console.log('event', event);
    console.log('target value', event.target.value);
    // Check the file type here and respond to the form with a stream to do real-time validation????
  }
}
