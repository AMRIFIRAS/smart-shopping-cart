# Smart Shopping Cart

**Smart Shopping Cart graduation project** — a Flutter and Dart application
exploring a connected grocery shopping experience.

**For academic reference only**

Demo website: [SmartCart](https://smartcart-grad-2026-9f27.web.app/)

## Project overview

SmartCart combines product discovery, QR product links, and a digital shopping
cart in a responsive interface with English and Arabic support. Firebase
Authentication supports optional user accounts, and Firebase Hosting serves
the web application. Guests can browse and complete simulated checkout.

## Current features

- **Product browsing and details:** categories, search, product photographs,
  demonstration prices, and nutrition information.
- **QR product links:** product URLs open the corresponding details page.
  Opening or scanning a link does not automatically add an item; shoppers
  choose **Add to cart**.
- **Digital shopping cart:** manage quantities, remove products, and review
  totals before checkout.
- **Firebase Authentication:** optional email/password registration, sign-in,
  sign-out, password reset, and profile display names when configured.
- **Profile settings and language selection:** English and Arabic, including
  right-to-left layouts.
- **Order history and simulated receipt:** demonstration checkout without
  payment processing. Order history is stored locally per user and does not
  synchronize across devices.
- **Firebase Hosting:** the demonstration website is available at the link above.

## Planned integrations

- **YOLO customer tracking:** planned computer vision research for the smart
  cart; not implemented as a connected feature in this prototype.
- **Raspberry Pi and camera integration:** planned hardware connection for
  product recognition and cart interaction.
- **Automatic scan-to-cart integration:** planned authenticated robot events
  that add recognized products to a paired shopping session.

The repository includes local robot interfaces, a simulator, and a proposed
integration contract. Physical hardware and a production robot backend are
not connected. See [Raspberry Pi integration](RASPBERRY_PI_INTEGRATION.md).

## Technology and structure

| Location | Purpose |
| --- | --- |
| `lib/` | Flutter application, Dart models, screens, services, and localization |
| `assets/` | Product photographs and bundled fonts |
| `web/` | Web entry point, manifest, and icons |
| `test/` | Existing application and integration-contract tests |
| `tool/` | Development utilities, QR tools, verification scripts, and simulator |
| `pubspec.yaml` / `pubspec.lock` | Dependency declarations and locked versions |
| `firebase.json` | Existing Firebase Hosting configuration |
| `firebase-config.example.json` | Empty configuration template |

The project uses Flutter, Dart, Firebase Core and Authentication, local
preferences, QR scanning, and PDF receipt/label utilities. The Dart SDK
constraint and exact dependency versions are recorded in `pubspec.yaml`
and `pubspec.lock`.

## Academic source copy

This repository contains a source snapshot. Local Firebase configuration,
environment files, credentials, logs, backups, build output, deployment caches,
and editor state are excluded. The configuration example contains no values.
Authentication configuration is supplied through Dart environment definitions;
without it, the application uses guest authentication mode.

The live demo has its own configuration. Publishing this repository does not
deploy the app or change Firebase Authentication or Hosting settings.
Some existing tools are intended for live verification and can modify test
accounts when deliberately executed; they are included as source references.

Product prices and nutrition are demonstration data. See
[image sources](IMAGE_SOURCES.md) for product image attribution. Existing font
license notices remain with the bundled fonts and apply to those assets only.
No open-source license is granted for this project.
