import css from '../css/app-player-v3.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";
import { create } from 'asciinema-player';

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
  console.debug(players);

  for (const [id, props] of players) {
    create(props.src, document.getElementById(id), props);
  };
});

window.createPlayer = (src, elem, opts) => {
  create(props.src, elem, opts);
}
