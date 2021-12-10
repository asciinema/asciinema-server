import css from '../css/app.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";
import { create } from 'asciinema-player';

window.createPlayer = create;

$(function() {
  $('input[data-behavior=focus]:first').focus().select();
  $('[data-toggle="popover"]').popover({ html: true });

  $("input[data-behavior=auto-select]").click(function() {
    this.select();
  });

  if ($('meta[name=referrer][content=origin]').length > 0) {
    $('a[href*=http]').attr('rel', 'noreferrer');
  }

  const players = window.players || new Map();

  for (const [id, props] of players) {
    create(props.src, document.getElementById(id), props);
  };
});
