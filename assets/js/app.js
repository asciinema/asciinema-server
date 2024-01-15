import css from '../css/app.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";
import { createPlayer, cinemaHeight } from './player';

window.createPlayer = createPlayer;
window.cinemaHeight = cinemaHeight;

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

  document.querySelectorAll('#download-txt').forEach(link => {
    link.addEventListener('click', () => {
      link.href = window.location.origin + window.location.pathname + '.txt';
    })
  });
});


import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } });

// Connect if there are any LiveViews on the page
liveSocket.connect();
