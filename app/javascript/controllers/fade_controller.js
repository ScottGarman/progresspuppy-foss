import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.display = "block"
    setTimeout(() => {
      this.element.style.transition = "opacity 2s"
      this.element.style.opacity = "0"
    }, 800)
  }
}
