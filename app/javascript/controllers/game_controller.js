import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { over: Boolean }

  connect() {
    this.focusInput()
  }

  focusInput() {
    if (this.hasInputTarget && !this.overValue) {
      this.inputTarget.focus()
    }
  }

  // Prevent default Enter key behavior (which would submit form twice with Turbo)
  // and clear input after Turbo processes the response
  submitGuess(event) {
    // Allow Turbo to handle the form submission naturally
  }
}
