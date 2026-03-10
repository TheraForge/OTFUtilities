# OTFUtilities

Utilities for TheraForge ToolBox: a small cross-cut of helpers used by other frameworks and apps — notably a modern logging façade (`OTFLogger`), a set of file-system/Data conveniences, and thin wrappers around **SwiftSodium** for common crypto workflows.

> **Version**: 2.0.0  
> **Minimum Platforms**: iOS 16+, watchOS 9+

## Change Log

<details closed>
  <summary>Release 2.0.0</summary>

* **Platform Support**
  * Minimum iOS 16+ / watchOS 9+
  * **Note:** Sodium-backed crypto helpers are available on **iOS only**.
* **Logging**
  * New `OTFLogger` API (per-file categories; native `OSLog.Logger` under the hood)
  * Request/response helpers with duration; request body logged using `.private`
  * Dev-only crash breadcrumbs utility
  * Legacy `OTFError`, `OTFLog`, `OTFDebug`, `OTFFault` marked **deprecated** (still available)
* **Documentation & Tests**
  * Expanded `///` doc comments across modules
  * Added Swift Testing examples (logger, data/file, SwiftSodium)

</details>

<details closed>
  <summary>Release 1.0.2-beta</summary>

* **OSLog Update**
  * Improved logging of all events
* **Added Crash Logging**

</details>

<details closed>
  <summary>Release 1.0.1-beta</summary>

* **OSLog Update**
  * Updated `OSLog` to support iOS 14.0+
  * Added the watchOS target

</details>

---

## Table of Contents

- [What’s New in 2.0.0](#whats-new-in-200)
- [Requirements](#requirements)
- [Installation](#installation)
- [Logging](#logging)
  - [Quick Start](#quick-start)
  - [Privacy & Formatting](#privacy--formatting)
  - [Per-File Categories](#perfile-categories)
  - [Migrating from Legacy Functions](#migrating-from-legacy-functions)
  - [Network Request/Response Logging](#network-requestresponse-logging)
  - [Crash Breadcrumbs (Dev-only)](#crash-breadcrumbs-devonly)
- [Crypto (SwiftSodium) — iOS only](#crypto-swiftsodium--ios-only)
  - [Master / Storage Keys](#master--storage-keys)
  - [Hashing](#hashing)
  - [Key Encryption (Sealed Box)](#key-encryption-sealed-box)
  - [Secret Stream (Chunked Encryption)](#secret-stream-chunked-encryption)
  - [Hex Utilities](#hex-utilities)
- [Data & File Helpers](#data--file-helpers)
- [Unit Tests](#unit-tests)
- [License](#license)

---

## What’s New in 2.0.0

- **Modern logging API** via `OTFLogger` with per-file categories and native `OSLog.Logger`.
- **Deprecated legacy** shims (`OTFError`, `OTFLog`, `OTFDebug`, `OTFFault`) — still available.
- **Readable network logging** helpers for requests/responses (duration, status, headers; request body is private by default).
- **Crash breadcrumb utility** (development only).
- **Platform bump**: iOS 16+, watchOS 9+.
- **Docs & examples** refreshed, plus example tests using Apple’s Swift Testing.

---

## Requirements

- iOS 16+
- watchOS 9+
- Swift 5.9+ (or newer)

> **Platform note:** Sodium-backed crypto helpers and some related extensions are **iOS-only**.

---

# Installation

> **Package Manager**: CocoaPods only (v2.0.0)  
> **Minimum Platforms**: iOS 16+, watchOS 9+

## CocoaPods

1. Ensure CocoaPods is installed and up to date:
   ```bash
   sudo gem install cocoapods
   pod --version
   ```

2. Add **OTFUtilities** to your `Podfile`.

   **iOS-only example**
   ```ruby
   platform :ios, '16.0'

   target 'YourApp' do
     use_frameworks!
     pod 'OTFUtilities', '~> 2.0.0'
   end
   ```

   **iOS + watchOS example**
   ```ruby
   abstract_target 'YourApp' do
     pod 'OTFUtilities', '~> 2.0.0'

     target 'YourApp-iOS' do
       platform :ios, '16.0'
       use_frameworks!
     end

     target 'YourApp-watchOS' do
       platform :watchos, '9.0'
       use_frameworks!
     end
   end
   ```

3. Install the pod:
   ```bash
   pod repo update   # optional, but recommended
   pod install
   ```

4. Open the generated `.xcworkspace` and import the module where needed:
   ```swift
   import OTFUtilities
   ```

> **Note:** Swift Package Manager is **not supported** for this release.

---

## Logging

### Quick Start

```swift
import OTFUtilities

// The category is derived from the current file name.
let log = OTFLogger.logger()

log.debug("App bootstrapped")
log.info("User signed in")
log.warning("Cache miss for key: \(key, privacy: .public)")
log.error("Request failed: \(requestID, privacy: .public)")
log.critical("Unrecoverable state")
```

### Privacy & Formatting

You have full access to Apple’s `Logger` interpolation and privacy controls:

```swift
let email = "user@example.com"
let token = "abcd…"

let log = OTFLogger.logger()
log.notice("Login for \(email, privacy: .private(mask: .hash)) succeeded")
log.debug("Using token: \(token, privacy: .private)")
```

### Per-File Categories

`OTFLogger.logger()` categorizes logs by the **calling file** automatically (derived from `#fileID`). For files with heavy logging, define a scoped constant:

```swift
private let log = OTFLogger.logger()   // category == "MyFile"
```

Need an explicit category? Use:

```swift
let paymentsLog = OTFLogger.logger(category: "Payments")
```

### Migrating from Legacy Functions

The following legacy helpers still exist but are **deprecated**. Replace them with the shown equivalents:

| Legacy          | Replacement (OTFLogger)                     |
|-----------------|---------------------------------------------|
| `OTFError(...)` | `OTFLogger.logger().error("…")`             |
| `OTFLog(...)`   | `OTFLogger.logger().info("…")`              |
| `OTFDebug(...)` | `OTFLogger.logger().debug("…")`             |
| `OTFFault(...)` | `OTFLogger.logger().critical("…")`          |

### Network Request/Response Logging

Helpers to log a request and then the corresponding response including **duration**:

```swift
let req: URLRequest = …
logRequest(req)

URLSession.shared.dataTask(with: req) { data, resp, err in
    logResponse(req, response: resp, data: data, error: err)
}.resume()
```

- The request body (if any) is logged with **`.private`** privacy.
- Response duration is auto-computed between `logRequest` and `logResponse`.

### Crash Breadcrumbs (Dev-only)

Enable lightweight breadcrumbs for uncaught exceptions and common POSIX signals:

```swift
setupCrashLogging()
```

> **Warning**: These handlers are intended for **development** only. Use a proper crash reporter in production.

---

## Crypto (SwiftSodium) — iOS only

> The Sodium-backed crypto utilities are compiled on **iOS** only.

### Master / Storage Keys

```swift
let crypto = SwiftSodium()

// Master key from password + email
let masterKey = try crypto.generateMasterKey(password: "your-password",
                                             email: "user@example.com")

// Storage keys derived from master
let defaultStorageKey      = try crypto.defaultStorageKey(from: masterKey)
let confidentialStorageKey = try crypto.confidentialStorageKey(from: masterKey)

// Derive a sub-key (index defaults to 1)
let fileKey = try crypto.deriveKey(from: defaultStorageKey)
```

### Hashing

```swift
let dataBytes: Bytes = Array("document bytes".utf8)

// BLAKE2b keyed (32-byte)
let keyedHash = try crypto.genericHash(message: dataBytes, key: fileKey)

// BLAKE2b unkeyed (32-byte)
let unkeyedHash = try crypto.genericHash(message: dataBytes)
```

### Key Encryption (Sealed Box)

```swift
let box = crypto.sodium.box
let keyPair = box.keyPair()!

// Encrypt key bytes for recipient (anonymous sender)
let encrypted: Bytes = try crypto.encryptSealedBox(bytes: masterKey,
                                                   recipientPublicKey: keyPair.publicKey)

// Decrypt using recipient key pair
let decrypted: Bytes = try crypto.decryptSealedBox(bytes: encrypted,
                                                   recipientPublicKey: keyPair.publicKey,
                                                   recipientSecretKey: keyPair.secretKey)
```

### Secret Stream (Chunked Encryption)

```swift
// Create a push stream and encrypt a single chunk
let push = try crypto.makePushStream(secretKey: fileKey)
let cipherChunk: Bytes = try crypto.pushChunk(push, message: Array(fileData))

// Combine header + chunk for transport
let encryptedWithHeader: [UInt8] = [push.header(), cipherChunk].flatMap { $0 }

// Later, decrypt the chunk
let (header, encrypted) = encryptedWithHeader.splitFile()
let (plainChunk, tag) = try crypto.pullChunk(secretKey: fileKey,
                                             header: header,
                                             ciphertext: encrypted)
```

> **Security note**: Prefer **random nonces** unless you have a strong reason not to.

### Hex Utilities

```swift
// UInt8[] → hex
let hex = [0xDE, 0xAD, 0xBE, 0xEF].bytesToHex(spacing: ":")

// hex → Data (throws on invalid input)
let data = try crypto.hexStringToData("DEADBEEF")
```

---

## Data & File Helpers

```swift
// Write to Documents
let blob = Data("hello".utf8)
let url = try FileManager.writeToDocuments(filename: "hello.bin", data: blob)

// Read from Documents
let loaded = try FileManager.readFromDocuments(filename: "hello.bin")

// Delete from Documents
try FileManager.deleteFile(filename: "hello.bin")

// Check if a file exists
let exists = FileManager.fileExistsInDocuments(filename: "hello.bin")
```

> These helpers validate filenames and throw descriptive errors when something goes wrong.

---

## Unit Tests

The project includes example tests using Apple’s **Swift Testing** covering:
- Logger basics and caching behavior
- Data + FileManager helpers
- Sodium crypto flows (sealed box, secret stream, hashing, hex)

Run with Xcode’s Test action on a toolchain that supports Swift Testing.

---

## License

This project is made available under the terms of a modified BSD license. See the [LICENSE](LICENSE.md) file.
