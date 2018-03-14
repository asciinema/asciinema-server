import css from '../css/app.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";

$(function() {
  $('input[data-behavior=focus]:first').focus().select();
});
