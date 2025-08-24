# Scotty Stalls

Scotty Stalls is a campus restroom finder built with Flutter. It provides a
Google-style map of Carnegie Mellon University, highlights buildings that have
restrooms, and lets users drill down into per-building floor plans. Each
bathroom can include a photo and description, and tapping it opens a review
page. Reviews can be read by anyone, but only signed-in users may contribute
their own.

### Key Features

* **Clean campus map** using CartoDB's `light_all` tiles for a familiar
  Google-like appearance.
* **Highlighted buildings** show where restrooms are available; tapping one
  opens a mini floor-plan map.
* **Per-floor layout maps** display bathroom locations and allow floor
  selection from a dropdown.
* **Offline support** through tile caching, enabling navigation without an
  internet connection.
* **Rich restroom pages** with images, descriptions, and star-rated reviews.
* **User profile stats** including PoopCounter, PoopStreak, and PoopMap distance.

## Development

This project started from Flutter's simple app state management sample. For
general Flutter guidance, see the [online documentation](https://docs.flutter.dev).

### Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application. The `assets/images` directory contains
[resolution-aware images](https://flutter.dev/to/resolution-aware-images).

### Localization

This project generates localized messages based on arb files found in the
`lib/src/localization` directory. To support additional languages, please visit
the tutorial on [Internationalizing Flutter apps](https://flutter.dev/to/internationalization).

### Testing

To run the test suite, ensure the Flutter SDK is installed and execute:

```bash
flutter test
```
