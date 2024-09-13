#![allow(unused_imports)]
#![allow(unused_mut)]

use crate::tokio;
use prost::Message;
use rinf::{debug_print, DartSignal, RinfError};
use std::collections::HashMap;
use std::error::Error;
use std::sync::OnceLock;
use tokio::sync::mpsc::unbounded_channel;

type Handler = dyn Fn(&[u8], &[u8]) -> Result<(), RinfError> + Send + Sync;
type DartSignalHandlers = HashMap<i32, Box<Handler>>;
static DART_SIGNAL_HANDLERS: OnceLock<DartSignalHandlers> = OnceLock::new();

pub fn assign_dart_signal(
    message_id: i32,
    message_bytes: &[u8],
    binary: &[u8]
) -> Result<(), RinfError> {    
    let hash_map = DART_SIGNAL_HANDLERS.get_or_init(|| {
        let mut new_hash_map: DartSignalHandlers = HashMap::new();
new_hash_map.insert(
    0,
    Box::new(|message_bytes: &[u8], binary: &[u8]| {
        use super::basic::*;
        let message =
            SmallText::decode(message_bytes)
            .map_err(|_| RinfError::DecodeMessage)?;
        let dart_signal = DartSignal {
            message,
            binary: binary.to_vec(),
        };
        let mut guard = SMALL_TEXT_CHANNEL
            .lock()
            .map_err(|_| RinfError::LockMessageChannel)?;
        if guard.is_none() {
            let (sender, receiver) = unbounded_channel();
            guard.replace((sender, Some(receiver)));
        }
        let mut pair = guard
            .as_ref()
            .ok_or(RinfError::NoMessageChannel)?;
        // After Dart's hot restart or app reopen on mobile devices,
        // a sender from the previous run already exists
        // which is now closed.
        if pair.0.is_closed() {
            let (sender, receiver) = unbounded_channel();
            guard.replace((sender, Some(receiver)));
            pair = guard
                .as_ref()
                .ok_or(RinfError::NoMessageChannel)?;
        }
        let sender = &pair.0;
        let _ = sender.send(dart_signal);
        Ok(())
    }),
);
        new_hash_map
    });

    let signal_handler = match hash_map.get(&message_id) {
        Some(inner) => inner,
        None => return Err(RinfError::NoSignalHandler),
    };
    signal_handler(message_bytes, binary)
}
