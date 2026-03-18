import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timeout = setTimeout(() => {
      this.element.style.transition = "opacity 0.5s"
      this.element.style.opacity = "0"
      setTimeout(() => this.element.remove(), 500)
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
