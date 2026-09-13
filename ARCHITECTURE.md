# OpenAamps ⇄ pi-ammps — System Architecture & Build Specification

**Version:** 1.0
**Status:** Draft for AI coding agent handoff
**Owner:** Sharad Bhandari
**Target hardware:** Raspberry Pi 3B+ (server/speaker node), Android phone (client), any modern browser (web client / laptop)

---

## 0. How to use this document

This file is written to be handed directly to an AI coding agent (e.g. Claude Code) as the single source of truth for building the system. It is intentionally exhaustive. The agent should:

1. Read this entire document before writing any code.
2. Build in the **phase order** given in §14 (Roadmap) — do not jump ahead to Bluetooth or streaming integrations before the core pairing + playback loop works end-to-end on a local network.
3. Treat every "Acceptance Criteria" block as a literal checklist before marking a phase done.
4. Never silently change an API contract in §7 without updating this document in the same commit — the three codebases (Android, Pi server, Web) must never drift out of sync on the contract.
5. Flag — do not silently resolve — anything in §15 (Open Decisions) that blocks progress.

---

## 1. Vision, in one paragraph

Two cooperating pieces of software form one product. **pi-ammps** is the server/brain that runs on a Raspberry Pi 3B+: it owns the audio output (local speaker via 3.5mm/USB DAC, or Bluetooth A2DP sink), manages the play queue, talks to streaming backends, and exposes a control API plus a minimal built-in web UI. **OpenAamps** is the polished, full-featured Android client for that server — analogous to how ArchiveTune is a third-party client for YouTube Music, OpenAamps is a third-party client for pi-ammps. Critically, pi-ammps is *not* browser-only: OpenAamps talks to it over the same API the web UI uses, via a **pairing code** shown on the Pi's default browser app, so a phone can discover, pair with, and fully control a specific pi-ammps instance without ever opening a browser. A laptop can still use the plain web client. Playback can happen **on the phone itself** (local playback, no Pi involved), **on the Pi's speaker over the LAN** (no Bluetooth needed), or **on the Pi via Bluetooth** to an external speaker — Bluetooth is an optional, independently toggleable output path, never a required dependency for anything else in the system.

---

## 2. Naming & product identity

| Name | What it is |
|---|---|
| **pi-ammps** | The server application running on the Raspberry Pi 3B+. Long-form: "Pi Audio & Media Management Player System." Owns playback, queue, library, streaming-service connectors, Bluetooth management, and the pairing/auth system. Ships with a minimal built-in web UI (the "default browser app"). |
| **OpenAamps** | The Android client app. A first-class, feature-rich alternative front-end to pi-ammps' browser UI — plus a fully capable standalone music player when not paired to any Pi. |
| **pi-ammps Web** | The laptop/desktop experience — the same web UI pi-ammps serves natively, no separate build needed; it is just pi-ammps' HTTP frontend, reused. |

These three surfaces share **one backend contract** (§7). Nothing about the API should be Android-specific or browser-specific.

---

## 3. Non-negotiable design principles

1. **Bluetooth is optional and isolated.** Every core feature (browsing, search, queueing, playback control, downloads, sync) must work with Bluetooth permanently off. Bluetooth only affects *where the Pi's own audio output goes*. A Bluetooth failure must never crash, hang, or degrade any other subsystem — it is handled by a dedicated, supervised, restartable process (§10).
2. **Phone playback and Pi playback are independent.** The app must be a fully standalone music player (local files + streaming) even with no Pi ever configured. Pairing to a Pi *adds* the ability to redirect or mirror playback to the Pi; it never becomes a requirement.
3. **One real-time contract, three surfaces.** Android, Web, and any future client all speak the exact same REST + WebSocket contract defined in §7. No client-specific backend endpoints.
4. **Local-first pairing.** Pairing and control happen over the LAN (mDNS/Zeroconf discovery + short-lived pairing code), not through a mandatory cloud relay. A cloud relay for remote (off-LAN) control is an optional, clearly separated Phase 4 feature (§14), never a dependency of local control.
5. **Idempotent, resumable state.** The Pi is the single source of truth for "what is currently playing / queued." Clients are thin observers that reflect server state and send intents; they never assume optimistic state changes stick without server confirmation. This is what makes multi-client sync (phone + web + a second phone) correct by construction rather than by careful bug-fixing.
6. **Everything typed and schema-validated.** Every message crossing a process boundary (HTTP body, WebSocket event, SQLite row) is validated against a schema (JSON Schema / Pydantic on the server, Kotlin `@Serializable` data classes on Android, Zod on the web). This is the primary lever for the "zero bugs" goal — most real-world bugs in systems like this are malformed-message bugs, not logic bugs.
7. **Graceful degradation over hard failure.** No streaming backend, no network, no paired Pi, no Bluetooth adapter — each of these should degrade the app to "do what you still can," never crash it.

---

## 4. High-level architecture

```
┌─────────────────────────────┐        ┌───────────────────────────────┐
│         OpenAamps            │        │           Laptop / pi-ammps Web │
│   (Android, Kotlin/Compose)  │        │      (served by pi-ammps itself) │
│                               │        │                                 │
│  - Local player (ExoPlayer)  │        │  - Same REST+WS client, in TS   │
│  - Streaming connectors      │◄──────┐ │                                 │
│  - Downloads/offline store   │       │ └───────────────────────────────┘
│  - Pairing + discovery       │       │
└──────────────┬────────────────┘       │
               │ REST (HTTPS/LAN) + WS   │  REST + WS
               │                          │
               ▼                          ▼
        ┌───────────────────────────────────────┐
        │             pi-ammps SERVER             │
        │        (Raspberry Pi 3B+, Python)        │
        │                                           │
        │  API Gateway (FastAPI) ── Auth/Pairing     │
        │  Playback Engine (MPD or GStreamer)        │
        │  Queue & Library DB (SQLite)                │
        │  Streaming Connector Layer (Spotify/YT/local)│
        │  Bluetooth Manager (BlueZ via D-Bus)         │
        │  Download Manager                            │
        │  mDNS advertiser (Zeroconf)                   │
        └───────────────┬───────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
     ┌─────────────────┐   ┌──────────────────────┐
     │ Local audio out   │   │ Bluetooth A2DP sink   │
     │ (3.5mm / USB DAC) │   │ (toggle on/off)       │
     └─────────────────┘   └──────────────────────┘
```

### 4.1 Component summary

| Component | Runs on | Responsibility |
|---|---|---|
| **API Gateway** | Pi | FastAPI app exposing REST + WebSocket. All auth, pairing, request validation happen here. |
| **Playback Engine** | Pi | Owns the actual audio pipeline. Recommended: **MPD (Music Player Daemon)** as the playback core, controlled via `python-mpd2`, because it already solves gapless playback, crossfade, output routing (ALSA/Bluetooth/multi-output), and queue management reliably — reinventing this in raw GStreamer is unnecessary risk for a "zero bugs" goal. |
| **Streaming Connector Layer** | Pi (primary) + Android (local fallback) | Resolves a logical track request ("play this Spotify URI" / "play this YouTube Music video ID" / "play this local file") into a playable audio stream URL or file MPD can consume. See §8. |
| **Bluetooth Manager** | Pi | Owns `bluetoothctl`/BlueZ D-Bus interactions, exposes a simple on/off + pair/scan/connect API, runs as its own supervised subprocess (§10). |
| **Library/Queue DB** | Pi | SQLite (via SQLModel/SQLAlchemy). Source of truth for queue, playlists, cached metadata, pairing tokens. |
| **Download Manager** | Both Pi and Android | Each side can independently download tracks for offline use into its own local cache; not shared storage. |
| **mDNS Advertiser** | Pi | Advertises `_pi-ammps._tcp.local` so OpenAamps and the web client can discover the Pi on the LAN without typing an IP. |
| **OpenAamps app** | Android | Full player UI, local library, streaming search/playback, download manager, pairing/discovery UI, Bluetooth toggle control (remote, i.e. controlling the *Pi's* Bluetooth), settings. |
| **pi-ammps Web** | Any browser | Thin web client served directly by the API Gateway (static build), same feature set as OpenAamps minus device-local things like offline phone storage. |

---

## 5. Technology stack

### 5.1 Raspberry Pi server (pi-ammps)

| Concern | Choice | Why |
|---|---|---|
| Language | Python 3.11+ | Best library support for BlueZ D-Bus, MPD clients, and streaming-service SDKs on ARM; Pi 3B+'s quad-core Cortex-A53 handles it fine for an I/O-bound app. |
| Web framework | FastAPI + Uvicorn | Async, native WebSocket support, automatic OpenAPI schema (which becomes the literal contract in §7), Pydantic validation baked in. |
| Playback core | MPD (`mpd` daemon) + `python-mpd2` | Battle-tested gapless playback, ALSA + Bluetooth output switching, queue primitives, crossfade, replaygain — do not reimplement. |
| Database | SQLite + SQLModel | Zero-ops, file-based, fully sufficient for a single-Pi deployment; SQLModel gives Pydantic-compatible schema validation for free. |
| Bluetooth | BlueZ (system service) via `dbus-next` (async D-Bus) | The only correct way to drive Bluetooth on Linux without shelling out unreliably to `bluetoothctl` for everything; shell out only for the small number of operations D-Bus doesn't cover cleanly. |
| Process supervision | `systemd` unit files, one per component (API gateway, MPD, Bluetooth manager) | Auto-restart on crash, clean logs via `journalctl`, boot-time startup — critical for a headless "always on" device. |
| Streaming SDKs | `spotipy` (Spotify Web API) + a maintained YT-Music resolver (see §8.2) | See §8 for full detail and legal caveats. |
| mDNS | `zeroconf` (python-zeroconf) | Pure-Python, no extra system daemon required beyond Avahi already present on Raspberry Pi OS. |

### 5.2 Android app (OpenAamps)

| Concern | Choice | Why |
|---|---|---|
| Language / UI | Kotlin + Jetpack Compose | Matches the modern Android stack (same as the ArchiveTune reference project) — Material 3, good tooling, good long-term support. |
| Architecture pattern | MVVM + a single `PlaybackRepository` as source of truth | Keeps UI dumb and testable; mirrors the pattern used by mature FOSS players like ArchiveTune/Metrolist. |
| Local playback | Media3 `ExoPlayer` + `MediaSessionService` | Standard, handles background playback, lock-screen controls, Bluetooth *headphone* audio routing (distinct from the Pi's Bluetooth speaker routing) and Android Auto for free. |
| Networking | Ktor client (or Retrofit + OkHttp) for REST, OkHttp `WebSocket` for the real-time channel | Ktor keeps one HTTP stack shareable with Kotlin Multiplatform later if the team ever wants to share code with a desktop client. |
| Local DB | Room | Local library index, download records, cached pairing credentials. |
| Dependency injection | Hilt | Standard, testable. |
| Background downloads | `WorkManager` | Correct Android-blessed way to run resumable, battery-aware background downloads. |
| Discovery | `NsdManager` (Android's native mDNS/DNS-SD APIs) | Matches the Pi's Zeroconf advertisement in §5.1, no third-party discovery library needed. |

### 5.3 Web client (pi-ammps Web)

| Concern | Choice |
|---|---|
| Framework | SvelteKit or plain Vite + TypeScript (kept intentionally light — this is a control surface, not a marketing site) |
| State | A single WebSocket-driven store, mirroring the Android `PlaybackRepository` pattern |
| Build output | Static files served directly by FastAPI (`/`), so "the web app" *is* pi-ammps — no separate hosting needed |

---

## 6. The pairing & discovery model

This is the mechanism that lets OpenAamps (and the web client) control a *specific* pi-ammps instance without ever touching a browser on the Pi, and without any cloud account.

### 6.1 Flow

1. On first boot (or via a settings reset), pi-ammps generates a long-lived `device_id` (UUID) and a `device_secret`, stored in SQLite.
2. pi-ammps starts advertising itself on the LAN via mDNS as `_pi-ammps._tcp.local`, with TXT records `device_id`, `name`, `version`.
3. The Pi's built-in web UI (accessible at `http://<pi>.local:8420` — its "default browser app") shows a **6-digit pairing code**, freshly generated, valid for 5 minutes, single-use, displayed large on screen (this is the equivalent of a Chromecast/Spotify Connect-style pairing code — no typing of IPs or passwords).
4. In OpenAamps, the user taps "Add device." The app uses `NsdManager` to discover all `_pi-ammps._tcp` services on the LAN, lists them by `name`, and on selection prompts for the 6-digit code.
5. OpenAamps calls `POST /pair` with `{device_id, code}`. The server validates the code, and if valid, issues a long-lived **pairing token** (a signed JWT, or a random opaque token stored server-side — see §9 for the tradeoff) scoped to that specific phone install (`client_id` generated client-side and sent along).
6. From then on, every request from that OpenAamps install includes `Authorization: Bearer <token>`. The web client goes through the identical flow — the pairing code UI *is* the pi-ammps web UI, so pairing a laptop is just "open the page, you're already in" (i.e., the local web UI is implicitly trusted because reaching `:8420` on the LAN already required LAN access) — remote/cloud access, if built in Phase 4, would require the same token, obtained the same way, over a relay.
7. Un-pairing (from either side) revokes the token immediately and both client and server drop cached credentials.

### 6.2 Why a rotating short code, not a static PIN

A static PIN is a shared secret that leaks the moment someone glances at a sticky note; a rotating, time-boxed, single-use code minimizes the exposure window and matches user expectations from Chromecast, Spotify Connect, and smart-TV pairing flows — this also directly satisfies "there is no bluetooth issue" adjacent worry the user has about connection reliability: pairing never depends on Bluetooth at all, it is pure LAN/HTTP.

### 6.3 Acceptance criteria for this phase

- [ ] A fresh Pi with pi-ammps installed shows a pairing code within 5 seconds of the web UI loading.
- [ ] OpenAamps discovers the Pi on the same LAN within 10 seconds without any manual IP entry.
- [ ] A wrong code is rejected with a clear error and does not lock out the device.
- [ ] An expired code (>5 min) is rejected and the UI offers to regenerate.
- [ ] Un-pairing from the phone immediately makes old requests from that phone return `401`.
- [ ] Two different phones can be paired to the same Pi simultaneously, each with its own token.

---

## 7. API & real-time contract

This is the **single contract** all three surfaces implement. The agent should generate this as an OpenAPI 3.1 spec file (`contract/openapi.yaml`) and an AsyncAPI-style doc for the WebSocket events (`contract/ws-events.md`), and treat both as generated-from / checked-against in CI (e.g., Android uses `openapi-generator` or hand-written matching Kotlin serializable models validated by a contract test; the web client can use `openapi-typescript`).

### 7.1 REST endpoints (representative, not exhaustive — agent should flesh out CRUD fully)

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/pair` | Exchange a pairing code for a token (§6). |
| `DELETE` | `/pair/{client_id}` | Revoke a token / un-pair. |
| `GET` | `/devices/me` | Current device info, firmware/app version, capabilities. |
| `GET` | `/search?q=&source=` | Unified search across enabled sources (local, spotify, ytmusic). |
| `GET` | `/library/tracks`, `/library/albums`, `/library/artists`, `/library/playlists` | Browse the local + cached library. |
| `POST` | `/queue` | Add track(s) to the play queue (`position: "next" \| "end"`). |
| `GET` | `/queue` | Current queue snapshot. |
| `DELETE` | `/queue/{item_id}` | Remove a queued item. |
| `POST` | `/playback/play`, `/pause`, `/next`, `/previous`, `/seek`, `/volume` | Transport controls. |
| `GET` | `/playback/state` | Current playback snapshot (also pushed over WS — this is the pull/fallback path). |
| `POST` | `/playback/output` | Select output: `"local"` (Pi's own speaker) or `"bluetooth"`. |
| `GET`/`POST` | `/bluetooth/status`, `/bluetooth/enable`, `/bluetooth/disable`, `/bluetooth/scan`, `/bluetooth/pair` | Bluetooth control surface (§10). |
| `POST` | `/downloads` | Request a track be downloaded to the Pi's local cache. |
| `GET` | `/downloads/{id}` | Download progress/status. |
| `GET`/`POST` | `/settings/streaming/spotify`, `/settings/streaming/ytmusic` | Link/unlink streaming accounts (OAuth flow handoff — see §8). |

### 7.2 WebSocket channel (`/ws`)

A single persistent connection per authenticated client. Server → client events (push-based state sync, per Principle 5):

```jsonc
// playback_state_changed
{ "type": "playback_state_changed", "state": "playing", "track": {...}, "position_ms": 12345, "queue_version": 42 }

// queue_changed
{ "type": "queue_changed", "queue_version": 43, "queue": [...] }

// bluetooth_status_changed
{ "type": "bluetooth_status_changed", "enabled": true, "connected_device": {"name": "Living Room Speaker", "address": "..."} }

// download_progress
{ "type": "download_progress", "download_id": "...", "percent": 57 }

// device_paired / device_unpaired
{ "type": "device_paired", "client_id": "..." }
```

Client → server intents over the same socket are optional (REST is authoritative and sufficient); the WS channel should be treated as **read/subscribe only** to keep the "server is the single source of truth" principle simple and avoid race conditions between REST and WS write paths. All writes go through REST; all clients (including the one that issued the REST call) learn the *actual resulting state* only via the WS push, never by trusting their own optimistic guess. This single rule eliminates an entire category of multi-client sync bugs.

### 7.3 Versioning

Prefix every route with `/api/v1/`. Bump to `/v2/` on breaking change; never mutate `v1` semantics in place. The agent should treat this as a hard rule, not a suggestion — it's what lets the Android app and Pi server update independently without bricking each other.

---

## 8. Streaming integration layer

### 8.1 Design

A `StreamSource` abstraction, implemented once on the Pi (for Pi-side playback) and mirrored on Android (for phone-only playback with no Pi):

```
interface StreamSource {
  fun search(query: String): List<TrackResult>
  fun resolvePlayableUrl(trackRef: TrackRef): PlayableStream   // returns a direct/streamable URL or throws
  fun getMetadata(trackRef: TrackRef): TrackMetadata
}
```

Implementations: `LocalFileSource`, `SpotifySource`, `YtMusicSource`. The Playback Engine (MPD on the Pi, ExoPlayer on Android) never talks to a streaming SDK directly — it only ever receives a resolved, playable URL from this layer. This isolation is what makes it possible to add/remove a streaming backend without touching playback code at all.

### 8.2 Per-source detail and important legal caveat

- **Local files**: trivial — filesystem scan + tag reading (`mutagen` on Pi, Media3 `MediaMetadataRetriever`/tag libs on Android).
- **Spotify**: Use the **official Spotify Web API** (`spotipy` on the Pi, Spotify's Android SDK or a REST wrapper on the phone) with standard OAuth. **Important limitation to design around from day one:** the official Web API can control playback on a device running licensed Spotify software (Spotify Connect) and can *read* metadata/playlists, but it does **not** hand out raw audio stream URLs for third-party playback — that's by design and is not something to try to work around. Two honest options, and the agent should implement (A) as the default and leave (B) as an explicitly optional, clearly-labeled advanced feature:
  - **(A) Spotify Connect control mode**: pi-ammps registers itself as a Spotify Connect target (via `librespot`, an open-source Spotify Connect client) so that *within a Premium account*, "play on [Pi speaker name]" works exactly like casting to any other Spotify Connect device — this is fully within Spotify's supported integration surface and gets real audio playback, real Spotify catalog, zero legal ambiguity.
  - **(B) Playlist import only**: read-only import of a user's Spotify playlists/liked songs as a *track list* (titles/artists), which OpenAamps then resolves against another playable source (local files the user owns, or YouTube Music) — this is the same pattern ArchiveTune already documents ("Import playlist from Spotify") and does not touch Spotify audio at all.
- **YouTube Music**: There is no official public API for third-party audio playback of YouTube Music content. Projects like ArchiveTune (referenced by the user) implement this via YouTube's internal ("InnerTube") web API, the same technique used by yt-dlp and similar FOSS tools, without bypassing DRM (YouTube Music's regular streams are not DRM-protected). The agent should:
  - Build the resolver as its own swappable module (e.g., wrapping a maintained library such as `ytmusicapi` for search/metadata and a maintained extractor such as `yt-dlp` for the actual stream URL), so it can be updated in isolation when YouTube changes internals — this is exactly why the abstraction in §8.1 exists.
  - Cache resolved stream URLs briefly (they expire) and re-resolve on failure rather than treating a stale URL as a hard error.
  - Surface this source as a distinct, clearly-labeled "YouTube Music (unofficial)" entry in settings, off by default, so the user consciously opts in — matching the honest, low-drama framing ArchiveTune itself uses in its own legal disclaimer.
- **"Or forms new" (built-in library)**: pi-ammps' own local library + user-uploaded/downloaded files, is a first-class source, not a fallback — many users will run this as a pure local jukebox with zero streaming accounts linked.

### 8.3 Acceptance criteria

- [ ] Playback works with **zero** streaming accounts linked (local-only mode).
- [ ] Adding/removing a streaming source at runtime never requires an app restart on either Pi or phone.
- [ ] A resolver failure for one track (e.g., an expired YouTube URL) never stalls the rest of the queue — it's skipped with a visible, non-blocking error toast/notification and the next track plays.

---

## 9. Security model

| Concern | Approach |
|---|---|
| Transport | HTTPS with a self-signed cert generated on first boot (LAN use — no public CA needed) *or* plain HTTP restricted to LAN with a clear settings warning if the user tries to expose it publicly. Agent should default to the self-signed HTTPS path; it's barely more work and avoids ever having plaintext tokens on the wire even on a home network. |
| Auth token | Prefer an **opaque server-side token** (random 256-bit value, stored hashed in SQLite, looked up on each request) over a JWT — for a single-Pi, low-scale system, revocation-by-deletion is simpler and safer than JWT blacklist bookkeeping. Store the raw token only in the client's secure storage (`EncryptedSharedPreferences` / Android Keystore-backed on Android; `localStorage` is acceptable for the web client given it's a LAN control surface, not a bank). |
| Streaming OAuth secrets | Never embedded in the Android app or web client. All OAuth token exchange/refresh for Spotify happens server-side on the Pi; the phone only ever gets a deep link to the Pi's own `/settings/streaming/spotify/login` page (opened in a Custom Tab) and the Pi holds the resulting tokens. |
| Pairing code | Single-use, 5-minute TTL, rate-limited attempts (max 5 wrong guesses per code lifetime, then force regeneration) to prevent brute-forcing a 6-digit code on the LAN. |
| Input validation | Every endpoint validated against its Pydantic/Zod/Kotlin schema; reject unknown fields (strict mode) rather than silently ignoring them — this catches contract drift immediately in development instead of causing silent bugs in production. |

---

## 10. Bluetooth subsystem (the "ensure zero bluetooth issues" section)

This is called out as its own section because it is historically the single flakiest part of any Linux-Pi audio project, and the user explicitly wants it bulletproof.

### 10.1 Isolation strategy

Run Bluetooth management as its **own supervised process** (`pi-ammps-bluetooth.service`, separate `systemd` unit from the API gateway and from MPD). It communicates with the API Gateway over a small internal Unix-socket RPC, not in-process. Rationale: BlueZ's D-Bus interface can occasionally hang on `Connect()`/`Disconnect()` calls, especially on flaky hardware or with certain speaker firmware; isolating this in its own process with a hard timeout means a hung Bluetooth call **cannot** hang the API Gateway or interrupt local (non-Bluetooth) playback control.

### 10.2 State machine

```
DISABLED ──enable()──▶ ENABLED_IDLE ──scan()──▶ SCANNING ──found+pair()──▶ PAIRING ──success──▶ ENABLED_PAIRED
    ▲                        │                                                  │                     │
    └───────disable()────────┴──────────────────disable()───────────────────────┴───connect()────▶ CONNECTED
                                                                                                           │
                                                                                    disconnect()/lost ◀────┘
```

Every transition is logged, every transition has an explicit timeout (e.g., 15s for `Connect()`), and every timeout results in a clean fallback to the previous stable state plus a WS `bluetooth_status_changed` event — the UI must never show an indefinite spinner.

### 10.3 Toggle behavior (the literal "toggle button")

- `POST /bluetooth/enable` → powers on the adapter (`bluetoothctl power on` equivalent via D-Bus `Adapter1.Powered = true`), returns immediately with `enabling` status, final status pushed over WS.
- `POST /bluetooth/disable` → gracefully disconnects any connected A2DP sink *first* (so MPD's output falls back to local/ALSA automatically — see 10.4), then powers off the adapter. This ordering is important: powering off with an active audio connection can leave MPD's ALSA/Bluetooth output plugin in a broken state until restarted, which is exactly the "bluetooth issue" the user is worried about; doing the graceful disconnect first avoids that entirely.
- The toggle is a **single idempotent switch** in both OpenAamps and the web UI, backed by the real device state from `GET /bluetooth/status` / the WS event — never a client-local boolean that could drift from reality.

### 10.4 Output routing

MPD is configured with **two simultaneously-defined outputs**: an ALSA output (local 3.5mm/USB DAC, always enabled) and a Bluetooth/PulseAudio or PipeWire output (only enabled while a Bluetooth device is connected). `POST /playback/output {"target": "bluetooth"}` toggles which output(s) are enabled in MPD without stopping playback; if the Bluetooth output disappears unexpectedly (device walks out of range), the Bluetooth Manager detects the disconnect and the API Gateway **automatically** falls back to the local output and pushes a WS notification — the user is informed, not left in silence with no idea why.

### 10.5 Acceptance criteria

- [ ] Toggling Bluetooth off mid-playback via Bluetooth never stops music — it fails over to local output within 2 seconds.
- [ ] A failed pairing attempt returns a specific, human-readable error (`device_not_found`, `pairing_rejected`, `timeout`) rather than a generic 500.
- [ ] Killing/restarting the Bluetooth subprocess never crashes the API Gateway or interrupts local playback.
- [ ] Re-enabling Bluetooth after a disable reconnects to the last-used device automatically if it's in range (configurable).

---

## 11. Data model (SQLite, Pi side — abbreviated)

```
Device(id, name, created_at)
PairedClient(id, client_id, token_hash, platform, created_at, last_seen_at)
Track(id, source [local|spotify|ytmusic], source_ref, title, artist, album, duration_ms, artwork_url, local_path NULL)
Playlist(id, name, created_at)
PlaylistTrack(playlist_id, track_id, position)
QueueItem(id, track_id, position, added_by_client_id, added_at)
PlaybackState(singleton_row, track_id NULL, position_ms, status [playing|paused|stopped], output [local|bluetooth], updated_at)
Download(id, track_id, status [queued|downloading|done|failed], percent, local_path, updated_at)
StreamingAccount(id, provider [spotify|ytmusic], oauth_tokens_encrypted, linked_at)
BluetoothDevice(id, mac_address, name, last_connected_at, auto_reconnect BOOL)
```

Android (Room) mirrors `Track`, `Playlist`, `PlaylistTrack`, and adds its own `LocalDownload` table scoped to phone storage — it does **not** try to be a full mirror of the Pi's DB; it's a local library index for phone-only playback plus a cache of what's been fetched from the Pi.

---

## 12. Downloads & offline behavior

- Downloads are **per-device**, not shared. Downloading a track "to the Pi" and "to the phone" are two independent operations with two independent storage locations and two independent `Download` records — this avoids a whole class of "why is my phone storage full of Pi downloads" confusion.
- Android downloads use `WorkManager` with constraints (Wi-Fi-only toggle in settings, pause-on-low-battery) and resumable range requests.
- Pi downloads happen because the streaming resolver can then serve future plays of that track without re-resolving it against the network — this is primarily a reliability/latency optimization, not a bulk offline-storage feature (the Pi's SD card is small); the agent should implement an LRU eviction policy with a configurable cache size cap (default 2 GB) rather than unbounded growth.

---

## 13. Testing strategy — the path to "zero bugs"

No non-trivial system is literally bug-free, but the following practices are what actually move the needle, in priority order:

1. **Contract tests, not just unit tests.** Every REST endpoint and WS event gets a schema-validated contract test that runs against the real FastAPI app (via `httpx.AsyncClient` / `TestClient`) in CI. This catches the single biggest source of real bugs in a multi-client system: silent drift between what the server sends and what a client expects.
2. **State machine tests for Bluetooth (§10.2)** — every transition, every timeout path, every "device disappears mid-connection" scenario, using a mocked BlueZ D-Bus interface (do not require real Bluetooth hardware in CI).
3. **Playback engine integration tests** run against a real (headless, CI-friendly) MPD instance with dummy/null ALSA output — verifies queue transitions, gapless behavior, and output-switching logic against the real daemon rather than a mock, since MPD's actual behavior is the thing most likely to surprise you.
4. **Android UI tests** with Compose testing APIs for the critical flows: pairing, play/pause/skip, output toggle, Bluetooth toggle, offline playback with airplane mode on.
5. **Manual hardware-in-the-loop checklist** (the agent should generate this as a literal markdown checklist file, `TESTPLAN.md`) for things that cannot be meaningfully automated on real Pi 3B+ hardware with a real Bluetooth speaker: actual audio glitches, actual Bluetooth pairing UX with 2–3 real speaker models, actual Wi-Fi drop/reconnect behavior, actual SD-card-full behavior.
6. **Chaos-ish resilience checks**: kill each `systemd` service mid-operation (mid-download, mid-Bluetooth-connect, mid-playback) and confirm auto-restart + client-visible recovery, not silent inconsistent state.

"Zero bugs" is a direction, not a literal guarantee this document can promise — what this section guarantees instead is that the *categories* of bugs most likely to actually occur in this specific architecture (contract drift, Bluetooth flakiness, multi-client state races) are the ones most heavily tested.

---

## 14. Build roadmap (phase order the agent should follow)

**Phase 0 — Contract & scaffolding.** Write `contract/openapi.yaml` and `contract/ws-events.md` fully (even before implementing anything). Scaffold three repos/modules: `pi-ammps-server/`, `openaamps-android/`, `pi-ammps-web/`. Get CI running with contract tests against an empty-but-real FastAPI app.

**Phase 1 — Local-only core loop (no Pi, no streaming, no Bluetooth).** OpenAamps as a standalone local-file music player (ExoPlayer, Room-backed library, standard player UI). This alone should be a usable, shippable app.

**Phase 2 — pi-ammps server core.** FastAPI + MPD + SQLite on the Pi, local-file library only, REST + WS contract fully working, pairing flow (§6) fully working, pi-ammps Web able to browse/play local files on the Pi. OpenAamps gains "Add device," pairing UI, and remote playback control of the Pi's local library.

**Phase 3 — Bluetooth subsystem.** Implement §10 in full, including the isolated supervised process and the state machine, with its own test suite before moving on.

**Phase 4 — Streaming integrations.** Local-file `StreamSource` → Spotify Connect mode (librespot) → Spotify playlist-import mode → YouTube Music resolver, in that order, each fully working (including on the phone-standalone path, not just via the Pi) before starting the next.

**Phase 5 — Downloads/offline, on both Pi and phone.**

**Phase 6 (optional, explicitly separated per Principle 4) — Remote/cloud relay** for control outside the LAN, if wanted at all.

**Phase 7 — Polish pass**: onboarding flow, error-state UX audit (every failure mode in this document should have a corresponding, tested, human-readable UI state), release signing/build pipeline for the actual installable `.apk` (see §16), Pi installer script (`curl | bash`-style one-liner that sets up systemd units, MPD, and Avahi).

---

## 15. Open decisions the agent must flag back to the user, not silently resolve

- **Spotify strategy**: Connect-mode (librespot, requires Premium, real audio) vs. playlist-import-only (works on any account, no direct Spotify audio). The document recommends supporting both but building Connect-mode first — confirm this is the intended priority.
- **Public/remote access (Phase 6)**: is this wanted at all, and if so, self-hosted relay (e.g., a small WireGuard/Tailscale-based approach) vs. a hosted relay service — these have very different security and cost implications.
- **Multi-Pi support**: this document assumes one Pi per user for v1 (one OpenAamps install can be paired to multiple Pis and switch between them, but no "sync playback across two Pis simultaneously" feature) — confirm that's acceptable for v1.
- **Audio hardware on the Pi 3B+**: onboard 3.5mm jack (lower quality, known PWM whine on some Pi 3B+ units) vs. recommending a USB DAC or HAT (HiFiBerry/IQAudio) as the documented default — recommend documenting the USB DAC path as primary and onboard jack as a "works but not ideal" fallback.

---

## 16. From this document to an installed `.apk`

To be explicit about scope: this document is the architecture and contract the coding agent builds *from*. Producing an actual signed, installable `.apk` requires an Android build environment (Android Studio / Gradle, an Android SDK, and a signing keystore) actually compiling the `openaamps-android/` module — that's a build step the coding agent runs (e.g., `./gradlew assembleRelease` or `bundleRelease` for a Play-Store-ready AAB), not something produced by writing documentation. The agent should, as part of Phase 7, produce:
- A working `build.gradle.kts` release config,
- A CI job that produces a signed nightly `.apk` (mirroring how ArchiveTune ships nightly builds, referenced by the user as a UX/process model),
- A `RELEASE.md` documenting exactly how to generate the signing key and cut a release build locally.

---

## 17. Repository layout (recommended)

```
pi-ammps-and-openaamps/
├── contract/
│   ├── openapi.yaml
│   └── ws-events.md
├── pi-ammps-server/         # Python/FastAPI, runs on the Pi
│   ├── app/
│   │   ├── api/             # route handlers, one module per §7.1 group
│   │   ├── playback/        # MPD wrapper
│   │   ├── bluetooth/       # isolated subprocess + RPC client
│   │   ├── streaming/       # StreamSource implementations (§8)
│   │   ├── db/               # SQLModel models + migrations
│   │   └── main.py
│   ├── systemd/              # unit files for gateway, bluetooth, mpd
│   ├── install.sh             # one-line Pi installer
│   └── tests/
├── openaamps-android/         # Kotlin/Compose
│   ├── app/src/main/java/.../ (feature-module structure: player, library, pairing, bluetooth, downloads, streaming, settings)
│   └── app/src/test, androidTest/
├── pi-ammps-web/               # TS web client, built output served by the Pi
└── TESTPLAN.md                 # manual hardware-in-the-loop checklist (§13.5)
```

---

*End of specification. Hand this file, in full, to the coding agent as its first message/context, and proceed phase-by-phase per §14.*
