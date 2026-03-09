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
import OSLog

/// Central logging entry point for apps and frameworks.
///
/// Usage:
/// ```swift
/// import OTFUtilities
///
/// // Zero-config: category = current filename
/// OTFLogger.logger().info("log it baby")
///
/// // Full Apple flexibility: privacy annotations, formatting, etc.
/// let email = "user@example.com"
/// OTFLogger.logger().warning("Login for \(email, privacy: .private(mask: .hash)) failed")
///
/// // (Optional) file-scoped constant if you log a lot in this file:
/// private let log = OTFLogger.logger()
/// log.debug("ready")
/// ```
///
/// Design notes:
/// - Thread-safe, cached `Logger` instances keyed by `(subsystem, category)`.
/// - Subsystem defaults to the main bundle identifier; can be overridden globally (useful in tests).
public enum OTFLogger {
    
    private static var cache: [String: Logger] = [:]
    private static let lock = NSLock()
    private static var globalSubsystem: String?
    
    /// Override the default subsystem (bundle identifier). Returns the previous value.
    /// Passing `nil` restores the bundle-based default.
    @discardableResult
    public static func setGlobalSubsystem(_ subsystem: String?) -> String? {
        lock.lock(); defer { lock.unlock() }
        let previous = globalSubsystem
        globalSubsystem = subsystem
        // subsystem change invalidates existing loggers
        cache.removeAll()
        return previous
    }
    
    /// Returns a `Logger` for the given category (or the caller's file name).
    ///
    /// - Parameters:
    ///   - file: Caller file (defaults to `#fileID`) used to derive the category when `category` is nil.
    ///   - subsystem: Optional explicit subsystem. Defaults to bundle identifier or "OTFUtilities".
    ///   - category: Optional explicit category. Defaults to a name derived from `file` (e.g., "MyFile").
    public static func logger(
        file: StaticString = #fileID,
        subsystem: String? = nil,
        category: String? = nil
    ) -> Logger {
        let resolvedCategory = category ?? deriveCategory(from: file)
        let resolvedSubsystem = subsystem ?? globalSubsystem ?? Bundle.main.bundleIdentifier ?? "OTFUtilities"
        let key = resolvedSubsystem + "::" + resolvedCategory
        
        lock.lock()
        if let existing = cache[key] {
            lock.unlock()
            return existing
        }
        let newLogger = Logger(subsystem: resolvedSubsystem, category: resolvedCategory)
        cache[key] = newLogger
        lock.unlock()
        return newLogger
    }
    
    /// Convenience that always uses an explicit category.
    public static func logger(category: String, subsystem: String? = nil) -> Logger {
        logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - Helpers
    
    /// "Module/Path/MyFile.swift" -> "MyFile"
    static func deriveCategory(from file: StaticString) -> String {
        let fileID = String(describing: file)
        let last = (fileID as NSString).lastPathComponent
        return last.hasSuffix(".swift") ? String(last.dropLast(6)) : last
    }
}
