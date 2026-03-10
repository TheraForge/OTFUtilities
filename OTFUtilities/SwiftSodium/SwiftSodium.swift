/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.
 
 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import Foundation
#if os(iOS)
import Sodium

/// Thin convenience wrapper over a subset of `libsodium` (via the `Sodium` Swift module).
///
/// The API focuses on a few common workflows and favors Swift error handling over
/// crashes. Every operation that can fail now `throws` instead of force-unwrapping
/// optionals.
///
/// - Note: This is **not** a complete surface area of libsodium
public final class SwiftSodium {
    
    // MARK: Types
    
    /// Errors emitted by `SwiftSodium`.
    public enum SwiftSodiumError: LocalizedError, Equatable {
        case encryptionFailed(String)
        case decryptionFailed(String)
        case secretStreamInitFailed
        case invalidHexString
        case keyDerivationFailed
        case hashFailed
        
        public var errorDescription: String? {
            switch self {
            case .encryptionFailed(let ctx):
                return String(localized: "Encryption failed: \(ctx).")
            case .decryptionFailed(let ctx):
                return String(localized: "Decryption failed: \(ctx).")
            case .secretStreamInitFailed:
                return String(localized: "Failed to initialize SecretStream (XChaCha20-Poly1305).")
            case .invalidHexString:
                return String(localized: "Invalid hex string (must be even-length and contain only 0-9A-F).")
            case .keyDerivationFailed:
                return String(localized: "Key derivation failed.")
            case .hashFailed:
                return String(localized: "Hashing failed.")
            }
        }
    }
    
    // MARK: - Properties / Init
    
    /// Shared libsodium handle.
    public let sodium: Sodium
    
    /// Initializes a new wrapper.
    public init(sodium: Sodium = Sodium()) { self.sodium = sodium }
    
    // MARK: - Public‑Key authenticated encryption (box)
    
    /// Encrypt an entire payload using *public‑key authenticated encryption* (`box.seal`).
    ///
    /// - Parameters:
    ///   - data: Plaintext data to encrypt.
    ///   - senderSecretKey: The **sender's** secret key.
    ///   - recipientPublicKey: The **recipient's** public key.
    /// - Returns: Combined `nonce + ciphertext + MAC` as `Bytes`.
    /// - Throws: ``SwiftSodiumError/encryptionFailed(_:)`` on failure.
    ///
    /// ### Example
    /// ```swift
    /// let sender    = sodium.box.keyPair()!
    /// let recipient = sodium.box.keyPair()!
    /// let ciphertext = try crypto.encryptFile(data: data,
    ///                                         senderSecretKey: sender.secretKey,
    ///                                         recipientPublicKey: recipient.publicKey)
    /// ```
    public func encryptFile(data: Data,
                            senderSecretKey: Box.KeyPair.SecretKey,
                            recipientPublicKey: Box.KeyPair.PublicKey) throws -> Bytes {
        let message = Array(data)
        guard let encryptedFile: Bytes = sodium.box.seal(message: message,
                                                         recipientPublicKey: recipientPublicKey,
                                                         senderSecretKey: senderSecretKey) else {
            throw SwiftSodiumError.encryptionFailed("box.seal")
        }
        return encryptedFile
    }
    
    /// Decrypt a payload previously produced by ``encryptFile(data:senderSecretKey:recipientPublicKey:)``.
    ///
    /// - Parameters:
    ///   - data: `nonce + ciphertext + MAC`.
    ///   - senderPublicKey: The **sender's** public key.
    ///   - recipientSecretKey: The **recipient's** secret key.
    /// - Returns: Decrypted data.
    /// - Throws: ``SwiftSodiumError/decryptionFailed(_:)`` on failure.
    public func decryptFile(data: Bytes,
                            senderPublicKey: Box.KeyPair.PublicKey,
                            recipientSecretKey: Box.KeyPair.SecretKey) throws -> Data {
        guard let decryptedFile = sodium.box.open(nonceAndAuthenticatedCipherText: data,
                                                  senderPublicKey: senderPublicKey,
                                                  recipientSecretKey: recipientSecretKey) else {
            throw SwiftSodiumError.decryptionFailed("box.open (nonce+cipher+mac)")
        }
        return Data(decryptedFile)
    }
    
    // MARK: - SecretStream (XChaCha20-Poly1305) for chunked encryption
    
    /// Create a `SecretStream.XChaCha20Poly1305` *push* stream for chunked encryption.
    ///
    /// - Parameter secretKey: A 32‑byte secret stream key.
    /// - Returns: A configured push stream.
    /// - Throws: ``SwiftSodiumError/secretStreamInitFailed`` on failure.
    public func makePushStream(secretKey: Bytes) throws -> SecretStream.XChaCha20Poly1305.PushStream {
        guard let push = sodium.secretStream.xchacha20poly1305.initPush(secretKey: secretKey) else {
            throw SwiftSodiumError.secretStreamInitFailed
        }
        return push
    }
    
    /// Encrypt a single chunk with the given push stream.
    public func pushChunk(_ pushStream: SecretStream.XChaCha20Poly1305.PushStream,
                          message: Bytes,
                          tag: SecretStream.XChaCha20Poly1305.Tag = .MESSAGE) throws -> Bytes {
        guard let encrypted = pushStream.push(message: message, tag: tag) else {
            throw SwiftSodiumError.encryptionFailed("secretStream.push")
        }
        return encrypted
    }
    
    /// Decrypt a single `SecretStream` message.
    ///
    /// - Parameters:
    ///   - secretKey: 32‑byte stream secret key.
    ///   - header: Stream header obtained from `PushStream.header`.
    ///   - ciphertext: The encrypted chunk to pull.
    /// - Returns: `(plaintext, tag)` pair.
    public func pullChunk(secretKey: Bytes,
                          header: Bytes,
                          ciphertext: Bytes) throws -> (Bytes, SecretStream.XChaCha20Poly1305.Tag) {
        guard let pull = sodium.secretStream.xchacha20poly1305.initPull(secretKey: secretKey, header: header) else {
            throw SwiftSodiumError.secretStreamInitFailed
        }
        guard let out = pull.pull(cipherText: ciphertext) else {
            throw SwiftSodiumError.decryptionFailed("secretStream.pull")
        }
        return out
    }
    
    // MARK: - SecretBox (symmetric) helpers
    
    /// Encrypt bytes using `secretBox.seal` with a deterministic nonce derived from `email`.
    ///
    /// - Important: Deterministic nonces are **not** recommended for general use because
    ///   nonce reuse with the same key breaks security. Only use this when the plaintext
    ///   is fixed for a given (key,email) pair (e.g. encrypting a single fixed key blob).
    ///
    /// - Parameters:
    ///   - bytes: Plaintext.
    ///   - secretKey: 32‑byte key for `secretBox`.
    ///   - email: Input used to derive a `NonceBytes`‑sized nonce via `genericHash`.
    public func encryptSecretBox(bytes: Bytes,
                                 secretKey: Bytes,
                                 email: String) throws -> Bytes {
        guard let nonce = sodium.genericHash.hash(message: email.bytes,
                                                  outputLength: sodium.secretBox.NonceBytes) else {
            throw SwiftSodiumError.hashFailed
        }
        guard let encrypted = sodium.secretBox.seal(message: bytes, secretKey: secretKey, nonce: nonce) else {
            throw SwiftSodiumError.encryptionFailed("secretBox.seal")
        }
        return encrypted
    }
    
    /// Decrypt bytes produced by ``encryptSecretBox(bytes:secretKey:email:)``.
    public func decryptSecretBox(bytes: Bytes,
                                 secretKey: Bytes,
                                 email: String) throws -> Bytes {
        guard let nonce = sodium.genericHash.hash(message: email.bytes,
                                                  outputLength: sodium.secretBox.NonceBytes) else {
            throw SwiftSodiumError.hashFailed
        }
        guard let decrypted = sodium.secretBox.open(authenticatedCipherText: bytes, secretKey: secretKey, nonce: nonce) else {
            throw SwiftSodiumError.decryptionFailed("secretBox.open (with nonce)")
        }
        return decrypted
    }
    
    /// Encrypt data using a single symmetric key via `secretBox.seal` (prepends nonce).
    /// - Returns: `nonce + ciphertext + MAC` bytes.
    public func encryptSymmetric(data: Data, secretKey: Bytes) throws -> Bytes {
        let message = Array(data)
        guard let encrypted: Bytes = sodium.secretBox.seal(message: message, secretKey: secretKey) else {
            throw SwiftSodiumError.encryptionFailed("secretBox.seal (with random nonce)")
        }
        return encrypted
    }
    
    /// Decrypt data previously produced by ``encryptSymmetric(data:secretKey:)``.
    public func decryptSymmetric(ciphertext: Bytes, secretKey: Bytes) throws -> Data {
        guard let decrypted = sodium.secretBox.open(nonceAndAuthenticatedCipherText: ciphertext, secretKey: secretKey) else {
            throw SwiftSodiumError.decryptionFailed("secretBox.open (nonce+cipher+mac)")
        }
        return Data(decrypted)
    }
    
    // MARK: - Sealed box (anonymous sender)
    
    /// Encrypt bytes using `box.seal` with an anonymous sender (aka "sealed box").
    public func encryptSealedBox(bytes: Bytes, recipientPublicKey: Bytes) throws -> Bytes {
        guard let encrypted = sodium.box.seal(message: bytes, recipientPublicKey: recipientPublicKey) else {
            throw SwiftSodiumError.encryptionFailed("box.seal (sealed box)")
        }
        return encrypted
    }
    
    /// Decrypt bytes produced by ``encryptSealedBox(bytes:recipientPublicKey:)``.
    public func decryptSealedBox(bytes: Bytes,
                                 recipientPublicKey: Box.KeyPair.PublicKey,
                                 recipientSecretKey: Box.KeyPair.SecretKey) throws -> Bytes {
        guard let decrypted = sodium.box.open(anonymousCipherText: bytes,
                                              recipientPublicKey: recipientPublicKey,
                                              recipientSecretKey: recipientSecretKey) else {
            throw SwiftSodiumError.decryptionFailed("box.open (sealed box)")
        }
        return decrypted
    }
    
    // MARK: - Keychain helpers (thin wrappers around your KeychainService)
    
    /// Save raw key bytes into the Keychain under `keychainKey`.
    public func saveKey(_ key: Bytes, keychainKey: String) {
        let data = Data(key)
        _ = KeychainService.saveKey(key: keychainKey, data: data)
    }
    
    /// Load previously stored key bytes from the Keychain.
    public func loadKey(keychainKey: String) -> Data {
        if let receivedData = KeychainService.loadKey(key: keychainKey) {
            return receivedData
        }
        return Data()
    }
    
    /// Convenience presence check for a Keychain item.
    public func isKeyStored(keychainKey: String) -> Bool {
        KeychainService.loadKey(key: keychainKey) != nil
    }
    
    /// Store a plain UTF‑8 `String` into the Keychain under `keychainKey`.
    public func saveStringValue(_ value: String, keychainKey: String) {
        let data = Data(value.utf8)
        _ = KeychainService.saveKey(key: keychainKey, data: data)
    }
    
    // MARK: - Hex / byte utilities
    
    /// Convert a hex string (even length, case‑insensitive) into `Data`.
    public func hexStringToData(_ string: String) throws -> Data {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard string.count % 2 == 0 else { throw SwiftSodiumError.invalidHexString }
        var out = Data()
        out.reserveCapacity(string.count / 2)
        var idx = string.startIndex
        while idx < string.endIndex {
            let next = string.index(idx, offsetBy: 2)
            let pair = String(string[idx..<next])
            guard let byte = UInt8(pair, radix: 16) else { throw SwiftSodiumError.invalidHexString }
            out.append(byte)
            idx = next
        }
        return out
    }
    
    /// Copy bytes out of `NSData` into a fresh `Bytes` array.
    public func bytes(from data: NSData) -> Bytes { Array(data as Data) }
    
    // MARK: - Key derivation & hashing
    
    /// Derive a 32‑byte *master key* from password and email using `pwHash.hash` with
    /// interactive limits.
    public func generateMasterKey(password: String, email: String) throws -> Bytes {
        guard let salt = sodium.genericHash.hash(message: email.bytes,
                                                 outputLength: sodium.pwHash.SaltBytes) else {
            throw SwiftSodiumError.hashFailed
        }
        guard let key = sodium.pwHash.hash(outputLength: 32,
                                           passwd: password.bytes,
                                           salt: salt,
                                           opsLimit: sodium.pwHash.OpsLimitInteractive,
                                           memLimit: sodium.pwHash.MemLimitInteractive) else {
            throw SwiftSodiumError.keyDerivationFailed
        }
        return key
    }
    
    /// Derive a sub‑key from `key` using the provided `index` and context "user_key".
    public func deriveKey(from key: Bytes, index: UInt64 = 1) throws -> Bytes {
        guard let sub = sodium.keyDerivation.derive(secretKey: key,
                                                    index: index,
                                                    length: key.count,
                                                    context: "user_key") else {
            throw SwiftSodiumError.keyDerivationFailed
        }
        return sub
    }
    
    /// Compute a 32‑byte `genericHash` (BLAKE2b) keyed with `key`.
    public func genericHash(message: Bytes, key: Bytes) throws -> Bytes {
        guard let out = sodium.genericHash.hash(message: message, key: key, outputLength: 32) else {
            throw SwiftSodiumError.hashFailed
        }
        return out
    }
    
    /// Compute a 32‑byte `genericHash` (BLAKE2b) with **no** key.
    public func genericHash(message: Bytes) throws -> Bytes {
        guard let out = sodium.genericHash.hash(message: message, key: nil, outputLength: 32) else {
            throw SwiftSodiumError.hashFailed
        }
        return out
    }
    
    /// Derive a *default* storage key from a master key (index 1).
    public func defaultStorageKey(from masterKey: Bytes) throws -> Bytes {
        try deriveKey(from: masterKey, index: 1)
    }
    
    /// Derive a *confidential* storage key from a master key (index 2).
    public func confidentialStorageKey(from masterKey: Bytes) throws -> Bytes {
        try deriveKey(from: masterKey, index: 2)
    }
}
#endif
