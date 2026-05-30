import { Controller } from "@hotwired/stimulus"

// Toggles the spymaster's secret key (card color tints) on and off.
// Hidden by default so a glance over the shoulder reveals nothing.
export default class extends Controller {
  static targets = ["card", "button"]

  connect() {
    this.visible = false
  }

  toggle() {
    this.visible = !this.visible

    this.cardTargets.forEach((card) => {
      const classes = card.dataset.identityClass.split(" ")
      classes.forEach((name) => card.classList.toggle(name, this.visible))
    })

    if (this.hasButtonTarget) {
      this.buttonTarget.innerHTML = this.visible
        ? '<i class="bi bi-eye-slash-fill me-1"></i>Hide key'
        : '<i class="bi bi-eye-fill me-1"></i>Show key'
    }
  }
}
