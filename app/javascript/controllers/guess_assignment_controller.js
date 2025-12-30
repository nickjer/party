import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Drag-and-drop assignment of answers to players.
// CSS handles styling based on parent container - no class manipulation needed.
export default class extends Controller {
  static targets = ["pool", "playerSlot", "overlay"]
  static values = { url: String }

  sortables = []

  connect() {
    const options = {
      group: "answers",
      animation: 150,
      ghostClass: "opacity-50",
      onEnd: (event) => this.handleDrop(event)
    }

    this.sortables.push(new Sortable(this.poolTarget, options))
    this.playerSlotTargets.forEach((slot) => {
      this.sortables.push(new Sortable(slot, options))
    })
  }

  disconnect() {
    this.sortables.forEach((sortable) => sortable.destroy())
  }

  handleDrop(event) {
    const answer = event.item
    const toSlot = event.to
    const fromPlayerId = event.from.dataset.playerId
    const toPlayerId = toSlot.dataset.playerId

    if (toPlayerId) {
      this.moveDisplacedAnswersToPool(toSlot, answer)
      this.sendAssignment(toPlayerId, answer.dataset.answerId)
    } else if (fromPlayerId) {
      this.sendAssignment(fromPlayerId, null)
    }
  }

  unassign(event) {
    const slot = event.target.closest("[data-player-id]")
    const answer = event.target.closest("[data-answer-id]")

    if (slot && answer) {
      this.poolTarget.appendChild(answer)
      this.sendAssignment(slot.dataset.playerId, null)
    }
  }

  moveDisplacedAnswersToPool(slot, droppedAnswer) {
    slot.querySelectorAll("[data-answer-id]").forEach((answer) => {
      if (answer !== droppedAnswer) {
        this.poolTarget.appendChild(answer)
      }
    })
  }

  async sendAssignment(playerId, answerId) {
    this.overlayTarget.classList.remove("d-none")

    const formData = new FormData()
    formData.append("guess_assignment[player_id]", playerId)
    formData.append("guess_assignment[answer_id]", answerId || "")

    try {
      await fetch(this.urlValue, {
        method: "PATCH",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content || ""
        }
      })
    } catch (error) {
      console.error("Assignment failed:", error)
    } finally {
      this.overlayTarget.classList.add("d-none")
    }
  }
}
