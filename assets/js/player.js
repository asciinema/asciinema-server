import { create } from 'asciinema-player';

export function createPlayer(src, container, opts) {
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
