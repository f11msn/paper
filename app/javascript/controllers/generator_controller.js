import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "output", "content", "temperatureValue"]

  updateTemperature(event) {
    this.temperatureValueTarget.textContent = event.target.value
  }

  async streamGenerate(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams()
    params.set("topic", formData.get("article[topic]"))
    params.set("rubric", formData.get("article[rubric]"))
    params.set("system_prompt", formData.get("article[system_prompt]"))
    params.set("temperature", formData.get("article[temperature]"))
    params.set("max_tokens", formData.get("article[max_tokens]"))
    params.set("model", formData.get("article[model]"))

    // First create the article to get an ID
    const response = await fetch("/articles", {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/html"
      },
      redirect: "manual"
    })

    // Extract article ID from redirect location
    const location = response.headers.get("Location")
    if (!location) {
      alert("Ошибка создания статьи")
      return
    }

    const articleId = location.split("/").pop()

    this.outputTarget.classList.remove("hidden")
    this.contentTarget.innerHTML = ""

    const eventSource = new EventSource(`/articles/${articleId}/stream`)

    eventSource.onmessage = (event) => {
      if (event.data === "[DONE]") {
        eventSource.close()
        this.contentTarget.innerHTML += '<p class="mt-4 text-stone-400 text-sm font-sans">✓ Генерация завершена</p>'
        return
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
