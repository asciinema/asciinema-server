import css from '../css/iframe.scss';

import { create } from 'asciinema-player';

const [id, props] = window.players.entries().next().value;
const player = create(props.src, document.getElementById(id), props);

if (window.parent !== window) {
  player.el.addEventListener('resize', e => {
    const w = e.detail.el.offsetWidth;
    const h = Math.max(document.body.scrollHeight, document.body.offsetHeight);
    window.parent.postMessage(['resize', { width: w, height: h }], '*');
  });
}
