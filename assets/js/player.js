import { create } from 'asciinema-player';

export function createPlayer(src, container, opts) {
  if (opts.customTerminalFontFamily) {
    opts.terminalFontFamily = `${opts.customTerminalFontFamily},Consolas,Menlo,'Bitstream Vera Sans Mono',monospace,'Powerline Symbols'`;

    return document.fonts.load(`1em ${opts.customTerminalFontFamily}`).then(() => {
      console.log(`loaded font ${opts.customTerminalFontFamily}`);
      return create(src, container, opts);
    }).catch(error => {
      console.log(`failed to load font ${opts.customTerminalFontFamily}`, error);
      return create(src, container, opts);
    });
  } else {
    return create(src, container, opts);
  }
}

const CONTAINER_VERTICAL_PADDING = 2 * 4;
const APPROX_CHAR_WIDTH = 7;
const APPROX_CHAR_HEIGHT = 16;

export function cinemaHeight(cols, rows) {
  const ratio = (rows * APPROX_CHAR_HEIGHT) / (cols * APPROX_CHAR_WIDTH);
  const height = Math.round(CONTAINER_VERTICAL_PADDING + 100 * ratio);
  return `${height}vw`;
}
