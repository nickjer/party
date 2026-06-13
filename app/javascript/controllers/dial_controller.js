import { Controller } from "@hotwired/stimulus"

// Drives the shared Wavelength dial. Dragging moves the marker locally; the
// resting position is pushed to the server (which broadcasts it to the rest of
// the table) only once the guesser lets go. An incoming broadcast replaces the
// marker element, so we re-sync the slider to continue from the shared spot.
export default class extends Controller {
  static targets = ["input", "marker", "value"]
  static values = { url: String }

  // Live, local-only feedback while dragging.
  move() {
    const position = this.inputTarget.value
    this.markerTarget.style.left = `${position}%`
    this.valueTarget.textContent = position
  }

  // Push the resting position once the drag ends (mouseup / touchend / key).
  commit() {
    const body = new FormData()
    body.append("guess[position]", this.inputTarget.value)
    fetch(this.urlValue, {
      method: "PATCH",
      body,
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content || ""
      }
    })
  }

  // A broadcast swapped in a new marker; follow it so the next drag is smooth.
  markerTargetConnected(element) {
    const position = element.dataset.dialPosition
    if (position !== undefined && this.hasInputTarget) {
      this.inputTarget.value = position
    }
  }
}
