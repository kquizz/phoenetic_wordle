import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = "Share Result"
      }, 2000)
    } catch {
      const textarea = document.createElement("textarea")
      textarea.value = this.textValue
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = "Share Result"
      }, 2000)
    }
  }
}
