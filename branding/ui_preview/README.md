# DigitalRViewer UI preview

Runs the screens in `flutter/lib/digitalrviewer/` (linked as `lib/dr`) in a browser with
sample data, so the design can be checked without building the full app.

```bash
flutter run -d web-server --web-port 8790      # then open http://localhost:8790
```

Pick a screen with `?screen=home|devices|settings|incoming` and the theme with `&dark=1`.
