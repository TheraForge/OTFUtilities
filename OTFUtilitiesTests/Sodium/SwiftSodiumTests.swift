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
import Testing
import OTFUtilities
import Sodium

@Suite("SwiftSodium Wrapper Tests")
struct SwiftSodiumTests {
    
    // MARK: - Helpers
    
    /// Loads `user.png` from the test bundle (SPM or Xcode) and returns its PNG-encoded data.
    /// This version does *not* depend on UIKit so it works on macOS and Linux.
    private func loadUserPNG() throws -> Data {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "user", withExtension: "png") {
            return try Data(contentsOf: url)
        }
        #else
        final class BundleToken {}
        let bundle = Bundle(for: BundleToken.self)
        if let url = bundle.url(forResource: "user", withExtension: "png") {
            return try Data(contentsOf: url)
        }
        #endif
        throw NSError(domain: "SwiftSodiumTests", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource user.png not found"])
    }
    
    // MARK: - Tests
    
    @Test("SecretStream: encrypt + decrypt a file round trip", .timeLimit(.minutes(1)))
    func encryptAndDecryptFile() throws {
        let swiftSodium = SwiftSodium()
        
        // Keys
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
        let fileKey = try swiftSodium.deriveKey(from: defaultStorageKey)
        
        // Payload (user.png)
        let data = try loadUserPNG()
        let originalFileBytes = swiftSodium.bytes(from: data as NSData)
        
        // Encrypt (stream)
        let pushStream = try swiftSodium.makePushStream(secretKey: fileKey)
        let fileCipher = try swiftSodium.pushChunk(pushStream, message: originalFileBytes)
        
        // Decrypt (use the header and ciphertext directly)
        let (decrypted, _) = try swiftSodium.pullChunk(secretKey: fileKey, header: pushStream.header(), ciphertext: fileCipher)
        
        // Assert
        #expect(decrypted == originalFileBytes)
    }
    
    @Test("Sealed box: encrypt/decrypt keypair")
    func encryptAndDecryptKey() throws {
        let swiftSodium = SwiftSodium()
        
        // Derive deterministic seed → keypair
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey)!
        
        // Encrypt
        let encryptedKey: Bytes = try swiftSodium.encryptSealedBox(bytes: masterKey, recipientPublicKey: keyPair.publicKey)
        let encryptedKeyHex = encryptedKey.bytesToHex(spacing: "").lowercased()
        
        // Convert hex → bytes again (exercise helpers)
        let hexToData = try swiftSodium.hexStringToData(encryptedKeyHex)
        let dataToBytes = swiftSodium.bytes(from: hexToData as NSData)
        
        // Decrypt
        let decryptedKey: Bytes = try swiftSodium.decryptSealedBox(bytes: dataToBytes,
                                                                   recipientPublicKey: keyPair.publicKey,
                                                                   recipientSecretKey: keyPair.secretKey)
        #expect(decryptedKey == masterKey)
    }
    
    @Test("Master key generation")
    func masterKeyGeneration() throws {
        let swiftSodium = SwiftSodium()
        let key = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        #expect(key.count == 32) // as implemented
    }
    
    @Test("Generate keypair from master key (seed)")
    func generateKeypairFromMasterKey() throws {
        let swiftSodium = SwiftSodium()
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let pair = swiftSodium.sodium.box.keyPair(seed: masterKey)
        #expect(pair != nil)
    }
    
    @Test("Derived key generation")
    func derivedKeyGeneration() throws {
        let swiftSodium = SwiftSodium()
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
        let fileKey = try swiftSodium.deriveKey(from: defaultStorageKey)
        #expect(fileKey.count == defaultStorageKey.count)
    }
    
    @Test("genericHash with key")
    func generateFileHashKey() throws {
        let swiftSodium = SwiftSodium()
        let message = "Hello World!"
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
        let fileKey = try swiftSodium.deriveKey(from: defaultStorageKey)
        let fileHashKey = try swiftSodium.genericHash(message: message.bytes, key: fileKey)
        #expect(fileHashKey.count == 32)
    }
    
    @Test("genericHash without key")
    func generateFileHashKeyWithoutKey() throws {
        let swiftSodium = SwiftSodium()
        let message = "Hello World!"
        let fileHashKey = try swiftSodium.genericHash(message: message.bytes)
        #expect(fileHashKey.count == 32)
    }
    
    @Test("XChaCha20-Poly1305 stream encrypt/decrypt a small message")
    func xchacha20poly1305EncryptionDecryption() throws {
        let swiftSodium = SwiftSodium()
        let message = "Hello World!"
        
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
        let fileKey = try swiftSodium.deriveKey(from: defaultStorageKey)
        
        let pushStream = try swiftSodium.makePushStream(secretKey: fileKey)
        let cipher = try swiftSodium.pushChunk(pushStream, message: message.bytes)
        let (plain, _) = try swiftSodium.pullChunk(secretKey: fileKey, header: pushStream.header(), ciphertext: cipher)
        
        #expect(plain.utf8String == message)
    }
    
    @Test("Default storage key derivation")
    func generateDefaultStorageKey() throws {
        let swiftSodium = SwiftSodium()
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = try swiftSodium.defaultStorageKey(from: masterKey)
        #expect(defaultStorageKey.count == masterKey.count)
    }
    
    @Test("Confidential storage key derivation")
    func generateConfidentialStorageKey() throws {
        let swiftSodium = SwiftSodium()
        let masterKey = try swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let confidential = try swiftSodium.confidentialStorageKey(from: masterKey)
        #expect(confidential.count == masterKey.count)
    }
    
    @Test("bytes ↔︎ hex round trip")
    func bytesToHexRoundTrip() throws {
        let swiftSodium = SwiftSodium()
        let bytes: [UInt8] = [48, 49, 48, 50, 48, 51, 48, 52, 48, 53] // "0102030405"
        let hex = bytes.bytesToHex(spacing: "").lowercased()
        let data = try swiftSodium.hexStringToData(hex)
        let roundTrip = swiftSodium.bytes(from: data as NSData)
        #expect(roundTrip == bytes)
    }
}
