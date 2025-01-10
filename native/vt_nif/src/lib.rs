use avt::Vt;
use rustler::{Atom, Binary, Encoder, Env, Error, NifResult, ResourceArc, Term};
use std::{ops::RangeInclusive, sync::RwLock};

const BOX_DRAWING_RANGE: RangeInclusive<char> = '\u{2500}'..='\u{257f}';
const BLOCK_ELEMENTS_RANGE: RangeInclusive<char> = '\u{2580}'..='\u{259f}';
const BRAILLE_PATTERNS_RANGE: RangeInclusive<char> = '\u{2800}'..='\u{28ff}';
const POWERLINE_TRIANGLES_RANGE: RangeInclusive<char> = '\u{e0b0}'..='\u{e0b3}';

mod atoms {
    rustler::atoms! {
        ok,
        error,
        invalid_size,
    }
}

pub struct VtResource {
    vt: RwLock<Vt>,
}

fn load(env: Env, _info: Term) -> bool {
    rustler::resource!(VtResource, env);

    true
}

#[rustler::nif]
fn new(
    cols: usize,
    rows: usize,
    scrollback_limit: Option<usize>,
) -> NifResult<(Atom, ResourceArc<VtResource>)> {
    if cols > 0 && rows > 0 {
        let mut builder = Vt::builder();
        builder.size(cols, rows);

        if let Some(limit) = scrollback_limit {
            builder.scrollback_limit(limit);
        }

        let vt = builder.build();

        let resource = ResourceArc::new(VtResource {
            vt: RwLock::new(vt),
        });

        Ok((atoms::ok(), resource))
    } else {
        Err(Error::Term(Box::new(atoms::invalid_size())))
    }
}

#[rustler::nif]
fn feed(resource: ResourceArc<VtResource>, input: Binary) -> NifResult<Atom> {
    let mut vt = convert_err(resource.vt.write(), "rw_lock")?;
    vt.feed_str(&String::from_utf8_lossy(&input));

    Ok(atoms::ok())
}

#[rustler::nif]
fn resize(resource: ResourceArc<VtResource>, cols: usize, rows: usize) -> NifResult<Atom> {
    let mut vt = convert_err(resource.vt.write(), "rw_lock")?;
    vt.resize(cols, rows);

    Ok(atoms::ok())
}

#[rustler::nif]
fn dump(resource: ResourceArc<VtResource>) -> NifResult<String> {
    let vt = convert_err(resource.vt.read(), "rw_lock")?;

    Ok(vt.dump())
}

#[rustler::nif]
fn dump_screen(env: Env, resource: ResourceArc<VtResource>) -> NifResult<(Atom, Term)> {
    let vt = convert_err(resource.vt.read(), "rw_lock")?;

    let lines = vt
        .view()
        .iter()
        .map(|line| line_to_terms(line, env))
        .collect::<Vec<_>>();

    let cursor: Option<(usize, usize)> = vt.cursor().into();

    Ok((atoms::ok(), (lines, cursor).encode(env)))
}

fn line_to_terms<'a>(line: &avt::Line, env: Env<'a>) -> Vec<Term<'a>> {
    line.chunks(|c1, c2| c1.pen() != c2.pen() || is_special_char(c1) || is_special_char(c2))
        .map(|cells| chunk_to_term(cells, env))
        .collect::<Vec<_>>()
}

fn is_special_char(cell: &avt::Cell) -> bool {
    let ch = &cell.char();

    cell.width() > 1
        || BOX_DRAWING_RANGE.contains(ch)
        || BRAILLE_PATTERNS_RANGE.contains(ch)
        || BLOCK_ELEMENTS_RANGE.contains(ch)
        || POWERLINE_TRIANGLES_RANGE.contains(ch)
}

#[rustler::nif]
fn text(resource: ResourceArc<VtResource>) -> NifResult<String> {
    let vt = convert_err(resource.vt.read(), "rw_lock")?;
    let mut text = vt.text();

    while !text.is_empty() && text[text.len() - 1].is_empty() {
        text.truncate(text.len() - 1);
    }

    for line in &mut text.iter_mut() {
        line.push('\n');
    }

    Ok(text.join(""))
}

fn chunk_to_term(cells: Vec<avt::Cell>, env: Env) -> Term {
    let txt: String = cells.iter().map(|c| c.char()).collect();
    let pen = cells[0].pen();
    let mut pairs: Vec<(String, Term)> = Vec::new();

    match pen.foreground() {
        Some(avt::Color::Indexed(c)) => {
            pairs.push(("fg".to_owned(), c.encode(env)));
        }

        Some(avt::Color::RGB(c)) => {
            let c = format!("#{:02x}{:02x}{:02x}", c.r, c.g, c.b);
            pairs.push(("fg".to_owned(), c.encode(env)));
        }

        None => (),
    }

    match pen.background() {
        Some(avt::Color::Indexed(c)) => {
            pairs.push(("bg".to_owned(), c.encode(env)));
        }

        Some(avt::Color::RGB(c)) => {
            let c = format!("#{:02x}{:02x}{:02x}", c.r, c.g, c.b);
            pairs.push(("bg".to_owned(), c.encode(env)));
        }

        None => (),
    }

    if pen.is_bold() {
        pairs.push(("bold".to_owned(), true.encode(env)));
    }

    if pen.is_faint() {
        pairs.push(("faint".to_owned(), true.encode(env)));
    }

    if pen.is_italic() {
        pairs.push(("italic".to_owned(), true.encode(env)));
    }

    if pen.is_underline() {
        pairs.push(("underline".to_owned(), true.encode(env)));
    }

    if pen.is_strikethrough() {
        pairs.push(("strikethrough".to_owned(), true.encode(env)));
    }

    if pen.is_blink() {
        pairs.push(("blink".to_owned(), true.encode(env)));
    }

    if pen.is_inverse() {
        pairs.push(("inverse".to_owned(), true.encode(env)));
    }

    let attrs = Term::map_from_pairs(env, &pairs).unwrap();

    (txt, attrs, cells[0].width()).encode(env)
}

fn convert_err<T, E>(result: Result<T, E>, error: &'static str) -> Result<T, Error> {
    match result {
        Ok(value) => Ok(value),
        Err(_) => Err(Error::RaiseAtom(error)),
    }
}

rustler::init!(
    "Elixir.Asciinema.Vt",
    [new, feed, resize, dump, dump_screen, text],
    load = load
);
