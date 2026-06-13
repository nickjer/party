import { Controller } from "@hotwired/stimulus"

// Reflects the live range value onto the dial marker and value bubble while a
// guesser drags it. No network traffic — the value is only persisted on form
// submit (lock in).
export default class extends Controller {
  static targets = ["input", "marker", "value"]

  move() {
    const position = this.inputTarget.value
    if (this.hasMarkerTarget) {
      this.markerTarget.style.left = `${position}%`
    }
    if (this.hasValueTarget) {
      this.valueTarget.textContent = position
    }
  }
}
