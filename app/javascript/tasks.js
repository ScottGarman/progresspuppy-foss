// Initialize datepickers on both full page loads and Turbo Drive navigations
document.addEventListener('turbo:load', () => {
  if (typeof $ !== 'undefined') {
    $('.date-picker-input').datepicker({
      format: 'yyyy-mm-dd',
      autoclose: true,
      todayBtn: "linked",
      todayHighlight: true,
      clearBtn: true,
      daysOfWeekHighlighted: '06',
      zIndexOffset: 2000
    });
  }
});
