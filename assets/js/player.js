import { create } from 'asciinema-player';

const DEFAULT_FONT_FAMILY = 'ui-monospace,"Cascadia Code","Source Code Pro",Menlo,Consolas,"DejaVu Sans Mono",monospace,"Symbols Nerd Font"';

export async function createPlayer(src, container, opts) {
  if (opts.customTerminalFontFamily) {
    try {
      if (await isFamilyLoaded(opts.customTerminalFontFamily)) {
        console.info(`loaded font ${opts.customTerminalFontFamily}`);

        return create(src, container, {
          ...opts,
          terminalFontFamily: `'${opts.customTerminalFontFamily}',${DEFAULT_FONT_FAMILY}`
        });
      } else {
        console.error(`font ${opts.customTerminalFontFamily} didn't load`);
      }
    } catch (error) {
      console.error(`failed to load font ${opts.customTerminalFontFamily}:`, error);
    }

    console.info('falling back to default font family');
  }

  return create(src, container, {
    ...opts,
    terminalFontFamily: DEFAULT_FONT_FAMILY
  });
}

function normalizedFamily(s) {
  return s.replace(/^['"]|['"]$/g, "");
}

async function isFamilyLoaded(family) {
  const font = `normal 400 normal 1em "${family}"`;
  const faces = await document.fonts.load(font, "aZ0");

  return faces.some(f =>
    normalizedFamily(f.family) === family &&
    String(f.weight) === "400" &&
    f.style === "normal" &&
    f.stretch === "normal" &&
    f.status === "loaded"
  );
}

const CONTAINER_VERTICAL_PADDING = 2 * 4;
const APPROX_CHAR_WIDTH = 7;
const APPROX_CHAR_HEIGHT = 16;

export function cinemaHeight(cols, rows) {
  const ratio = (rows * APPROX_CHAR_HEIGHT) / (cols * APPROX_CHAR_WIDTH);
  const height = Math.round(CONTAINER_VERTICAL_PADDING + 100 * ratio);
  return `${height}vw`;
}
