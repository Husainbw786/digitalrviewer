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

## Artwork

`python3 branding/gen-icons.py` (needs Pillow) regenerates all icons:

- `res/*.png` and `res/mac-*`
- `flutter/macos/Runner/AppIcon.icns`
- `flutter/assets/icon.png` and `flutter/assets/logo.png`
- the placeholder SVGs

Until a real logo exists it draws a placeholder "DR" monogram. For the real logo:

1. Save it as `branding/logo-1024.png` (square, 1024×1024).
2. Rerun the script.
3. Replace `flutter/assets/icon.svg`, `res/logo.svg` and `res/scalable.svg` with SVG versions by hand.

`flutter/assets/*.png` is gitignored upstream, so add them with `git add -f`.

## Build

`.github/workflows/digitalrviewer.yml` builds the macOS dmgs (Intel + Apple Silicon).
It's derived from the `build-for-macOS` job in `flutter-build.yml`, and runs on manual
dispatch or on a `v*` tag. The dmgs go to a GitHub Release.

Upstream's own workflows are disabled on this fork in the Actions settings, not by editing their files.

## Syncing upstream

```bash
git fetch upstream
git checkout master && git merge --ff-only upstream/master && git push origin master
git checkout digitalrviewer && git merge master
```

Conflicts, if any, will be in the files listed above. After merging, also check:

- whether `flutter-build.yml`'s `build-for-macOS` job changed (port the change into `digitalrviewer.yml`);
- for new hardcoded "RustDesk" strings:

  ```bash
  git diff master@{1} master | grep '^+.*RustDesk'
  ```
