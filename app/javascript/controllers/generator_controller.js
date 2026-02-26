import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "output", "content", "temperatureValue"]

  updateTemperature(event) {
    this.temperatureValueTarget.textContent = event.target.value
  }

  async streamGenerate(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)

    const response = await fetch("/articles", {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    })

    const data = await response.json()

    if (!response.ok || !data.id) {
      alert(data.errors ? data.errors.join(", ") : "Ошибка создания статьи")
      return
    }

    this.outputTarget.classList.remove("hidden")
    this.contentTarget.innerHTML = '<p class="text-stone-400 text-sm font-sans animate-pulse">Генерация...</p>'

    const eventSource = new EventSource(`/articles/${data.id}/stream`)

    let firstChunk = true
    eventSource.onmessage = (event) => {
      if (event.data === "[DONE]") {
        eventSource.close()
        this.contentTarget.innerHTML += '<p class="mt-4 text-stone-400 text-sm font-sans">✓ Генерация завершена. <a href="/articles/' + data.id + '" class="underline">Открыть статью →</a></p>'
        return
      }

      if (firstChunk) {
        this.contentTarget.innerHTML = ""
        firstChunk = false
      }

      const text = JSON.parse(event.data)
      this.contentTarget.innerHTML += text.replace(/\n/g, "<br>")
    }

    eventSource.onerror = () => {
      eventSource.close()
      this.contentTarget.innerHTML += '<p class="mt-4 text-red-500 text-sm font-sans">Соединение закрыто</p>'
    }
  }
}
