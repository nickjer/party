import { Controller } from "@hotwired/stimulus"

// Reflects the live range value onto the dial marker while a guesser drags it.
// No network traffic — the value is only persisted on form submit (lock in).
export default class extends Controller {
  static targets = ["input", "marker"]

  move() {
    if (this.hasMarkerTarget) {
      this.markerTarget.style.left = `${this.inputTarget.value}%`
    }
  }
}
