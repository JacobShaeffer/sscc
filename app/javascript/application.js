// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

import "./vendor/jquery"
import "js-cookie"

// import * as ActiveStorage from "activestorage"
// ActiveStorage.start()

// addEventListener("direct-upload:initialize", event => {
//     const { target, detail } = event
//     const { id, file } = detail
//         // <div class="direct-upload-container">
//         //     <div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
//         //         <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
//         //         <span class="direct-upload__filename"></span>
//         //     </div>
//         // </div>
//     target.insertAdjacentHTML("beforebegin", `
//         <div class="direct-upload-modal-background"></div>
//         <div class="direct-upload-modal">
//             <h3 class="pb-4">Uploading... Please Wait.</h3>
//             <div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
//                 <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
//                 <span class="direct-upload__filename"></span>
//             </div>
//             <p class="pt-4 mb-0">You will be redirected when the upload completes.</p>
//         </div>
//     `)
//     target.previousElementSibling.querySelector(`.direct-upload__filename`).textContent = file.name
// })

// addEventListener("direct-upload:start", event => {
//     const { id } = event.detail
//     const element = document.getElementById(`direct-upload-${id}`)
//     element.classList.remove("direct-upload--pending")
// })

// addEventListener("direct-upload:progress", event => {
//     const { id, progress } = event.detail
//     const progressElement = document.getElementById(`direct-upload-progress-${id}`)
//     progressElement.style.width = `${progress}%`
// })

// addEventListener("direct-upload:error", event => {
//     event.preventDefault()
//     const { id, error } = event.detail
//     const element = document.getElementById(`direct-upload-${id}`)
//     element.classList.add("direct-upload--error")
//     element.setAttribute("title", error)
// })

// addEventListener("direct-upload:end", event => {
//     const { id } = event.detail
//     const element = document.getElementById(`direct-upload-${id}`)
//     element.classList.add("direct-upload--complete")
// })

const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))