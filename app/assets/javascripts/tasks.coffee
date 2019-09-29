# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'turbolinks:load', (e) ->
  $('.date-picker-input').datepicker({ format: 'yyyy-mm-dd', autoclose: true, todayBtn: "linked", todayHighlight: true, clearBtn: true, daysOfWeekHighlighted: '06', zIndexOffset: 2000 })