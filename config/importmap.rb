# Pin npm packages by running ./bin/importmap

pin "application"
pin "cable", to: "cable.js"
pin "tasks", to: "tasks.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# jQuery and Bootstrap dependencies - vendored locally by running:
# bin/importmap pin jquery@3.7.1
# bin/importmap pin @popperjs/core@2.11.8
# bin/importmap pin bootstrap@5.3.8
pin "jquery" # @3.7.1
pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
pin "bootstrap" # @5.3.8

# Additional libraries - vendored locally by running:
# bin/importmap pin js-cookie@2.2.0
# bin/importmap pin bootstrap-datepicker@1.10.0
pin "js-cookie" # @2.2.0
pin "bootstrap-datepicker" # @1.10.0

# Action Cable
pin "@rails/actioncable", to: "actioncable.esm.js"
