import css from '../css/app.scss';

import $ from 'jquery';
import "bootstrap";
import "phoenix_html";
import { create } from 'asciinema-player';

window.createPlayer = create;

function createPlayer(src, container, opts) {
  if (opts.customTerminalFontFamily) {
    opts.terminalFontFamily = `${opts.customTerminalFontFamily},Consolas,Menlo,'Bitstream Vera Sans Mono',monospace,'Powerline Symbols'`;

    document.fonts.load(`1em ${opts.customTerminalFontFamily}`).then(() => {
      console.log(`loaded font ${opts.customTerminalFontFamily}`);
      create(src, container, opts);
    }).catch(error => {
      console.log(`failed to load font ${opts.customTerminalFontFamily}`, error);
      create(src, container, opts);
    });
  } else {
    create(src, container, opts);
  }
}

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
    createPlayer(props.src, document.getElementById(id), { ...props, logger: console });
  };
});
