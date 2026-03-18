import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "cell", "inputRow"]
  static values = {
    id: Number,
    url: String,
    over: Boolean,
    maxGuesses: Number,
    currentGuess: Number
  }

  connect() {
    this.focusInput()
  }

  focusInput() {
    if (this.hasInputTarget && !this.overValue) {
      this.inputTarget.focus()
    }
  }

  async submitGuess() {
    if (this.overValue) return

    const input = this.inputTarget
    const guess = input.value.trim()
    if (!guess) return

    input.disabled = true

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
        },
        body: new URLSearchParams({ guess: guess })
      })

      const html = await response.text()
      Turbo.renderStreamMessage(html)

      input.value = ""
      this.currentGuessValue++

      if (this.currentGuessValue >= this.maxGuessesValue) {
        this.overValue = true
      }
    } catch (error) {
      console.error("Guess submission failed:", error)
    } finally {
      input.disabled = false
      this.focusInput()
    }
  }
}
