use std::collections::{BTreeMap, BTreeSet};
use std::ops::Range;
use std::sync::Mutex;

use avt::observer::Transcript;
use avt::{Line, Observation, Observer, Operation, ScreenKind, Terminal};
use indexmap::IndexSet;
use rustler::{Atom, Binary, Env, Error, NifResult, Resource, ResourceArc, Term};

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

struct Fts {
    terminal: Terminal,
    index: TextIndex,
}

struct TextIndex {
    transcript: Transcript,
    dirty_rows: BTreeSet<usize>,
    content: CappedString,
    alt_screen_lines: BTreeMap<usize, Vec<String>>,
    alt_screen_words: CappedIndexSet,
}

const MAX_TEXT_LEN: usize = (1024 * 1024) - 1; // PostgreSQL's default size limit for tsvector

impl Fts {
    fn feed(&mut self, input: Binary) {
        let text = String::from_utf8_lossy(&input);

        self.terminal.feed_with(text.as_ref(), &mut self.index);
        self.index.collect_alternate(&self.terminal);
    }

    fn resize(&mut self, cols: usize, rows: usize) {
        self.terminal.resize_with(cols, rows, &mut self.index);
    }

    fn dump(&mut self) -> String {
        self.index.finish(&self.terminal)
    }
}

impl TextIndex {
    fn new() -> Self {
        Self {
            transcript: Transcript::new(),
            dirty_rows: BTreeSet::new(),
            content: CappedString::new(MAX_TEXT_LEN),
            alt_screen_lines: BTreeMap::new(),
            alt_screen_words: CappedIndexSet::new(MAX_TEXT_LEN),
        }
    }

    fn collect_alternate(&mut self, terminal: &Terminal) {
        // Compare word edits once per output event. Dirty rows include changes
        // from any intervening resize events.
        let dirty_rows = std::mem::take(&mut self.dirty_rows);

        if terminal.active_screen_kind() == ScreenKind::Alternate {
            for line_no in dirty_rows {
                // get current words for the line
                let mut cur_words: Vec<_> =
                    split_words(&terminal.screen().line(line_no).unwrap().text()).collect();

                // get previous words for the line
                let old_words = self.alt_screen_lines.entry(line_no).or_default();

                // find common prefix length

                let prefix_len = old_words
                    .iter()
                    .zip(&cur_words)
                    .take_while(|(old, cur)| old == cur)
                    .count();

                // find common suffix length

                let suffix_len = old_words[prefix_len..]
                    .iter()
                    .rev()
                    .zip(cur_words[prefix_len..].iter().rev())
                    .take_while(|(old, cur)| old == cur)
                    .count();

                let old_suffix_start = old_words.len() - suffix_len;
                let cur_suffix_start = cur_words.len() - suffix_len;
                let old_middle = &old_words[prefix_len..old_suffix_start];
                let cur_middle = &mut cur_words[prefix_len..cur_suffix_start];

                for (old, cur) in old_middle.iter().zip(cur_middle.iter_mut()) {
                    if old.starts_with(cur.as_str()) || old.ends_with(cur.as_str()) {
                        // Keep the longer word when characters are removed at either end.
                        cur.clone_from(old);
                    } else if !cur.starts_with(old) && !cur.ends_with(old) {
                        // A different word replaces the old one; preserve both.
                        self.alt_screen_words.insert(old.clone());
                    }
                }

                // Save removed words; added words and unchanged ends are already in cur_words.
                self.alt_screen_words
                    .extend(old_middle.iter().skip(cur_middle.len()).cloned());

                *old_words = cur_words;
            }
        }
    }

    fn finish(&mut self, terminal: &Terminal) -> String {
        // Flush primary history and visible text, even when alternate is active.
        let lines = std::mem::take(&mut self.transcript).finish(terminal);

        self.content
            .extend(lines.iter().flat_map(|line| split_words(line)));

        // flush alternate screen buffer

        for words in std::mem::take(&mut self.alt_screen_lines).into_values() {
            self.alt_screen_words.extend(words);
        }

        self.content.extend(self.alt_screen_words.drain());

        self.content.take()
    }
}

impl Observer for TextIndex {
    type Output = ();

    fn before(&mut self, context: &mut Observation<'_>, operation: &Operation) {
        self.transcript.before(context, operation);
    }

    fn resized(&mut self, _: usize, rows: usize) {
        self.dirty_rows.retain(|row| *row < rows);
    }

    fn dirty(&mut self, rows: Range<usize>) {
        self.dirty_rows.extend(rows);
    }

    fn evicted(&mut self, context: &mut Observation<'_>, line: &Line) {
        self.transcript.evicted(context, line);
    }

    fn end(&mut self, context: &mut Observation<'_>) {
        let lines = self.transcript.end(context);

        self.content
            .extend(lines.iter().flat_map(|line| split_words(line)));
    }
}

fn split_words(line: &str) -> impl Iterator<Item = String> + '_ {
    line.split(|c: char| !c.is_alphanumeric())
        .filter(|s| s.len() > 1)
        .map(|s| s.chars().take(32).collect::<String>().to_lowercase())
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

    fn extend(&mut self, items: impl IntoIterator<Item = String>) {
        for item in items {
            self.insert(item);
        }
    }

    fn drain(&mut self) -> impl Iterator<Item = String> + '_ {
        self.inner.drain(..)
    }
}

pub struct FtsResource {
    fts: Mutex<Fts>,
}

impl Resource for FtsResource {}

fn load(env: Env, _term: Term) -> bool {
    env.register::<FtsResource>().is_ok()
}

#[rustler::nif]
fn new(cols: usize, rows: usize) -> NifResult<(Atom, ResourceArc<FtsResource>)> {
    if !valid_size(cols, rows) {
        return Err(Error::Term(Box::new(atoms::invalid_size())));
    }

    let terminal = Terminal::with_scrollback(cols, rows, Some(1000))
        .map_err(|_| Error::Term(Box::new(atoms::invalid_size())))?;

    let resource = ResourceArc::new(FtsResource {
        fts: Mutex::new(Fts {
            terminal,
            index: TextIndex::new(),
        }),
    });

    Ok((atoms::ok(), resource))
}

#[rustler::nif]
fn feed(resource: ResourceArc<FtsResource>, input: Binary) -> NifResult<Atom> {
    convert_err(resource.fts.lock(), "rw_lock")?.feed(input);

    Ok(atoms::ok())
}

#[rustler::nif]
fn resize(resource: ResourceArc<FtsResource>, cols: usize, rows: usize) -> NifResult<Atom> {
    if !valid_size(cols, rows) {
        return Err(Error::Term(Box::new(atoms::invalid_size())));
    }

    convert_err(resource.fts.lock(), "rw_lock")?.resize(cols, rows);

    Ok(atoms::ok())
}

#[rustler::nif]
fn dump(resource: ResourceArc<FtsResource>) -> NifResult<String> {
    Ok(convert_err(resource.fts.lock(), "rw_lock")?.dump())
}

fn convert_err<T, E>(result: Result<T, E>, error: &'static str) -> Result<T, Error> {
    match result {
        Ok(value) => Ok(value),
        Err(_) => Err(Error::RaiseAtom(error)),
    }
}

rustler::init!("Elixir.Asciinema.Fts", load = load);
