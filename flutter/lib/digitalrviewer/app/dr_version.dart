// The DigitalRViewer release version. Bump it for every release; the build workflows read
// it (see .github/workflows/digitalrviewer*.yml) to name the installers, and the in-app
// updater compares it with https://digitalrviewer.com/download/latest.json.
//
// Format: <upstream RustDesk version>.<our build>. The upstream part stays in Cargo.toml
// because peers compare that version during connections.
const String kDrVersion = '1.5.0.2';
