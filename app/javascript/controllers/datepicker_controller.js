import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $(this.element).datepicker({
      format: 'yyyy-mm-dd',
      autoclose: true,
      todayBtn: "linked",
      todayHighlight: true,
      clearBtn: true,
      daysOfWeekHighlighted: '06',
      zIndexOffset: 2000
    })
  }

  disconnect() {
    $(this.element).datepicker('destroy')
  }
}
