use std::collections::HashMap;
use std::str;
use std::sync::RwLock;

use avt::parser::{DecMode, Function};
use avt::terminal::Terminal;
use avt::util::TextUnwrapper;
use avt::{parser::Parser, terminal::BufferType};
use indexmap::IndexSet;
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
    content: CappedString,
    alt_screen_lines: HashMap<usize, Vec<String>>,
    alt_screen_words: CappedIndexSet,
}

const MAX_TEXT_LEN: usize = (1024 * 1024) - 1; // PostgreSQL's default size limit for tsvector

impl Fts {
    fn feed(&mut self, input: Binary) {
        let input = match str::from_utf8(&input) {
            Ok(s) => s,
            Err(_) => &String::from_utf8_lossy(&input),
        };

        // process input

        for ch in input.chars() {
            if let Some(fun) = self.parser.feed(ch) {
                self.terminal.execute(fun);
            }
        }

        // collect scrollback of the primary screen buffer

        let words = self
            .terminal
            .gc()
            .filter_map(|line| self.unwrapper.push(&line))
            .flat_map(|line| split_words(&line));

        self.content.extend(words);

        // collect text of changed lines in the alternate screen buffer

        if self.terminal.active_buffer_type() == BufferType::Alternate {
            for line_no in self.terminal.changes() {
                // get current words for the line
                let cur_words = split_words(&self.terminal.line(line_no).text());

                // get previous words for the line
                let old_words = self
                    .alt_screen_lines
                    .entry(line_no)
                    .or_insert_with(|| cur_words.clone());

                // find common prefix length

                let mut old_iter = old_words.iter();
                let mut cur_iter = cur_words.iter();
                let mut old_word = old_iter.next();
                let mut cur_word = cur_iter.next();
                let mut prefix_len = 0;

                while let (Some(old), Some(cur)) = (old_word, cur_word) {
                    if old != cur {
                        break;
                    }

                    prefix_len += 1;
                    old_word = old_iter.next();
                    cur_word = cur_iter.next();
                }

                // find common suffix length

                let mut old_iter = old_words.iter().rev();
                let mut cur_iter = cur_words.iter().rev();
                let mut old_word = old_iter.next();
                let mut cur_word = cur_iter.next();
                let mut suffix_len = 0;

                while let (Some(old), Some(cur)) = (old_word, cur_word) {
                    if old != cur {
                        break;
                    }

                    suffix_len += 1;
                    old_word = old_iter.next();
                    cur_word = cur_iter.next();
                }

                // build new word list for the line

                // initialize with common prefix
                let mut new_words: Vec<String> = old_words[0..prefix_len].to_vec();

                let old_suffix_start = prefix_len.max(old_words.len() - suffix_len);
                let cur_suffix_start = prefix_len.max(cur_words.len() - suffix_len);
                let old_middle = &old_words[prefix_len..old_suffix_start];
                let cur_middle = &cur_words[prefix_len..cur_suffix_start];

                for (old, cur) in old_middle.iter().zip(cur_middle.iter()) {
                    let word = if cur.starts_with(old) {
                        // characters appended - replace
                        cur
                    } else if old.starts_with(cur) {
                        // characters removed on the right side - keep old
                        old
                    } else if cur.ends_with(old) {
                        // characters prepended - replace
                        cur
                    } else if old.ends_with(cur) {
                        // characters removed on the left side - keep old
                        old
                    } else {
                        // likely a different word - save old, replace with cur
                        self.alt_screen_words.insert(old.clone());
                        cur
                    };

                    new_words.push(word.clone());
                }

                if old_middle.len() > cur_middle.len() {
                    // save removed words
                    self.alt_screen_words
                        .extend(&old_middle[cur_middle.len()..]);
                } else if cur_middle.len() > old_middle.len() {
                    // append newly appeared words to the current line
                    new_words.extend_from_slice(&cur_middle[old_middle.len()..]);
                }

                // append common suffix
                new_words.extend_from_slice(&old_words[old_suffix_start..]);

                // replace words for the line
                self.alt_screen_lines.insert(line_no, new_words);
            }
        }
    }

    fn resize(&mut self, cols: usize, rows: usize) {
        self.terminal.resize(cols, rows);
    }

    fn dump(&mut self) -> String {
        // ensure primary screen buffer is active

        self.terminal
            .execute(Function::Decrst(vec![DecMode::AltScreenBuffer]));

        // flush primary screen buffer

        let mut unwrapper = std::mem::take(&mut self.unwrapper);

        let words = self
            .terminal
            .lines()
            .filter_map(|line| unwrapper.push(line))
            .flat_map(|line| split_words(&line));

        self.content.extend(words);

        let words = unwrapper
            .flush()
            .into_iter()
            .flat_map(|line| split_words(&line));

        self.content.extend(words);

        // flush alternate screen buffer

        let mut lines: Vec<(usize, Vec<String>)> = self.alt_screen_lines.drain().collect();
        lines.sort_by(|(n1, _), (n2, _)| n1.cmp(n2));

        for (_, words) in lines {
            self.alt_screen_words.extend(words);
        }

        self.content.extend(self.alt_screen_words.drain());

        self.content.take()
    }
}

fn split_words(line: &str) -> Vec<String> {
    line.replace(|c: char| !c.is_alphanumeric(), " ")
        .split_whitespace()
        .filter(|s| s.len() > 1)
        .map(|s| s.chars().take(32).collect::<String>().to_lowercase())
        .collect()
}

struct CappedString(String, usize);

impl CappedString {
    fn new(limit: usize) -> Self {
        CappedString(String::new(), limit)
    }

    fn extend<S: AsRef<str>, I: Iterator<Item = S>>(&mut self, items: I) {
        for item in items {
            if self.0.len() >= self.1 {
                return;
            }

            self.0.push_str(item.as_ref());
            self.0.push(' ');
        }
    }

    fn take(&mut self) -> String {
        std::mem::take(&mut self.0)
    }
}

struct CappedIndexSet {
    inner: IndexSet<String>,
    limit: usize,
    size: usize,
}

impl CappedIndexSet {
    fn new(limit: usize) -> Self {
        CappedIndexSet {
            inner: IndexSet::new(),
            limit,
            size: 0,
        }
    }

    fn insert(&mut self, item: String) {
        if self.size < self.limit {
            let len = item.len();

            if self.inner.insert(item) {
                self.size += len;
            }
        }
    }

    fn extend<S: ToString, I: IntoIterator<Item = S>>(&mut self, items: I) {
        for item in items.into_iter() {
            self.insert(item.to_string());
        }
    }

    fn drain(&mut self) -> impl Iterator<Item = String> + '_ {
        self.inner.drain(..)
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
                content: CappedString::new(MAX_TEXT_LEN),
                alt_screen_lines: HashMap::new(),
                alt_screen_words: CappedIndexSet::new(MAX_TEXT_LEN),
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
