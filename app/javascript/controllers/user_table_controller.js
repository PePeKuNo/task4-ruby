import { Controller } from "@hotwired/stimulus"

// IMPORTANT: User Table Controller
// NOTE: Handles checkbox selection, toolbar button states, and bulk actions
// NOTA BENE: Uses Stimulus for declarative, maintainable JavaScript
export default class extends Controller {
  static targets = ["selectAll", "rowCheckbox", "btnBlock", "btnUnblock", "btnDelete", "bulkActionForm", "bulkActionType"]

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
  block() { this.performAction('block', this.confirmBlockValue) }
  unblock() { this.performAction('unblock', this.confirmUnblockValue) }
  delete() { this.performAction('delete', this.confirmDeleteValue) }

  // IMPORTANT: Perform bulk action with confirmation
  performAction(action, confirmMessage) {
    const selectedCount = this.rowCheckboxTargets.filter(c => c.checked).length

    if (selectedCount === 0) return

    // Confirmation dialog
    if (confirmMessage && !confirm(confirmMessage)) {
      return
    }

    // Set action type and submit form
    this.bulkActionTypeTarget.value = action
    this.bulkActionFormTarget.submit()
  }
}