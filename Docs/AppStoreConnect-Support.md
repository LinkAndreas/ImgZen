# Support the Developer — App Store Connect setup

ImgZen's Support the Developer feature is **optional support**. It never unlocks features; the app is fully usable
for free. This document lists what has to be configured in App Store Connect for the in-app code to work, and how to
test it.

Product identifiers are defined once in `ImgZen/Domain/Support/SupportProductID.swift`. Names and prices are **not**
in the code: the app shows the localized name and price StoreKit returns, so both can be changed in App Store
Connect at any time without an app update.

The feature is in the **⋯ (More) menu › Support the Developer**, next to Send Feedback.

## Prerequisites

1. **Agreements, Tax, and Banking** — the *Paid Apps* agreement must be active, otherwise StoreKit returns no
   products and the screen shows "Support options couldn't be loaded".
2. **In-App Purchase capability** — on by default for the `de.linkandreas.imgzen` app ID. No entitlement key is
   needed.

## Products

Create them in App Store Connect › ImgZen › Monetization.

### One-time support — type: Consumable

Consumables, so people can support more than once. They are not restorable, which is expected for tips (Restore
Purchases applies to subscriptions).

| Product ID                               | Reference name   | Proposed price | Display name (en / de)                         |
|------------------------------------------|------------------|----------------|------------------------------------------------|
| `de.linkandreas.imgzen.support.small`    | Small Support    | €2.99          | Small Support / Kleine Unterstützung           |
| `de.linkandreas.imgzen.support.medium`   | Support          | €5.99          | Support / Unterstützung                        |
| `de.linkandreas.imgzen.support.generous` | Generous Support | €9.99          | Generous Support / Großzügige Unterstützung    |

Suggested descriptions: "Buy the developer a coffee." / "Spendiere dem Entwickler einen Kaffee.", "Help keep ImgZen
growing." / "Hilf mit, dass ImgZen weiter wächst.", "A big thank you." / "Ein großes Dankeschön."

The app adds an emoji (☕ ❤️ ⭐ 🌱 🌳) itself, so leave it out of the display name.

### Recurring support — type: Auto-Renewable Subscription

Create one subscription group, **Support**, containing both subscriptions.

| Product ID                              | Reference name  | Duration | Proposed price | Group level |
|-----------------------------------------|-----------------|----------|----------------|-------------|
| `de.linkandreas.imgzen.support.yearly`  | Yearly Support  | 1 year   | €14.99         | 1           |
| `de.linkandreas.imgzen.support.monthly` | Monthly Support | 1 month  | €1.99          | 2           |

- Display names: Yearly Support / Jährliche Unterstützung, Monthly Support / Monatliche Unterstützung.
- No free trials or introductory offers — this is support, not access.
- Family Sharing: off.
- Localize the group display name: "Support ImgZen" / "ImgZen unterstützen".

### For every product

- **Localizations** — display name and description in English and German, the languages the app ships in. These
  are what the Support screen shows.
- **Price** — choose the price point in *Pricing*. The app uses `Product.displayPrice`, so the storefront's local
  currency is shown automatically.
- **Review screenshot** — a screenshot of the Support screen (⋯ › Support the Developer):
  [`Docs/Images/SupportReviewScreenshot.png`](Images/SupportReviewScreenshot.png).
- **Review notes**, e.g.: "Optional developer support. Purchases and subscriptions unlock no content or features;
  the entire app is free. Found under the ⋯ (More) button at the top of the main screen › Support the Developer."

The first in-app purchases and subscriptions must be submitted **together with an app version**: add them to the
version under *In-App Purchases and Subscriptions* before submitting it for review.

## App Review requirements covered by the app

- Localized price and billing period, taken from StoreKit, next to each option.
- A clear statement that subscriptions renew automatically, how to cancel, and that they unlock nothing (footer of
  the Recurring Support section).
- **Restore Purchases** button.
- Links to the **Terms of Use** and **Privacy Policy**, published in English and German at
  `https://imgzen.linkandreas.de/termsofuse/<language>/` and `…/privacy/<language>/` (the
  [ImgZen website](https://github.com/LinkAndreas/ImgZen-Website)). `SupportLinks` in
  `ImgZen/UI/Screens/Support/SupportLinks.swift` opens the page in the app's language, and English for any other.
  In App Store Connect, set:
  - App Information › **Privacy Policy URL**: `https://imgzen.linkandreas.de/privacy/en/` (English) and
    `https://imgzen.linkandreas.de/privacy/de/` (German).
  - App Information › **License Agreement** › custom EULA, or the app description: a link to
    `https://imgzen.linkandreas.de/termsofuse/en/`.
- Manage Subscription opens the system subscription management sheet.

## Testing

### Local (Xcode, no App Store Connect needed)

`Config/ImgZen.storekit` defines all five products, and the shared `ImgZen` scheme uses it (Edit Scheme › Run ›
Options › StoreKit Configuration). It only applies when Xcode runs the app — a build installed any other way talks to
the real App Store.

1. Run the app from Xcode on a simulator or device.
2. Open ⋯ › Support the Developer and buy something; the purchase sheet is Xcode's test store.
3. Use Debug › StoreKit › Manage Transactions to approve Ask to Buy purchases, refund, expire subscriptions, or
   simulate failures (Editor › Enable StoreKit Errors in the configuration file).

Things to check: loading, purchase, cancel, pending (Ask to Buy), failure, subscription renewal, restore, offline
launch ("Try Again").

`ImgZenTests/Domain/Services/SupportStoreTests.swift` covers the store's logic without StoreKit, using
`PreviewSupportService`.

### Sandbox

Create sandbox testers in App Store Connect › Users and Access › Sandbox, sign in on a device under Settings ›
App Store › Sandbox Account, and run a build without the StoreKit configuration file selected (or a TestFlight
build).

## Changing prices later

Change the price in App Store Connect › the product › Pricing. No code or app update is needed; the next launch
shows the new localized price. For subscriptions, follow Apple's price-increase rules (existing subscribers may need
to consent).
