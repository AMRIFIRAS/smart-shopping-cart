# Raspberry Pi integration: product URL QR codes and paired carts

The public website is a Flutter shopping prototype. The physical Raspberry Pi,
FastAPI server and WebSocket backend are **not connected or deployed**. A local
simulator verifies the proposed contract without hardware or paid services.

## One product label, two behaviors

Each final QR encodes `https://smartcart-grad-2026-9f27.web.app/product/P001`
(P001-P005). This is the deployed canonical origin. Example origins and legacy
`SMARTCART:` strings must never be printed as final labels.

- iPhone normal Camera: Safari opens product details. Opening or refreshing a
  product URL never changes the cart. The shopper chooses Add to Cart.
- Future robot: decode the same URL, validate the HTTPS origin and exact product
  path, extract P001, and send the product ID with the robot's paired active cart.
  An accepted robot event adds one unit to that cart automatically.

The static product QR contains **no cart ID, user identity or pairing token**.
It can be reused for every shopper. Pairing happens separately for each trip.
The public website contains no QR displays or printable-label assets.

## Required message body

```json
{
  "cart_id": "active-cart-id",
  "product_id": "P001",
  "source": "raspberry-pi"
}
```

P001 = Almarai Full Fat Milk; P002 = Nadec Orange Juice; P003 = Berain Water;
P004 = Twix Chocolate; P005 = Doritos Chips. IDs are case-sensitive. Reject
missing/wrong-type fields, unknown IDs, unexpected source values, foreign URL
origins, credentials, query strings, fragments and partial product paths.

## Future pairing and transport workflow

1. The shopper starts a trip. FastAPI authenticates the Firebase user, or issues
   a signed guest session, and creates an unguessable active cart ID. It records
   the owner server-side. Registration remains optional.
2. The shopper requests a short-lived, single-use pairing code for that cart.
   The backend binds redemption to the authenticated owner/session and a
   provisioned robot identity. The prototype simulator takes trusted owner
   strings only; those strings are not a production authentication mechanism.
3. The robot redeems the code. The server atomically records one active cart per
   robot and one robot per cart. Pairing a new shopper revokes the previous
   association. Do not infer ownership from a client-supplied cart_id.
4. The robot scans a product URL, extracts the ID and POSTs the body above to a
   proposed `/api/robot/scans` endpoint over HTTPS. Authenticate the robot using
   a provisioned credential kept on the robot, never in Flutter browser assets.
5. The server verifies robot identity, active pairing, cart status and catalog
   membership before changing quantities. A mismatched/stale cart is rejected.
6. Apply the increment transactionally. Broadcast an authoritative cart snapshot
   only on the corresponding authenticated `wss://BACKEND/ws/carts/{cart_id}`
   subscription. Verify the subscriber owns that cart; guessing its ID grants
   no access. The client replaces its snapshot instead of re-adding echoed events.
7. Checkout closes the active session and unpairs the robot. A new trip receives
   a fresh cart ID and pairing. Delayed events for the old trip are rejected.

Suggested error responses: 400 invalid message/QR, 403 pairing or ownership
mismatch, 404 unknown product, 409 inactive cart or idempotency conflict.
These endpoints are a design contract, not live URLs.

## Duplicate handling

The Pi must debounce continuous frames: every sighting refreshes last-seen time,
and the label must be absent for at least two seconds before another scan.
That prevents one held label from repeatedly adding products.

Transport retries are a different problem. Generate an event UUID once per
accepted physical scan and send it as `Idempotency-Key` metadata (or a WebSocket
envelope field), preserving the exact three-field body above. Retry with the
same key after timeouts; a new deliberate scan uses a new key. Atomically store
and deduplicate robot/event IDs server-side. Reject reuse of a key with a
different product/cart. Reconnect with backoff, recover the latest snapshot,
and never reapply a local optimistic increment plus its server echo.

## Implemented local interfaces and simulator

- `ProductLinks`: generates canonical URLs and strictly parses trusted origins.
- `RobotScanMessage`: validates/serializes the exact request body.
- `RobotScanService`: send events with authenticated transport identity and an
  idempotency key; subscribe to cart updates with an owner identity.
- `CartPairingService`: pairing, unpairing and active-cart lookup.
- `SimulatedRobotBackend`: two or more isolated carts, pairing validation,
  closed-session rejection, filtered updates and retry deduplication.
- `RobotScanSimulator`: URL decoding and raw-frame cooldown before transport.

Run the offline demonstration:

```powershell
dart run tool/simulate_robot.dart
flutter test test/public_product_robot_test.dart
```

The simulator prints the exact JSON, adds milk only to Alice's simulated cart,
adds chips only to Bob's, suppresses a repeated frame, and rejects a cross-cart
message. It uses `simulation.invalid` without network access. Unit tests cover
wrong owners/subscribers, unknown and malformed inputs, stale pairings, cart
closure, idempotent retries and deliberate repeated scans.

Replace the simulated service with HTTPS/WebSocket adapters when a real backend
and robot are ready. The backend must verify real credentials; simulator checks
are not proof of production security. No hardware connectivity is claimed.

## Free-plan boundary

The current deployment is classic Firebase Hosting on Spark plus optional
email/password Firebase Authentication. It needs no Firestore, SMS, Functions,
App Hosting, Cloud Run or billing account. This proposed FastAPI backend is not
being provisioned. Stop for owner approval before any future hosting action
that could create charges.
