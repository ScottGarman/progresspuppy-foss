import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.modalEl = this.element.classList.contains('modal')
      ? this.element
      : this.element.querySelector('.modal')
    if (!this.modalEl) return

    this.handleHidden = () => this.element.remove()
    this.modalEl.addEventListener("hidden.bs.modal", this.handleHidden)

    const modal = bootstrap.Modal.getOrCreateInstance(this.modalEl)
    modal.show()
  }

  disconnect() {
    if (this.modalEl) {
      this.modalEl.removeEventListener("hidden.bs.modal", this.handleHidden)
      const modal = bootstrap.Modal.getInstance(this.modalEl)
      if (modal) modal.dispose()
    }
  }
}
