import { createPlayer } from './player';

window.createIframePlayer = async function(src, container, opts) {
  const fit = new URLSearchParams(window.location.search).get('fit') === 'width' ? 'width' : 'both';
  document.body.classList.add(`fit-${fit}`);

  if (fit === 'width' && window.parent !== window) {
    window.addEventListener('message', e => {
      if (e.source !== window.parent || e.data?.type !== 'textStyle') return;

      document.body.style.color = e.data.payload.color;
      document.body.style.fontFamily = `${e.data.payload.fontFamily}, sans-serif`;
      document.body.style.fontSize = e.data.payload.fontSize;
    });
  }

  const player = await createPlayer(src, container, { ...opts, fit });

  if (fit === 'width' && window.parent !== window) {
    // Observing the body includes the footer and reports the initial size too.
    new ResizeObserver(() => {
      const width = document.body.offsetWidth;
      const height = Math.max(document.body.scrollHeight, document.body.offsetHeight);
      window.parent.postMessage({ type: 'bodySize', payload: { width, height } }, '*');
    }).observe(document.body);
  }

  return player;
};
