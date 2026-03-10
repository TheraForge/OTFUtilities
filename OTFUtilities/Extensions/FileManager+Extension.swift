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

extension FileManager {
    public enum FMError: Error, Equatable, LocalizedError {
        case documentsDirectoryUnavailable
        case fileNotFound(URL)
        case invalidFilename(String)
        
        public var errorDescription: String? {
            switch self {
            case .documentsDirectoryUnavailable:
                return String(localized: "Documents directory unavailable")
            case .fileNotFound(let url):
                return String(localized: "File not found at \(url.path)")
            case .invalidFilename(let name):
                return String(localized: "Invalid filename: \(name)")
            }
        }
    }
    
    /// Convenience access to the user's Documents directory URL.
    public static func documentsDirectoryURL() throws -> URL {
        guard let url = Self.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FMError.documentsDirectoryUnavailable
        }
        return url
    }
    
    /// Writes `data` to the Documents directory.
    /// - Parameters:
    ///   - filename: Basename only (no path components).
    ///   - data: Bytes to persist.
    ///   - options: Write options. Defaults to `[]`.
    /// - Returns: Destination URL on success.
    @discardableResult
    public static func writeToDocuments(
        filename: String,
        data: Data,
        options: Data.WritingOptions = []
    ) throws -> URL {
        guard !filename.isEmpty, filename.range(of: "/") == nil else {
            throw FMError.invalidFilename(filename)
        }
        let url = try documentsDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        do {
            try data.write(to: url, options: options)
            return url
        } catch {
            OTFLogger.logger(category: "FileManager").warning("Write failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Reads a file from Documents into memory.
    /// - Parameter filename: Basename to read.
    public static func readFromDocuments(filename: String) throws -> Data {
        guard !filename.isEmpty, filename.range(of: "/") == nil else {
            throw FMError.invalidFilename(filename)
        }
        let url = try documentsDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        do {
            return try Data(contentsOf: url)
        } catch {
            OTFLogger.logger(category: "FileManager").warning("Read failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Deletes a file from Documents.
    /// - Throws: `CocoaError(.fileNoSuchFile)` when the file doesn't exist (useful for precise test expectations).
    public static func deleteFile(filename: String) throws {
        guard !filename.isEmpty, filename.range(of: "/") == nil else {
            throw FMError.invalidFilename(filename)
        }
        let url = try documentsDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        if !Self.default.fileExists(atPath: url.path) {
            throw CocoaError(.fileNoSuchFile)
        }
        do {
            try Self.default.removeItem(at: url)
        } catch {
            OTFLogger.logger(category: "FileManager").warning("Delete failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Returns `true` if a file exists in Documents.
    public static func fileExistsInDocuments(filename: String) -> Bool {
        guard let base = try? documentsDirectoryURL(), !filename.isEmpty, filename.range(of: "/") == nil else {
            return false
        }
        let url = base.appendingPathComponent(filename, isDirectory: false)
        return Self.default.fileExists(atPath: url.path)
    }
    
    /// Writes a UTF-8 string to Documents.
    @discardableResult
    public static func writeStringToDocuments(_ string: String, filename: String) throws -> URL {
        try writeToDocuments(filename: filename, data: Data(string.utf8))
    }
}
