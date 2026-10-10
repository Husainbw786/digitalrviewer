# DigitalRViewer branding checklist

Everything that turns RustDesk into DigitalRViewer. Use this list when merging upstream, swapping
the domain, or replacing the placeholder logo.

## Runtime (one file)

`src/branding.rs`: app name, ID/relay/API servers, public key, and the locked/hidden settings.
`apply()` is called at the top of `load_custom_client()` and `read_custom_client()` in
`src/common.rs`, and the module is declared in `src/lib.rs`.

Because the app name is set at runtime, RustDesk itself rebrands:

- translations: `src/lang.rs`, every "RustDesk" in all languages
- the URL scheme: `digitalrviewer://`
- macOS launchd plists and install scripts: `src/platform/macos.rs:correct_app_name`
- RustDesk's own update check, which is disabled for custom clients

**Changing the domain:** edit `API_SERVER` (and `ID_SERVER` / `RELAY_SERVER` if they move) in
`src/branding.rs`, rebuild, and ship the new dmg.

## Static macOS identity (must match `APP_NAME`)

| File | What |
|---|---|
| `flutter/macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, copyright |
| `flutter/macos/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (3 Runner configs), `DigitalRViewer.app` product ref |
| `flutter/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | `BuildableName` |
| `flutter/macos/Runner/Base.lproj/MainMenu.xib` | `customModule` |
| `flutter/macos/Runner/Info.plist` | URL scheme `digitalrviewer`, URL name |
| `build.py` (`build_flutter_dmg`) | copies `service` into `DigitalRViewer.app` |
| `Cargo.toml` | `description`, `[package.metadata.bundle]` |
| `flutter/lib/desktop/widgets/tabbar_widget.dart` | window title reads the app name |
| `src/auth_2fa.rs` | 2FA issuer shown in authenticator apps |

The internal crate and library names (`rustdesk`, `librustdesk`, `flutter_hbb`) and `ORG`
(`com.carriez`) are deliberately unchanged: users never see them, and renaming them would
conflict with almost every upstream merge.

## Static Windows identity

| File | What |
|---|---|
| `flutter/windows/runner/Runner.rc` | exe details: product name, description, company, copyright, original filename |
| `Cargo.toml`, `libs/portable/Cargo.toml` | `[package.metadata.winres]` for the Rust binary and the self-extracting exe |
| `.github/workflows/digitalrviewer-windows.yml` | renames `rustdesk.exe` to `DigitalRViewer.exe`; MSI `--app-name` / `-m` |

At runtime the app name sets the install folder (`C:\Program Files\DigitalRViewer`), the
Windows service, shortcuts, the Apps & features entry and the remote printer name.
`librustdesk.dll`, `drivers\RustDeskPrinterDriver` and the driver's own name are internal and stay.

## Artwork

`python3 branding/gen-icons.py` (needs Pillow) regenerates all icons:

- `res/*.png` and `res/mac-*`
- `flutter/macos/Runner/AppIcon.icns`
- `res/icon.ico`, `res/tray-icon.ico`, `flutter/windows/runner/resources/app_icon.ico`
- `flutter/assets/icon.png` and `flutter/assets/logo.png`
- the placeholder SVGs

Until a real logo exists it draws a placeholder "DR" monogram. For the real logo:

1. Save it as `branding/logo-1024.png` (square, 1024×1024).
2. Rerun the script.
3. Replace `flutter/assets/icon.svg`, `res/logo.svg` and `res/scalable.svg` with SVG versions by hand.

`flutter/assets/*.png` is gitignored upstream, so add them with `git add -f`.

## Build

`.github/workflows/digitalrviewer.yml` builds the macOS dmgs (Intel + Apple Silicon).
It's derived from the `build-for-macOS` job in `flutter-build.yml`.

`.github/workflows/digitalrviewer-windows.yml` builds the Windows x64 self-extracting exe and
MSI, derived from the `build-for-windows-flutter` job. Both run on manual dispatch or on a
`v*` tag and publish to a GitHub Release.

Upstream's own workflows are disabled on this fork in the Actions settings, not by editing their files.

## Syncing upstream

```bash
git fetch upstream
git checkout master && git merge --ff-only upstream/master && git push origin master
git checkout digitalrviewer && git merge master
```

Conflicts, if any, will be in the files listed above. After merging, also check:

- whether `flutter-build.yml`'s `build-for-macOS` or `build-for-windows-flutter` job changed
  (port the change into `digitalrviewer.yml` / `digitalrviewer-windows.yml`);
- for new hardcoded "RustDesk" strings:

  ```bash
  git diff master@{1} master | grep '^+.*RustDesk'
  ```

## Desktop UI (Digital R Viewer design)

The redesigned screens live in `flutter/lib/digitalrviewer/`:

| Path | What |
|---|---|
| `theme.dart` | Design tokens (colours, radii, type), light + dark, and `drThemeData()` |
| `widgets.dart` | Pill buttons, cards, toggles, segmented nav, chips, fields, notices |
| `screens/*.dart` | Home, Devices, Transfers, Settings shell, Incoming request: Flutter-only, take data + callbacks |
| `app/dr_main_window.dart` | Adapters that feed RustDesk's models into the screens; `kDrUi` master switch |
| `app/dr_cm.dart` | Incoming-request card for the connection-manager window |

Fonts (Albert Sans, Source Serif 4, SIL OFL) are in `flutter/assets/fonts/digitalrviewer/`.

Hooks in stock RustDesk files (each guarded by `kDrUi`, so `kDrUi = false` restores the stock UI):

| File | Hook |
|---|---|
| `flutter/lib/main.dart` | `theme`/`darkTheme` wrapped in `drAppTheme()` (2 places) |
| `flutter/lib/desktop/pages/desktop_tab_page.dart` | main window → `DrMainWindow`; `onAddSetting` → `drShowSettings` |
| `flutter/lib/desktop/pages/desktop_home_page.dart` | `build()` → `DrHomePane` (state, timers and multi-window handlers unchanged); help cards → `DrNotice` |
| `flutter/lib/desktop/pages/desktop_setting_page.dart` | `build()` → `DrSettingsShell` around the existing pages |
| `flutter/lib/desktop/pages/server_page.dart` | pending request → `DrCmRequestCard` (other CM states keep the stock panel) |
| `flutter/lib/common.dart` | `MyTheme.accent*` and `MyTheme.button` recoloured |

Preview the screens in a browser with sample data (no Rust/Xcode needed):

```bash
cd branding/ui_preview && flutter run -d web-server --web-port 8790
# http://localhost:8790/?screen=home|devices|transfers|settings|incoming|cm  (&dark=1)
```

## Releases and in-app updates

`flutter/lib/digitalrviewer/app/dr_version.dart` holds the release version (`kDrVersion`,
e.g. `1.5.0.2` = upstream 1.5.0, our build 2). The workflows read it to name the installers;
Cargo.toml's `1.5.0` stays because peers compare it during connections.

The app checks `https://digitalrviewer.com/download/latest.json` 8 s after start and every 4 h.
When a newer version exists the top bar shows **Update** → **Downloading n%** →
**Restart to update**. Downloads come from this repo's GitHub releases (allowed in
`src/updater.rs` via `branding::UPDATE_REPO`); installing reuses RustDesk's updater
(UAC prompt on Windows, administrator password on macOS).

To ship a release:

1. Bump `kDrVersion` and commit.
2. Run both workflows with the same tag, e.g. `-f tag=v1.5.0.2`.
3. On the server, run `/opt/rustdesk-admin/publish.sh v1.5.0.2`. Installed apps then offer the update,
   and the website's download buttons switch to the new files.
