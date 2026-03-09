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

/// Lightweight wrapper around Keychain Services for storing small secrets.
///
/// This utility uses the *Generic Password* class (`kSecClassGenericPassword`) and
/// treats the `key` as the `kSecAttrAccount`.
///
/// - Important: Keychain items are intended for **small** pieces of data (tokens, keys, identifiers).
///   Do not store large blobs.
public enum KeychainService {
    
    /// Stores a value under the given key using the Generic Password class.
    ///
    /// If an item already exists for `key`, it is deleted before adding the new item.
    ///
    /// - Parameters:
    ///   - key: Logical identifier mapped to `kSecAttrAccount`.
    ///   - data: Raw bytes to persist.
    ///   - accessControlFlags: Optional `SecAccessControlCreateFlags` (e.g., `.biometryAny`, `.userPresence`).
    ///   - accessibility: Optional `kSecAttrAccessible*` value (default is chosen by the system if omitted).
    /// - Returns: The `OSStatus` result of `SecItemAdd`.
    @discardableResult
    public static func saveKey(
        key: String,
        data: Data,
        accessControlFlags: SecAccessControlCreateFlags? = nil,
        accessibility: CFString? = nil
    ) -> OSStatus {
        var attrs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        if let flags = accessControlFlags {
            var error: Unmanaged<CFError>?
            let acc = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                accessibility ?? kSecAttrAccessibleAfterFirstUnlock,
                flags,
                &error
            )
            if let acc = acc {
                attrs[kSecAttrAccessControl as String] = acc
            } else {
                let errMsg = (error?.takeRetainedValue()).map { String(describing: $0) } ?? "unknown"
                OTFLogger.logger().warning("Failed to create SecAccessControl: \(errMsg)")
            }
        } else if let accessibility = accessibility {
            attrs[kSecAttrAccessible as String] = accessibility
        }
        
        // Replace any existing item
        SecItemDelete(attrs as CFDictionary)
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            let msg = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
            OTFLogger.logger().warning("Keychain save failed (status: \(status) – \(msg))")
        }
        return status
    }
    
    /// Loads the value previously stored for `key`.
    ///
    /// - Parameter key: Logical identifier mapped to `kSecAttrAccount`.
    /// - Returns: The stored `Data` if found; otherwise `nil`.
    public static func loadKey(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return keyData
        } else {
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
            OTFLogger.logger().warning("Keychain load failed (status: \(status) – \(message))")
            return nil
        }
    }
    
    /// Deletes the item stored under `key`.
    ///
    /// - Parameter key: Logical identifier mapped to `kSecAttrAccount`.
    /// - Returns: The `OSStatus` result of `SecItemDelete`.
    @discardableResult
    public static func delete(key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            let msg = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
            OTFLogger.logger().warning("Keychain delete failed (status: \(status) – \(msg))")
        }
        return status
    }
}
