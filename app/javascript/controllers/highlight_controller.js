import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.backgroundColor = "#ffffcc"

    // Two animation frames ensure the browser paints the yellow before the
    // transition begins, so the fade is always visible.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.style.transition = "background-color 2s ease"
        this.element.style.backgroundColor = ""
      })
    })
  }

  disconnect() {
    this.element.style.transition = ""
    this.element.style.backgroundColor = ""
  }
}
