import { Controller } from "@hotwired/stimulus"

// Slides the value bubble along with the range thumb (which doubles as the
// dial marker) while a guesser drags it. No network traffic — the value is
// only persisted on form submit (lock in).
export default class extends Controller {
  static targets = ["input", "value"]

  move() {
    const position = this.inputTarget.value
    if (this.hasValueTarget) {
      this.valueTarget.style.left = `${position}%`
      this.valueTarget.textContent = position
    }
  }
}
