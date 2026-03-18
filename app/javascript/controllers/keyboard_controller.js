import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  press(event) {
    const key = event.currentTarget.dataset.key
    const input = document.querySelector("[data-game-target='input']")
    if (input && !input.disabled) {
      input.value += key
      input.focus()
    }
  }

  enter() {
    const gameController = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='game']"),
      "game"
    )
    if (gameController) {
      gameController.submitGuess()
    }
  }

  backspace() {
    const input = document.querySelector("[data-game-target='input']")
    if (input && !input.disabled) {
      input.value = input.value.slice(0, -1)
      input.focus()
    }
  }
}
