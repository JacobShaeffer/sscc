// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "controllers"
import "popper"
import "bootstrap"
import "@rails/request.js"

const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))