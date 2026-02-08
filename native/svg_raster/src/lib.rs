use std::io::Write;

use crc32fast::Hasher;
use flate2::write::ZlibEncoder;
use flate2::Compression;
use rustler::types::binary::{Binary, NewBinary};
use rustler::{Env, Error, NifResult};

mod atoms {
    rustler::atoms! {
        invalid_size,
        invalid_data,
    }
}

type Rgb8 = (u8, u8, u8);
type BgRun = (usize, usize, usize, Rgb8);
type MosaicBlock = (usize, usize, u32, Rgb8);

const CELL_V_RES: usize = 8;
const CELL_H_RES: usize = 8;
const MAX_TERM_COLS: usize = 720;
const MAX_TERM_ROWS: usize = 200;
const PNG_SIGNATURE: [u8; 8] = [137, 80, 78, 71, 13, 10, 26, 10];

#[rustler::nif(schedule = "DirtyCpu")]
fn render_png<'a>(
    env: Env<'a>,
    cols: usize,
    rows: usize,
    default_bg: Rgb8,
    bg_runs: Vec<BgRun>,
    mosaic_blocks: Vec<MosaicBlock>,
) -> NifResult<Binary<'a>> {
    if cols == 0 || rows == 0 || cols > MAX_TERM_COLS || rows > MAX_TERM_ROWS {
        return Err(Error::Term(Box::new(atoms::invalid_size())));
    }

    let img_w = cols * CELL_V_RES;
    let img_h = rows * CELL_H_RES;
    let pixel_count = img_w * img_h;
    let rgb_len = pixel_count * 3;
    let mut pixels = vec![0u8; rgb_len];
    fill_rect(&mut pixels, img_w, 0, 0, img_w, img_h, default_bg);

    for (y, x, width, color) in bg_runs {
        if y >= rows || width == 0 {
            continue;
        }

        let start_x = x.min(cols);
        let end_x = x.saturating_add(width).min(cols);

        if end_x <= start_x {
            continue;
        }

        fill_rect(
            &mut pixels,
            img_w,
            start_x * CELL_V_RES,
            y * CELL_H_RES,
            end_x * CELL_V_RES,
            (y + 1) * CELL_H_RES,
            color,
        );
    }

    for (y, x, cp, color) in mosaic_blocks {
        if y >= rows || x >= cols {
            continue;
        }

        draw_mosaic_block(&mut pixels, img_w, x, y, cp, color);
    }

    let png = encode_png_rgb8(img_w, img_h, &pixels)?;
    let mut out = NewBinary::new(env, png.len());
    out.as_mut_slice().copy_from_slice(&png);

    Ok(out.into())
}

fn encode_png_rgb8(width: usize, height: usize, pixels: &[u8]) -> NifResult<Vec<u8>> {
    let row_bytes = width * 3;

    if pixels.len() != row_bytes * height {
        return Err(Error::Term(Box::new(atoms::invalid_data())));
    }

    let mut raw = Vec::with_capacity((row_bytes + 1) * height);

    for y in 0..height {
        raw.push(0);
        let from = y * row_bytes;
        let to = from + row_bytes;
        raw.extend_from_slice(&pixels[from..to]);
    }

    let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
    encoder
        .write_all(&raw)
        .map_err(|_| Error::Term(Box::new(atoms::invalid_data())))?;

    let idat = encoder
        .finish()
        .map_err(|_| Error::Term(Box::new(atoms::invalid_data())))?;

    let mut png = Vec::with_capacity(PNG_SIGNATURE.len() + 128 + idat.len());
    png.extend_from_slice(&PNG_SIGNATURE);

    let ihdr = [
        (width as u32).to_be_bytes().as_slice(),
        (height as u32).to_be_bytes().as_slice(),
        &[8, 2, 0, 0, 0],
    ]
    .concat();

    append_chunk(&mut png, b"IHDR", &ihdr);
    append_chunk(&mut png, b"IDAT", &idat);
    append_chunk(&mut png, b"IEND", &[]);

    Ok(png)
}

fn append_chunk(out: &mut Vec<u8>, chunk_type: &[u8; 4], data: &[u8]) {
    out.extend_from_slice(&(data.len() as u32).to_be_bytes());
    out.extend_from_slice(chunk_type);
    out.extend_from_slice(data);

    let mut hasher = Hasher::new();
    hasher.update(chunk_type);
    hasher.update(data);

    out.extend_from_slice(&hasher.finalize().to_be_bytes());
}

fn draw_mosaic_block(
    pixels: &mut [u8],
    img_w: usize,
    cell_x: usize,
    cell_y: usize,
    cp: u32,
    color: Rgb8,
) {
    let base_x = cell_x * CELL_V_RES;
    let base_y = cell_y * CELL_H_RES;
    let origin = (base_x, base_y);

    match cp {
        // upper half block
        0x2580 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 4), color),
        // lower one eighth block
        0x2581 => fill_cell_rect(pixels, img_w, origin, (0, 7, 8, 8), color),
        // lower one quarter block
        0x2582 => fill_cell_rect(pixels, img_w, origin, (0, 6, 8, 8), color),
        // lower three eighths block
        0x2583 => fill_cell_rect(pixels, img_w, origin, (0, 5, 8, 8), color),
        // lower half block
        0x2584 => fill_cell_rect(pixels, img_w, origin, (0, 4, 8, 8), color),
        // lower five eighths block
        0x2585 => fill_cell_rect(pixels, img_w, origin, (0, 3, 8, 8), color),
        // lower three quarters block
        0x2586 => fill_cell_rect(pixels, img_w, origin, (0, 2, 8, 8), color),
        // lower seven eighths block
        0x2587 => fill_cell_rect(pixels, img_w, origin, (0, 1, 8, 8), color),
        // full block
        0x2588 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 8), color),
        // left seven eighths block
        0x2589 => fill_cell_rect(pixels, img_w, origin, (0, 0, 7, 8), color),
        // left three quarters block
        0x258A => fill_cell_rect(pixels, img_w, origin, (0, 0, 6, 8), color),
        // left five eighths block
        0x258B => fill_cell_rect(pixels, img_w, origin, (0, 0, 5, 8), color),
        // left half block
        0x258C => fill_cell_rect(pixels, img_w, origin, (0, 0, 4, 8), color),
        // left three eighths block
        0x258D => fill_cell_rect(pixels, img_w, origin, (0, 0, 3, 8), color),
        // left one quarter block
        0x258E => fill_cell_rect(pixels, img_w, origin, (0, 0, 2, 8), color),
        // left one eighth block
        0x258F => fill_cell_rect(pixels, img_w, origin, (0, 0, 1, 8), color),
        // right half block
        0x2590 => fill_cell_rect(pixels, img_w, origin, (4, 0, 8, 8), color),
        // light shade
        0x2591 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 8), color),
        // medium shade
        0x2592 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 8), color),
        // dark shade
        0x2593 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 8), color),
        // upper one eighth block
        0x2594 => fill_cell_rect(pixels, img_w, origin, (0, 0, 8, 1), color),
        // right one eighth block
        0x2595 => fill_cell_rect(pixels, img_w, origin, (7, 0, 8, 8), color),
        // quadrant lower left
        0x2596 => fill_cell_quadrants(pixels, img_w, origin, color, (false, false, true, false)),
        // quadrant lower right
        0x2597 => fill_cell_quadrants(pixels, img_w, origin, color, (false, false, false, true)),
        // quadrant upper left
        0x2598 => fill_cell_quadrants(pixels, img_w, origin, color, (true, false, false, false)),
        // quadrant upper left and lower left and lower right
        0x2599 => fill_cell_quadrants(pixels, img_w, origin, color, (true, false, true, true)),
        // quadrant upper left and lower right
        0x259A => fill_cell_quadrants(pixels, img_w, origin, color, (true, false, false, true)),
        // quadrant upper left and upper right and lower left
        0x259B => fill_cell_quadrants(pixels, img_w, origin, color, (true, true, true, false)),
        // quadrant upper left and upper right and lower right
        0x259C => fill_cell_quadrants(pixels, img_w, origin, color, (true, true, false, true)),
        // quadrant upper right
        0x259D => fill_cell_quadrants(pixels, img_w, origin, color, (false, true, false, false)),
        // quadrant upper right and lower left
        0x259E => fill_cell_quadrants(pixels, img_w, origin, color, (false, true, true, false)),
        // quadrant upper right and lower left and lower right
        0x259F => fill_cell_quadrants(pixels, img_w, origin, color, (false, true, true, true)),
        _ => {}
    }
}

fn fill_cell_quadrants(
    pixels: &mut [u8],
    img_w: usize,
    (base_x, base_y): (usize, usize),
    color: Rgb8,
    (ul, ur, ll, lr): (bool, bool, bool, bool),
) {
    if ul {
        fill_cell_rect(pixels, img_w, (base_x, base_y), (0, 0, 4, 4), color);
    }

    if ur {
        fill_cell_rect(pixels, img_w, (base_x, base_y), (4, 0, 8, 4), color);
    }

    if ll {
        fill_cell_rect(pixels, img_w, (base_x, base_y), (0, 4, 4, 8), color);
    }

    if lr {
        fill_cell_rect(pixels, img_w, (base_x, base_y), (4, 4, 8, 8), color);
    }
}

fn fill_cell_rect(
    pixels: &mut [u8],
    img_w: usize,
    (base_x, base_y): (usize, usize),
    (local_x0, local_y0, local_x1, local_y1): (usize, usize, usize, usize),
    color: Rgb8,
) {
    fill_rect(
        pixels,
        img_w,
        base_x + local_x0,
        base_y + local_y0,
        base_x + local_x1,
        base_y + local_y1,
        color,
    );
}

fn fill_rect(
    pixels: &mut [u8],
    img_w: usize,
    x0: usize,
    y0: usize,
    x1: usize,
    y1: usize,
    (r, g, b): Rgb8,
) {
    if x1 <= x0 || y1 <= y0 {
        return;
    }

    for y in y0..y1 {
        let row_start = (y * img_w + x0) * 3;
        let row_end = (y * img_w + x1) * 3;
        let row = &mut pixels[row_start..row_end];

        for px in row.chunks_exact_mut(3) {
            px[0] = r;
            px[1] = g;
            px[2] = b;
        }
    }
}

rustler::init!("Elixir.Asciinema.SvgRaster");
