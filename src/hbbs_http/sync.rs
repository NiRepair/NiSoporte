#[cfg(not(target_os = "ios"))]
lazy_static::lazy_static! {
    static ref SENDER: hbb_common::tokio::sync::broadcast::Sender<Vec<i32>> =
        hbb_common::tokio::sync::broadcast::channel(16).0;
}

#[cfg(not(target_os = "ios"))]
pub fn signal_receiver() -> hbb_common::tokio::sync::broadcast::Receiver<Vec<i32>> {
    SENDER.subscribe()
}

#[cfg(not(target_os = "ios"))]
pub fn is_pro() -> bool {
    false
}
