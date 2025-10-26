import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Monitors the Turbo Cable connection and handles disconnections
export default class extends Controller {
  static targets = ["stream", "frame", "dialog"]

  connect() {
    this.wasDisconnected = false
  }

  streamTargetConnected(streamElement) {
    this.observer = new MutationObserver(this.handleConnectionChange.bind(this))
    this.observer.observe(streamElement, {
      attributes: true,
      attributeFilter: ["connected"]
    })
  }

  streamTargetDisconnected() {
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  handleConnectionChange(mutations) {
    const streamElement = this.streamTarget
    const isConnected = streamElement.hasAttribute("connected")

    if (!isConnected) {
      this.handleDisconnection()
    } else if (this.wasDisconnected) {
      this.handleReconnection()
    }
  }

  handleDisconnection() {
    this.wasDisconnected = true

    // Disable the game frame
    if (this.hasFrameTarget) {
      this.frameTarget.style.pointerEvents = "none"
      this.frameTarget.style.opacity = "0.5"
    }

    // Show the disconnection modal
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
    }
  }

  handleReconnection() {
    // Re-enable the game frame
    if (this.hasFrameTarget) {
      this.frameTarget.style.pointerEvents = ""
      this.frameTarget.style.opacity = ""
    }

    // Close the disconnection modal
    if (this.hasDialogTarget) {
      this.dialogTarget.close()
    }

    // Refresh the game frame to get the latest state
    if (this.hasFrameTarget) {
      Turbo.visit(location.href, { frame: this.frameTarget.id })
    }

    this.wasDisconnected = false
  }
}
