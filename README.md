# Taxed GmbH — iOS

The Taxed GmbH client portal for iPhone and iPad. It is the same portal as
[taxed.ch/client-portal](https://taxed.ch/client-portal), against the same
backend, and it does the same things: sign in, send a document, read what we
have prepared for you.

**Native SwiftUI, iOS 18+, Firebase Auth + Firestore.** No server lives in this
repository — see [Backend](#backend).

## Build

```bash
open TaxedGmbH_IOS.xcodeproj      # Xcode 26, resolve packages on first open
python3 tools/check-localization.py
```

The project uses a file-system-synchronized group, so a `.swift` file added
anywhere under `TaxedGmbH_IOS/` is compiled — there is no membership checkbox
to forget.

## What is here

```
TaxedGmbH_IOS/
  Backend/            the entire contract with taxed.ch — read this first
    PortalAPI.swift          the only place that builds a request to the server
    PortalSession.swift      who is signed in and what they may reach
    PortalDocumentsService   list, upload, download
    PortalModels.swift       wire types
    PortalError.swift        the server's error codes, one to one
  Views/
    Auth/               sign in, sign up, password reset
    Portal/             waiting-for-access, documents, upload
    Account/            preferences and links; writes nothing
    Shared/             buttons, fields, the one error banner
  Constants/            configuration, all of it checkable
tools/                  check-localization.py
```

## Backend

The contract is **`docs/SCHEMA.md` in the `taxed.ch` repository.** It is
maintained, it is verified against production, and it outranks anything written
here. Read it before changing anything under `Backend/`.

The short version:

| | |
|---|---|
| Auth | Firebase Auth, project `taxedgmbh`. Email and password. |
| Authorisation | The token's `hh` claim. Never a Firestore read. |
| Documents | Google Drive, reached through `https://taxed.ch/api/portal/*`. |
| Firestore | The **`(default)`** database, europe-west6. |
| Client writes | None. Every document row is written by the server. |

This repository contains **no** `firestore.rules`, `storage.rules`, `firebase.json`
or Cloud Functions, and must not acquire them. The `taxed.ch` repository is the
single owner of the Firebase posture; a second copy here drifted from production
and would have re-opened rules that were deliberately closed.

## Three rules worth knowing before you change anything

**Authorisation comes from claims, not from a document.** `getIDTokenResult()`
costs no round trip and cannot disagree with the security rules, which read the
same claims. `users/{uid}` can lag by up to an hour, and the rules win.

**Nothing signs a user out except an explicit sign-out or a revoked token.**
Deciding "you may not be here" is `RootView`'s job. A session object that signs
people out to enforce a decision destroys a valid login for every other screen.

**A signed-in account with no household is normal.** Signing up creates an
account, never an environment — the household is created when a person at the
firm approves the request. That is `PendingAccessView`, and it exists because an
empty document list reads as "my tax records are gone".

## Uploads, specifically

The device sends a **category** — `02_Income_Salary_And_Other` — and never a
folder id. The server resolves it against that household's own record. A folder
id accepted from a phone would let any session write anywhere in the company's
Shared Drive.

Bytes go straight from the device to Drive over a resumable session; they never
pass through the API. Telling the API what landed afterwards is a latency
optimisation, not the correctness path — if it fails, the server's sweep finds
the file within minutes. So a failure there is deliberately not reported to the
client as a failed upload.

## Localization

English, German, French, Italian, all complete. `tools/check-localization.py`
fails on a key used in code but missing from a language, a key in one language
but not another, an unused key, or format specifiers that differ between
languages. Run it before you commit.
