// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require vendor/es5-shim.min
//= require vendor/console-shim-min
//= require vendor/underscore-min
//= require vendor/backbone-min
//= require vendor/jquery.timeago
//= require backbone/ascii_io

$(function() {
  $('abbr.timeago').timeago();
});
