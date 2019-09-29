// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require popper
//= require jquery3
//= require rails-ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.en-CA.js
//= require jstz
//= require js.cookie
//= require_tree .

$(document).ready(function() {
  // initialize tooltips
  $('[data-toggle="tooltip"]').tooltip({ trigger: 'hover' });

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
  val = $('#sort_by').val();

  // obtain the current url
  url = $(location).attr('href');
  // strip out any previous occurances of '&sort_by=...'
  if (url.match(/&sort_by=.*/) != null) {
    url = url.replace(/&sort_by=.*/, '&sort_by=' + val);
  } else {
    url = url + '&sort_by=' + val;
  }

  // reload the page
  location.href = url;
}