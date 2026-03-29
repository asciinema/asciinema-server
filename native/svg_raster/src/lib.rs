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

const CELL_X_RES: usize = 8;
const CELL_Y_RES: usize = 24;
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

    let img_w = cols * CELL_X_RES;
    let img_h = rows * CELL_Y_RES;
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
            start_x * CELL_X_RES,
            y * CELL_Y_RES,
            end_x * CELL_X_RES,
            (y + 1) * CELL_Y_RES,
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
    let bytes_per_pixel = 3;

    if pixels.len() != row_bytes * height {
        return Err(Error::Term(Box::new(atoms::invalid_data())));
    }

    let mut encoder = ZlibEncoder::new(Vec::new(), Compression::new(2));
    let mut row_with_filter = vec![0u8; row_bytes + 1];
    row_with_filter[0] = 1; // PNG filter type 1 (Sub)

    for y in 0..height {
        let from = y * row_bytes;
        let to = from + row_bytes;
        let row = &pixels[from..to];
        let filtered_row = &mut row_with_filter[1..];

        // PNG filter type 1 (Sub): each byte stores the difference from the previous pixel byte.
        filtered_row[..bytes_per_pixel].copy_from_slice(&row[..bytes_per_pixel]);

        for idx in bytes_per_pixel..row_bytes {
            filtered_row[idx] = row[idx].wrapping_sub(row[idx - bytes_per_pixel]);
        }

        encoder
            .write_all(&row_with_filter)
            .map_err(|_| Error::Term(Box::new(atoms::invalid_data())))?;
    }
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
    let base_x = cell_x * CELL_X_RES;
    let base_y = cell_y * CELL_Y_RES;
    let origin = (base_x, base_y);
    let unit_x = CELL_X_RES / 8;
    let unit_y = CELL_Y_RES / 8;
    let half_x = CELL_X_RES / 2;
    let half_y = CELL_Y_RES / 2;

    match cp {
        // box drawings heavy vertical (https://symbl.cc/en/2503/)
        0x2503 => fill_cell_rect(pixels, img_w, origin, (3, 0, 5, CELL_Y_RES), color),

        // box drawings heavy up (https://symbl.cc/en/2579/)
        0x2579 => fill_cell_rect(pixels, img_w, origin, (3, 0, 5, half_y), color),

        // box drawings heavy down (https://symbl.cc/en/257B/)
        0x257B => fill_cell_rect(pixels, img_w, origin, (3, half_y, 5, CELL_Y_RES), color),

        // upper half block
        0x2580 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, half_y), color),

        // lower one eighth block
        0x2581 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 7, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower one quarter block
        0x2582 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 6, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower three eighths block
        0x2583 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 5, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower half block
        0x2584 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, half_y, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower five eighths block
        0x2585 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 3, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower three quarters block
        0x2586 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 2, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // lower seven eighths block
        0x2587 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // full block
        0x2588 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, CELL_Y_RES), color),

        // left seven eighths block
        0x2589 => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x * 7, CELL_Y_RES), color),

        // left three quarters block
        0x258A => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x * 6, CELL_Y_RES), color),

        // left five eighths block
        0x258B => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x * 5, CELL_Y_RES), color),

        // left half block
        0x258C => fill_cell_rect(pixels, img_w, origin, (0, 0, half_x, CELL_Y_RES), color),

        // left three eighths block
        0x258D => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x * 3, CELL_Y_RES), color),

        // left one quarter block
        0x258E => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x * 2, CELL_Y_RES), color),

        // left one eighth block
        0x258F => fill_cell_rect(pixels, img_w, origin, (0, 0, unit_x, CELL_Y_RES), color),

        // right half block
        0x2590 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (half_x, 0, CELL_X_RES, CELL_Y_RES),
            color,
        ),

        // light shade
        0x2591 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, CELL_Y_RES), color),

        // medium shade
        0x2592 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, CELL_Y_RES), color),

        // dark shade
        0x2593 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, CELL_Y_RES), color),

        // upper one eighth block
        0x2594 => fill_cell_rect(pixels, img_w, origin, (0, 0, CELL_X_RES, unit_y), color),

        // right one eighth block
        0x2595 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (unit_x * 7, 0, CELL_X_RES, CELL_Y_RES),
            color,
        ),

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

        // black square (half-height, vertically centered)
        0x25A0 => fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, unit_y * 2, CELL_X_RES, unit_y * 6),
            color,
        ),

        cp => {
            if let Some(mask) = sextant_mask(cp) {
                fill_cell_sextants(pixels, img_w, origin, color, mask);
            }
        }
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

fn fill_cell_quadrants(
    pixels: &mut [u8],
    img_w: usize,
    (base_x, base_y): (usize, usize),
    color: Rgb8,
    (ul, ur, ll, lr): (bool, bool, bool, bool),
) {
    let half_x = CELL_X_RES / 2;
    let half_y = CELL_Y_RES / 2;

    if ul {
        fill_cell_rect(
            pixels,
            img_w,
            (base_x, base_y),
            (0, 0, half_x, half_y),
            color,
        );
    }

    if ur {
        fill_cell_rect(
            pixels,
            img_w,
            (base_x, base_y),
            (half_x, 0, CELL_X_RES, half_y),
            color,
        );
    }

    if ll {
        fill_cell_rect(
            pixels,
            img_w,
            (base_x, base_y),
            (0, half_y, half_x, CELL_Y_RES),
            color,
        );
    }

    if lr {
        fill_cell_rect(
            pixels,
            img_w,
            (base_x, base_y),
            (half_x, half_y, CELL_X_RES, CELL_Y_RES),
            color,
        );
    }
}

// Maps Unicode sextant codepoints (U+1FB00..U+1FB3B) to 6-bit masks.
// The range encodes masks 1–62, skipping values that duplicate existing characters:
//   0  = empty (no codepoint needed)
//   21 = left half block (U+258C)
//   42 = right half block (U+2590)
//   63 = full block (U+2588)
// The offset→mask formula adds 1, 2, or 3 to jump over these gaps.
fn sextant_mask(cp: u32) -> Option<u8> {
    if !(0x1FB00..=0x1FB3B).contains(&cp) {
        return None;
    }

    let offset = (cp - 0x1FB00) as u8;

    let shift = if offset < 20 {
        1
    } else if offset < 40 {
        2
    } else {
        3
    };

    Some(offset + shift)
}

fn fill_cell_sextants(
    pixels: &mut [u8],
    img_w: usize,
    origin: (usize, usize),
    color: Rgb8,
    mask: u8,
) {
    let sextant_x = CELL_X_RES / 2;
    let sextant_y = CELL_Y_RES / 3;

    if (mask & 0b000001) != 0 {
        fill_cell_rect(pixels, img_w, origin, (0, 0, sextant_x, sextant_y), color);
    }

    if (mask & 0b000010) != 0 {
        fill_cell_rect(
            pixels,
            img_w,
            origin,
            (sextant_x, 0, CELL_X_RES, sextant_y),
            color,
        );
    }

    if (mask & 0b000100) != 0 {
        fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, sextant_y, sextant_x, sextant_y * 2),
            color,
        );
    }

    if (mask & 0b001000) != 0 {
        fill_cell_rect(
            pixels,
            img_w,
            origin,
            (sextant_x, sextant_y, CELL_X_RES, sextant_y * 2),
            color,
        );
    }

    if (mask & 0b010000) != 0 {
        fill_cell_rect(
            pixels,
            img_w,
            origin,
            (0, sextant_y * 2, sextant_x, CELL_Y_RES),
            color,
        );
    }

    if (mask & 0b100000) != 0 {
        fill_cell_rect(
            pixels,
            img_w,
            origin,
            (sextant_x, sextant_y * 2, CELL_X_RES, CELL_Y_RES),
            color,
        );
    }
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

    let row_byte_len = (x1 - x0) * 3;
    let first_row_start = (y0 * img_w + x0) * 3;
    let first_row_end = first_row_start + row_byte_len;

    for px in pixels[first_row_start..first_row_end].chunks_exact_mut(3) {
        px[0] = r;
        px[1] = g;
        px[2] = b;
    }

    for y in (y0 + 1)..y1 {
        let row_start = (y * img_w + x0) * 3;
        let (before, after) = pixels.split_at_mut(row_start);
        let row = &mut after[..row_byte_len];
        let src = &before[first_row_start..first_row_end];
        row.copy_from_slice(src);
    }
}

rustler::init!("Elixir.Asciinema.SvgRaster");
