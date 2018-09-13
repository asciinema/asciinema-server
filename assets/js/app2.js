import css from '../css/app2.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";

$(function() {
  $('input[data-behavior=focus]:first').focus().select();
  $('[data-toggle="popover"]').popover({ html: true });
});
