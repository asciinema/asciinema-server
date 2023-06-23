import css from '../css/app.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";
import { createPlayer } from './player';

window.createPlayer = createPlayer;

$(function() {
  $('input[data-behavior=focus]:first').focus().select();
  $('[data-toggle="popover"]').popover({ html: true });

  $("input[data-behavior=auto-select]").click(function() {
    this.select();
  });

  if ($('meta[name=referrer][content=origin]').length > 0) {
    $('a[href*=http]').attr('rel', 'noreferrer');
  }

  const m = `consulting@${window.location.hostname}`;
  $('.a-consulting code').replaceWith(`<a href="mailto:${m}">${m}</a>`);
});
