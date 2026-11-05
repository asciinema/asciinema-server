use avt::Terminal;
use rustler::{Atom, Binary, Encoder, Env, Error, NifResult, Resource, ResourceArc, Term};
use std::str;
use std::sync::RwLock;

const MAX_TERM_COLS: usize = 720;
const MAX_TERM_ROWS: usize = 200;

fn valid_size(cols: usize, rows: usize) -> bool {
    (1..=MAX_TERM_COLS).contains(&cols) && (1..=MAX_TERM_ROWS).contains(&rows)
}

mod atoms {
    rustler::atoms! {
        ok,
        error,
        invalid_size,
    }
}

pub struct TerminalResource {
    terminal: RwLock<Terminal>,
}

impl Resource for TerminalResource {}

fn load(env: Env, _term: Term) -> bool {
    env.register::<TerminalResource>().is_ok()
}

#[rustler::nif]
fn new(
    cols: usize,
    rows: usize,
    scrollback_limit: Option<usize>,
) -> NifResult<(Atom, ResourceArc<TerminalResource>)> {
    if !valid_size(cols, rows) {
        return Err(Error::Term(Box::new(atoms::invalid_size())));
    }

    let terminal = Terminal::with_scrollback(cols, rows, scrollback_limit)
        .map_err(|_| Error::Term(Box::new(atoms::invalid_size())))?;

    let resource = ResourceArc::new(TerminalResource {
        terminal: RwLock::new(terminal),
    });

    Ok((atoms::ok(), resource))
}

#[rustler::nif]
fn feed(resource: ResourceArc<TerminalResource>, input: Binary) -> NifResult<Atom> {
    let mut terminal = convert_err(resource.terminal.write(), "rw_lock")?;

    match str::from_utf8(&input) {
        Ok(s) => {
            terminal.feed(s);
        }

        Err(_) => {
            terminal.feed(String::from_utf8_lossy(&input).as_ref());
        }
    };

    Ok(atoms::ok())
}

#[rustler::nif]
fn resize(resource: ResourceArc<TerminalResource>, cols: usize, rows: usize) -> NifResult<Atom> {
    if !valid_size(cols, rows) {
        return Err(Error::Term(Box::new(atoms::invalid_size())));
    }

    let mut terminal = convert_err(resource.terminal.write(), "rw_lock")?;
    terminal.resize(cols, rows);

    Ok(atoms::ok())
}

#[rustler::nif]
fn dump(resource: ResourceArc<TerminalResource>) -> NifResult<String> {
    let terminal = convert_err(resource.terminal.read(), "rw_lock")?;

    Ok(terminal.dump())
}

#[rustler::nif]
fn dump_screen(env: Env, resource: ResourceArc<TerminalResource>) -> NifResult<Term> {
    let terminal = convert_err(resource.terminal.read(), "rw_lock")?;

    let lines = terminal
        .screen()
        .visible_lines()
        .map(|line| line_to_terms(line, env))
        .collect::<Vec<_>>();

    let cursor = terminal.cursor().position();

    Ok((lines, cursor).encode(env))
}

fn line_to_terms<'a>(line: &avt::Line, env: Env<'a>) -> Vec<Term<'a>> {
    line.chunks(|c1, c2| c1.pen() != c2.pen() || c1.width() != c2.width())
        .map(|cells| chunk_to_term(cells, env))
        .collect::<Vec<_>>()
}

#[rustler::nif]
fn text(resource: ResourceArc<TerminalResource>) -> NifResult<String> {
    let terminal = convert_err(resource.terminal.read(), "rw_lock")?;
    let mut text = terminal.primary_screen().text();

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

rustler::init!("Elixir.Asciinema.Vt", load = load);
