import { Controller } from "@hotwired/stimulus"

// IMPORTANT: AI Assistant Controller (Parts 2 and 3)
// NOTE: Talks to the REAL API endpoints: POST /ai/chat (questions about the database)
//       and POST /ai/tools (tool calling that can control the app, e.g. filter users)
// NOTA BENE: No CSRF token is needed here - AiController skips verify_authenticity_token
export default class extends Controller {
  static targets = ["question", "answer", "statusFilter", "filterResult"]

  // IMPORTANT: Part 2 - ask a factual question, the answer comes from the real database
  async ask(event) {
    // NOTE: Suggested question chips pass their text via data-assistant-question-value.
    // IMPORTANT: The Stimulus event.params cache can be EMPTY on the very first action
    // right after page load, which made the first chip click silently do nothing.
    // NOTA BENE: So the attribute is also read directly from the clicked element as a
    // reliable fallback - a click must NEVER result in "nothing happened".
    const chip = event && event.target ? event.target : null
    const quick = (event && event.params && event.params.question) ||
      (chip && chip.getAttribute ? chip.getAttribute('data-assistant-question-value') : null)
    const question = quick || this.questionTarget.value.trim()

    if (!question) {
      this.answerTarget.textContent = 'Type a question first, or pick one of the suggested questions.'
      return
    }
    this.questionTarget.value = question

    this.answerTarget.innerHTML = '<span class="text-muted">Asking the AI...</span>'

    try {
      const response = await fetch("/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
        body: `question=${encodeURIComponent(question)}`
      })
      const data = await response.json()
      this.answerTarget.textContent = data.answer
    } catch (error) {
      this.answerTarget.textContent = "AI request failed: " + error.message
    }
  }

  // IMPORTANT: Part 3 - control the app through the AI tool "filter_users"
  async filter() {
    const status = this.statusFilterTarget.value

    this.filterResultTarget.innerHTML = '<span class="text-muted">Running the AI tool...</span>'

    try {
      const body = new URLSearchParams()
      body.append("tool", "filter_users")
      if (status) body.append("arguments[status]", status)

      const response = await fetch("/ai/tools", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
        body: body.toString()
      })
      const data = await response.json()
      const users = data.users || []

      // NOTA BENE: Build the list with textContent (never innerHTML) - user data is untrusted
      const count = document.createElement("div")
      count.className = "small text-muted mb-1"
      count.textContent = `The AI tool returned ${users.length} user(s), showing first ${Math.min(users.length, 10)}:`

      const list = document.createElement("ul")
      list.className = "list-group list-group-flush"
      users.slice(0, 10).forEach(user => {
        const item = document.createElement("li")
        item.className = "list-group-item px-0 py-1 small"
        item.textContent = `${user.full_name} — ${user.email} (${user.status})`
        list.appendChild(item)
      })

      this.filterResultTarget.innerHTML = ""
      this.filterResultTarget.appendChild(count)
      if (users.length > 0) this.filterResultTarget.appendChild(list)
    } catch (error) {
      this.filterResultTarget.textContent = "AI tool request failed: " + error.message
    }
  }
}
