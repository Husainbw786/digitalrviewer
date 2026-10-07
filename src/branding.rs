//! DigitalRViewer branding.
//!
//! Every value that makes this build "DigitalRViewer" instead of RustDesk lives here, so a
//! domain or key change is a one-file edit. `apply()` runs from `load_custom_client()`, the
//! same early hook RustDesk uses for its own custom clients, on every entry point (GUI,
//! service, Flutter FFI). Setting the app name there also rebrands translations, the URL
//! scheme (`digitalrviewer://`) and macOS launchd files, and disables RustDesk's update check.
//!
//! See `branding/README.md` for the static files (bundle name, icons, workflow) that must
//! match `APP_NAME`.

use hbb_common::config;

pub const APP_NAME: &str = "DigitalRViewer";

/// ID / rendezvous server (hbbs). Port 21116 is implied.
pub const ID_SERVER: &str = "163.128.34.42";
/// Relay server (hbbr).
pub const RELAY_SERVER: &str = "163.128.34.42:21117";
/// Accounts, address books and audit (rustdesk-api behind the console's HTTPS host).
pub const API_SERVER: &str = "https://rustdesk.163-128-34-42.sslip.io";
/// Public key of the hbbs/hbbr key pair (`/opt/rustdesk/data/id_ed25519.pub` on the server).
pub const KEY: &str = "ihG8O4mHHiAvvNjVbt02xFUm3umqBfgQFQlyIlyosLQ=";

pub fn apply() {
    *config::APP_NAME.write().unwrap() = APP_NAME.to_owned();

    // Override settings win over anything saved in the user's config and are shown as
    // locked in the UI, so clients can't be pointed at another server.
    let mut overwrite = config::OVERWRITE_SETTINGS.write().unwrap();
    overwrite.insert("custom-rendezvous-server".to_owned(), ID_SERVER.to_owned());
    overwrite.insert("relay-server".to_owned(), RELAY_SERVER.to_owned());
    overwrite.insert("api-server".to_owned(), API_SERVER.to_owned());
    overwrite.insert("key".to_owned(), KEY.to_owned());
    drop(overwrite);

    let mut builtin = config::BUILTIN_SETTINGS.write().unwrap();
    builtin.insert("hide-server-settings".to_owned(), "Y".to_owned());
    builtin.insert("hide-help-cards".to_owned(), "Y".to_owned());
}
