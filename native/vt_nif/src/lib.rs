#[macro_use]
extern crate rustler;

use rustler::resource::ResourceArc;
use rustler::{Encoder, Env, Error, Term};
use serde_rustler::to_term;
use std::sync::RwLock;
use vt::VT;

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
        atom invalid_size;
    }
}

pub struct MutableResource {
    data: RwLock<VT>,
}

rustler::rustler_export_nifs! {
    "Elixir.Asciinema.Vt",
    [
        ("new", 2, new),
        ("feed", 2, feed),
        ("dump_screen", 1, dump_screen)
    ],
    Some(on_load)
}

fn on_load(env: Env, _info: Term) -> bool {
    resource_struct_init!(MutableResource, env);

    true
}

fn new<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let w: usize = args[0].decode()?;
    let h: usize = args[1].decode()?;

    if w > 0 && h > 0 {
        let vt = VT::new(w, h);
        let resource = ResourceArc::new(MutableResource {
            data: RwLock::new(vt),
        });

        Ok((atoms::ok(), resource).encode(env))
    } else {
        Ok((atoms::error(), atoms::invalid_size()).encode(env))
    }
}

fn feed<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<MutableResource> = args[0].decode()?;
    let input: &str = args[1].decode()?;
    let mut vt = convert_err((*resource).data.write(), "rw_lock")?;
    vt.feed_str(input);

    Ok(atoms::ok().encode(env))
}

fn dump_screen<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<MutableResource> = args[0].decode()?;
    let vt = convert_err((*resource).data.read(), "rw_lock")?;
    let lines = vt.get_lines();
    let cursor = vt.cursor();
    let term = convert_err(to_term(env, (lines, cursor)), "to_term")?;

    Ok((atoms::ok(), term).encode(env))
}

fn convert_err<T, E>(result: Result<T, E>, error: &'static str) -> Result<T, Error> {
    match result {
        Ok(value) => Ok(value),
        Err(_) => return Err(Error::RaiseAtom(error)),
    }
}
