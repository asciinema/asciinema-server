use std::str;
use std::sync::RwLock;

use avt::parser::Parser;
use avt::terminal::Terminal;
use avt::util::TextUnwrapper;
use rustler::{Atom, Binary, Env, Error, NifResult, Resource, ResourceArc, Term};

mod atoms {
    rustler::atoms! {
        ok,
        error,
        invalid_size,
    }
}

struct Fts {
    parser: Parser,
    terminal: Terminal,
    unwrapper: TextUnwrapper,
    content: String,
}

const MAX_TEXT_LEN: usize = 1024 * 1024;

impl Fts {
    fn feed(&mut self, input: Binary) {
        let input = match str::from_utf8(&input) {
            Ok(s) => s,
            Err(_) => &String::from_utf8_lossy(&input),
        };

        input
            .chars()
            .filter_map(|ch| self.parser.feed(ch))
            .for_each(|op| self.terminal.execute(op));

        let words = self
            .terminal
            .gc()
            .filter_map(|line| self.unwrapper.push(&line))
            .flat_map(|line| split_words(&line));

        collect(words, &mut self.content);
    }

    fn resize(&mut self, cols: usize, rows: usize) {
        self.terminal.resize(cols, rows);
    }

    fn dump(&mut self) -> String {
        let mut unwrapper = std::mem::take(&mut self.unwrapper);

        let words = self
            .terminal
            .lines()
            .filter_map(|line| unwrapper.push(line))
            .flat_map(|line| split_words(&line));

        collect(words, &mut self.content);

        let words = unwrapper
            .flush()
            .into_iter()
            .flat_map(|line| split_words(&line));

        collect(words, &mut self.content);

        std::mem::take(&mut self.content)
    }
}

fn split_words(line: &str) -> Vec<String> {
    line.replace(|c: char| !c.is_alphanumeric(), " ")
        .split_whitespace()
        .filter(|s| s.len() > 1)
        .map(|s| s.chars().take(32).collect::<String>().to_lowercase())
        .collect()
}

fn collect<I: Iterator<Item = String>>(words: I, output: &mut String) {
    for word in words {
        if output.len() >= MAX_TEXT_LEN {
            break;
        }

        output.push_str(&word);
        output.push(' ');
    }
}

pub struct FtsResource {
    fts: RwLock<Fts>,
}

impl Resource for FtsResource {}

fn load(env: Env, _term: Term) -> bool {
    env.register::<FtsResource>().is_ok()
}

#[rustler::nif]
fn new(cols: usize, rows: usize) -> NifResult<(Atom, ResourceArc<FtsResource>)> {
    if cols > 0 && rows > 0 {
        let resource = ResourceArc::new(FtsResource {
            fts: RwLock::new(Fts {
                parser: Parser::new(),
                terminal: Terminal::new((cols, rows), Some(1000)),
                unwrapper: TextUnwrapper::new(),
                content: String::new(),
            }),
        });

        Ok((atoms::ok(), resource))
    } else {
        Err(Error::Term(Box::new(atoms::invalid_size())))
    }
}

#[rustler::nif]
fn feed(resource: ResourceArc<FtsResource>, input: Binary) -> NifResult<Atom> {
    convert_err(resource.fts.write(), "rw_lock")?.feed(input);

    Ok(atoms::ok())
}

#[rustler::nif]
fn resize(resource: ResourceArc<FtsResource>, cols: usize, rows: usize) -> NifResult<Atom> {
    convert_err(resource.fts.write(), "rw_lock")?.resize(cols, rows);

    Ok(atoms::ok())
}

#[rustler::nif]
fn dump(resource: ResourceArc<FtsResource>) -> NifResult<String> {
    Ok(convert_err(resource.fts.write(), "rw_lock")?.dump())
}

fn convert_err<T, E>(result: Result<T, E>, error: &'static str) -> Result<T, Error> {
    match result {
        Ok(value) => Ok(value),
        Err(_) => Err(Error::RaiseAtom(error)),
    }
}

rustler::init!("Elixir.Asciinema.Fts", load = load);
