import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// IMPORTANT: User Table Controller
// NOTE: Handles checkbox selection, toolbar button states, and bulk actions
// NOTA BENE: Uses Stimulus for declarative, maintainable JavaScript
// NOTA BENE: The toolbar, the table AND the confirm modal must all live inside the
//            SAME data-controller="user-table" element, otherwise targets are not found
export default class extends Controller {
  static targets = ["selectAll", "rowCheckbox", "btnBlock", "btnUnblock", "btnDelete", "bulkActionForm", "bulkActionType", "confirmModal", "confirmTitle", "confirmMessage"]

  static values = {
    confirmBlock: String,
    confirmUnblock: String,
    confirmDelete: String
  }

  // NOTE: Initialize controller
  connect() {
    this.updateToolbarState()
  }

  // IMPORTANT: Handle "Select All" checkbox change
  selectAll(event) {
    const checked = event.target.checked
    this.rowCheckboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateToolbarState()
  }

  // NOTE: Handle individual row checkbox change
  rowCheckboxChanged() {
    this.updateToolbarState()
    this.updateSelectAllState()
  }

  // NOTE: Update "Select All" checkbox indeterminate state
  updateSelectAllState() {
    const checkedCount = this.rowCheckboxTargets.filter(c => c.checked).length
    const totalCount = this.rowCheckboxTargets.length

    if (checkedCount === 0) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    } else if (checkedCount === totalCount) {
      this.selectAllTarget.checked = true
      this.selectAllTarget.indeterminate = false
    } else {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = true
    }
  }

  // IMPORTANT: Update toolbar button enabled/disabled state
  updateToolbarState() {
    const hasSelection = this.rowCheckboxTargets.some(c => c.checked)
    const isEnabled = hasSelection

    this.btnBlockTarget.disabled = !isEnabled
    this.btnUnblockTarget.disabled = !isEnabled
    this.btnDeleteTarget.disabled = !isEnabled
  }

  // NOTE: Handle toolbar button clicks
  block() { this.performAction('block', 'Block users', this.confirmBlockValue) }
  unblock() { this.performAction('unblock', 'Unblock users', this.confirmUnblockValue) }
  delete() { this.performAction('delete', 'Delete users', this.confirmDeleteValue) }

  // IMPORTANT: Perform bulk action with confirmation via Bootstrap modal
  // NOTA BENE: window.confirm() is a browser alert - forbidden by the task.
  //            A Bootstrap modal without "fade" is used instead (no animations allowed).
  performAction(action, title, confirmMessage) {
    const selectedCount = this.rowCheckboxTargets.filter(c => c.checked).length

    if (selectedCount === 0) return

    // Remember which action to run after the user confirms
    this.pendingAction = action

    this.confirmTitleTarget.textContent = title
    this.confirmMessageTarget.textContent = confirmMessage

    this.confirmModalInstance = bootstrap.Modal.getOrCreateInstance(this.confirmModalTarget)
    this.confirmModalInstance.show()
  }

  // NOTE: User confirmed in the modal - submit the form with the chosen action
  confirmOk() {
    if (this.confirmModalInstance) this.confirmModalInstance.hide()

    this.bulkActionTypeTarget.value = this.pendingAction
    this.bulkActionFormTarget.submit()
  }
}