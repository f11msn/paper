import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import remend from "remend"

export default class extends Controller {
  static targets = ["form", "output", "content", "temperatureValue"]

  updateTemperature(event) {
    this.temperatureValueTarget.textContent = event.target.value
  }

  async streamGenerate(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const csrfToken = formData.get("authenticity_token") || document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch("/articles", {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      }
    })

    if (!response.ok) {
      const text = await response.text()
      let errorMsg
      try {
        const json = JSON.parse(text)
        errorMsg = json.errors ? json.errors.join(", ") : `HTTP ${response.status}`
      } catch {
        errorMsg = `HTTP ${response.status}: ${text.substring(0, 200)}`
      }
      alert("Ошибка: " + errorMsg)
      return
    }

    const data = await response.json()

    if (!data.id) {
      alert("Ошибка: сервер не вернул ID статьи")
      return
    }

    this.outputTarget.classList.remove("hidden")
    this.contentTarget.innerHTML = '<p class="text-stone-400 text-sm font-sans animate-pulse">Генерация...</p>'

    const eventSource = new EventSource(`/articles/${data.id}/stream`)
    let rawMarkdown = ""
    let firstChunk = true

    eventSource.onmessage = (event) => {
      if (event.data === "[DONE]") {
        eventSource.close()
        this.contentTarget.innerHTML = marked.parse(rawMarkdown)
        this.contentTarget.innerHTML += '<p class="mt-4 text-stone-400 text-sm font-sans">✓ Генерация завершена. <a href="/articles/' + data.id + '" class="underline">Открыть статью →</a></p>'
        return
      }

      if (firstChunk) {
        this.contentTarget.innerHTML = ""
        firstChunk = false
      }

      const text = JSON.parse(event.data)
      rawMarkdown += text
      this.contentTarget.innerHTML = marked.parse(remend(rawMarkdown))
    }

    eventSource.onerror = () => {
      eventSource.close()
      this.contentTarget.innerHTML = marked.parse(remend(rawMarkdown))
      this.contentTarget.innerHTML += '<p class="mt-4 text-red-500 text-sm font-sans">Соединение закрыто</p>'
    }
  }
}
