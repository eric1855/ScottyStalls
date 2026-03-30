<div align="center">

# ScottyStalls

### The Yelp for Campus Restrooms

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![AWS](https://img.shields.io/badge/AWS_Lambda-FF9900?style=for-the-badge&logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-7EBC6F?style=for-the-badge&logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)

**Find, rate, and review every restroom on Carnegie Mellon's campus.**

Built for 7,000+ CMU students who deserve to know what they're walking into.

<a href="https://drive.google.com/file/d/1vnNqPjb15x5mxHe_59MipTUJfzSqPFer/view?usp=sharing">
<img src="https://img.shields.io/badge/🎬_Watch_Demo-4285F4?style=for-the-badge&logo=googledrive&logoColor=white"/>
</a>

[Features](#features) · [Architecture](#architecture) · [Run Locally](#getting-started)

</div>

---

## The Problem

You're between classes. You need a restroom. You walk into the nearest building, find the bathroom, and... it's awful. No soap, broken lock, mystery puddle on the floor.

**ScottyStalls fixes this.** Real reviews from real students. Star ratings for cleanliness, noise level, and overall quality. Interactive campus map with every restroom pinpointed by building and floor.

---

## Features

**Interactive Campus Map** — Zoomable OpenStreetMap with live GPS tracking, building highlights, and restroom markers with rating badges. Tap any building to drill into floor-by-floor views.

**Review System** — Rate restrooms on 3 axes (Cleanliness, Noise, Overall Quality) for both the general bathroom and sinks separately. Read what other students think before you commit.

**Multi-Floor Navigation** — Select building floors from a dropdown to find restrooms on any level. Each restroom shows its exact location on the floor plan.

**Authentication + Gamification** — Register with email + 2FA verification, or explore as a guest. Track your stats: PoopCounter (total reviews), PoopStreak (consecutive days), and PoopMap Distance (campus distance traveled).

**Offline Mode** — Download campus map tiles for offline navigation. Full tile caching means the app works in basements with zero signal.

**Search & Filter** — Search restrooms by building name. Find the closest one to your current location with real-time distance calculations.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Flutter App                │
│                                             │
│  ┌──────────┐  ┌───────────┐ ┌────────────┐ │
│  │   Auth   │  │ Restroom  │ │  Location  │ │
│  │ Provider │  │ Provider  │ │  Provider  │ │
│  └────┬─────┘  └─────┬─────┘ └──────┬─────┘ │
│       │              │              │       │
│  ┌────┴─────┐ ┌──────┴──────┐ ┌─────┴─────┐ │
│  │   Auth   │ │     API     │ │  Location │ │
│  │ Service  │ │   Service   │ │  Service  │ │
│  └────┬─────┘ └──────┬──────┘ └────┬──────┘ │
└───────┼──────────────┼─────────────┼────────┘
        │              │             │
   ┌────┴────┐   ┌─────┴─────┐  ┌────┴─────┐
   │   AWS   │   │    AWS    │  │ Device   │
   │ Lambda  │   │  Lambda   │  │   GPS    │
   │  Auth   │   │  REST API │  └──────────┘
   └─────────┘   └───────────┘
```

- **State Management:** Provider pattern with 3 dedicated providers
- **Backend:** Serverless AWS Lambda functions behind API Gateway
- **Auth:** Email + 2FA code verification, JWT tokens, guest mode fallback
- **Maps:** flutter_map with CartoDB tiles (no Google Maps API key required)
- **Storage:** SharedPreferences for device ID persistence, flutter_cache_manager for offline tiles

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter, Dart |
| State | Provider |
| Maps | flutter_map, OpenStreetMap (CartoDB tiles) |
| Backend | AWS Lambda, API Gateway |
| Auth | JWT + Email 2FA |
| Location | Geolocator, GPS |
| Offline | flutter_cache_manager, tile pre-download |

---

## Getting Started

```bash
# Clone
git clone https://github.com/eric1855/ScottyStalls.git
cd ScottyStalls

# Install dependencies
flutter pub get

# Run on iOS Simulator
open -a Simulator
flutter run

# Run on Android Emulator
flutter run

# Run tests
flutter test
```

**Requirements:** Flutter SDK 3.5+, Dart 3.5+

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── app.dart                 # MultiProvider + routing
    ├── config.dart              # API configuration
    ├── home_page.dart           # Map view + restroom discovery
    ├── login_page.dart          # Auth (guest/login/register)
    ├── verify_code_page.dart    # 2FA verification
    ├── review_page.dart         # Write reviews
    ├── reader_review_page.dart  # Browse reviews
    ├── building_map_page.dart   # Floor plan navigation
    ├── profile_page.dart        # User stats + gamification
    ├── models/                  # User, Restroom, Review
    ├── providers/               # Auth, Restroom, Location state
    └── services/                # API, Auth, Location backends
```
</div>
