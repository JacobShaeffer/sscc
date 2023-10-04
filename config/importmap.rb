# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "popper", to: "popper.js", preload: true
pin "bootstrap", to: "bootstrap.min.js", preload: true
# pin "filepond", to: "vendor/assets/javascripts/filepond.min.js", preload: true
# pin "filepond-plugin-file-validate-size", to: "vendor/assets/javascripts/filepond-plugin-file-validate-size.min.js", preload: true
# pin "filepond-plugin-file-validate-type", to: "vendor/assets/javascripts/filepond-plugin-file-validate-type.min.js", preload: true
pin "filepond" # @4.30.4
pin "filepond-plugin-file-validate-size" # @2.2.8
pin "filepond-plugin-file-validate-type" # @1.2.8
pin "activestorage", to: "https://ga.jspm.io/npm:activestorage@5.2.8-1/app/assets/javascripts/activestorage.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.8/lib/assets/compiled/rails-ujs.js"
