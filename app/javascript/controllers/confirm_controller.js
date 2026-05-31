import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Routes Turbo's data-turbo-confirm through a styled modal dialog instead of
// the browser's native window.confirm.
export default class extends Controller {
  static targets = ["dialog", "message"]

  connect() {
    Turbo.config.forms.confirm = (message) => this.confirm(message)
  }

  confirm(message) {
    this.messageTarget.textContent = message
    this.dialogTarget.showModal()

    return new Promise((resolve) => {
      this.dialogTarget.addEventListener(
        "close",
        () => resolve(this.dialogTarget.returnValue === "confirm"),
        { once: true }
      )
    })
  }

  // Clicking the backdrop (the dialog element itself, outside its content)
  // dismisses the dialog as a cancel.
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
