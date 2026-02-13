// Import external dependencies
import jquery from "jquery"
import "@popperjs/core"
import * as bootstrap from "bootstrap"
import "bootstrap-datepicker"
import Cookies from "js-cookie"
import "@hotwired/turbo-rails"

// Import and start Stimulus
import "controllers"

// Make jQuery available globally (needed for legacy code and Bootstrap)
window.$ = window.jQuery = jquery;

// Make Bootstrap available globally
window.bootstrap = bootstrap;

// Make Cookies available globally
window.Cookies = Cookies;

// Import local modules
import "cable"
import "tasks"

document.addEventListener('turbo:load', function() {
  // Initialize Bootstrap tooltips (Bootstrap 5 native API)
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new
  bootstrap.Tooltip(tooltipTriggerEl, {
    trigger: 'hover'
  }));

  // fade out alerts after an initial delay
  $('[data-fade-out]').delay(4000).fadeTo(500, 0).slideUp(500, function() {
    $(this).remove();
  });
});

$(document).on('click', '#toggle_new_task_form_control', function() {
  $('#new_task_container').slideToggle('fast', function () { save_new_task_form_state() });
  return false;
});

$(document).on('click', '.editable-due-date', function () {
  //due_date = $(this).html();
  //task_id = $(this).data('task-id');
  //alert("This is the due date for task " + task_id + ": " + due_date);
  //$(this).datepicker({ format: 'yyyy-mm-dd', autoclose: true, todayBtn: "linked", todayHighlight: true, clearBtn: true, daysOfWeekHighlighted: '06', zIndexOffset: 2000 });
});

// save the visibility state of the new task form using HTML5 local storage
function save_new_task_form_state() {
  if ( $('#new_task_container').is(':visible') ) {
    Cookies.set('display_new_task_form', true);
  } else {
    Cookies.set('display_new_task_form', false);
  }
}

// read the search result sort_by selector and reload the page using its
// value as the new sort_by parameter
function search_results_sort_by() {
  // obtain the select tag value
  const val = $('#sort_by').val();

  // obtain the current url
  let url = $(location).attr('href');
  // strip out any previous occurances of '&sort_by=...'
  if (url.match(/&sort_by=.*/) != null) {
    url = url.replace(/&sort_by=.*/, '&sort_by=' + val);
  } else {
    url = url + '&sort_by=' + val;
  }

  // reload the page
  location.href = url;
}
// Make it globally accessible
window.search_results_sort_by = search_results_sort_by;
