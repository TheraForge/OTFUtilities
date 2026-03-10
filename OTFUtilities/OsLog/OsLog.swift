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
import os.log

/// Legacy convenience functions and helpers around the unified logging system.
///
/// - Important: These shims are deprecated. Prefer the modern ``OTFLogger`` API,
///   which returns a type-safe `Logger` instance scoped to the calling file.
///   Example:
///   ```swift
///   OTFLogger.logger().info("Hello")
///   OTFLogger.logger().error("Something failed: \(error.localizedDescription)")
///   ```

/// Error-level messages are intended for reporting critical errors and failures.
@available(*, deprecated, message: "Use OTFLogger.logger().error(\"…\"). (Note: legacy format arguments are supported best-effort; privacy annotations are not.)")
public func OTFError(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    logger(.error, message, args, category: category)
}

/// General informational messages that may be helpful, but aren’t essential, for troubleshooting.
@available(*, deprecated, message: "Use OTFLogger.logger().info(\"…\"). (Note: legacy format arguments are supported best-effort; privacy annotations are not.)")
public func OTFLog(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    logger(.info, message, args, category: category)
}

/// Debug-level messages are intended for verbose output during development.
@available(*, deprecated, message: "Use OTFLogger.logger().debug(\"…\"). (Note: legacy format arguments are supported best-effort; privacy annotations are not.)")
public func OTFDebug(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    logger(.debug, message, args, category: category)
}

/// Fault-level messages are intended for capturing system-level or multi-process errors only.
@available(*, deprecated, message: "Use OTFLogger.logger().critical(\"…\"). (Note: legacy format arguments are supported best-effort; privacy annotations are not.)")
public func OTFFault(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    logger(.fault, message, args, category: category)
}

/// Installs **development-only** crash breadcrumbs.
///
/// This sets an `NSSetUncaughtExceptionHandler` to capture uncaught exceptions and
/// registers basic POSIX signal handlers for common crash signals.
///
/// - Warning: Signal handlers are **not** async-signal-safe when calling into Swift/OSLog.
///   Use for diagnostics during development only. For production, prefer a dedicated crash
///   reporting SDK (e.g., Crashlytics, Sentry) or rely on system crash logs.
public func setupCrashLogging() {
    #if DEBUG
    NSSetUncaughtExceptionHandler { exception in
        let stackTrace = exception.callStackSymbols.joined(separator: "\n")
        let message = "Uncaught Exception: \(exception.name.rawValue) - \(exception.reason ?? "Unknown reason")\n\(stackTrace)"
        OTFLogger.logger().critical("\(message)")
    }
    
    // Re-raise signals after writing a short message.
    for sig in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE] {
        signal(sig) { s in
            let txt = "Received signal \(s)\n"
            _ = txt.withCString { ptr in write(STDERR_FILENO, ptr, strlen(ptr)) }
            signal(s, SIG_DFL)
            raise(s)
        }
    }
    #endif
}

/// Logs the start of a network request with basic metadata.
///
/// Stores an opaque key (derived from method, URL, headers and body) to measure duration
/// when the corresponding response is logged via ``logResponse(_:response:data:error:)``.
///
/// - Parameter request: The `URLRequest` to describe.
/// - Note: If present, request bodies are logged using `.private` privacy to avoid leaking PII.
public func logRequest(_ request: URLRequest) {
    let timestamp = logTimestamp()
    let startTime = Date()
    let method = request.httpMethod ?? "UNKNOWN"
    let urlString = request.url?.absoluteString ?? "UNKNOWN"
    let headers = request.allHTTPHeaderFields ?? [:]
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    
    let requestKey = generateRequestKey(method: method, url: urlString, headers: headers, body: body)
    requestStartTimes[requestKey] = startTime
    
    let logMessage = """
            \n➡️ [\(timestamp)]\nAPI Request: \(method)
            \nURL: \(urlString)
            \nHeaders: \(headers.isEmpty ? "None" : headers.description)
            """
    
    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        OTFLogger.logger().debug("Body: \(bodyString, privacy: .private)")
    }
    
    OTFLogger.logger().info("\(logMessage)")
}

/// Logs the end of a network request with duration and response metadata.
///
/// - Parameters:
///   - request: The original `URLRequest` (used to correlate with the start time).
///   - response: The `URLResponse`, if any.
///   - data: The response body as raw `Data`, if any.
///   - error: An error that occurred, if any.
///
/// - Note: This function computes and logs the elapsed time since ``logRequest(_:)`` was called
///   for the same request (within process lifetime). If the start time cannot be found,
///   the duration is reported as "Unknown".
public func logResponse(_ request: URLRequest?, response: URLResponse?, data: Data?, error: Error?) {
    let timestamp = logTimestamp()
    
    guard let request else {
        OTFLogger.logger().info("[\(timestamp)] Response received but request is missing.")
        return
    }
    
    let method = request.httpMethod ?? "UNKNOWN"
    let urlString = request.url?.absoluteString ?? "UNKNOWN"
    let headers = request.allHTTPHeaderFields ?? [:]
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    let requestKey = generateRequestKey(method: method, url: urlString, headers: headers, body: body)
    
    var durationString = "Unknown"
    if let startTime = requestStartTimes[requestKey] {
        let duration = Date().timeIntervalSince(startTime)
        requestStartTimes.removeValue(forKey: requestKey)
        durationString = duration >= 1.0 ? String(format: "%.3f s", duration)
        : String(format: "%.0f ms", duration * 1000)
    }
    
    var logMessage = "\n⬅️ [\(timestamp)]\nAPI Response\n(Response Time: \(durationString))\nURL: \(urlString)"
    
    if let httpResponse = response as? HTTPURLResponse {
        let responseHeaders = httpResponse.allHeaderFields.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        logMessage += """
            \nStatus Code: \(httpResponse.statusCode)
            Headers: \(responseHeaders)
            """
        
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            logMessage += "\nResponse Body: \(responseString)"
        }
    }
    
    if let error = error {
        logMessage += "\nAPI Error: \(error.localizedDescription)"
    }
    
    OTFLogger.logger().info("\(logMessage)")
}

// MARK: - Private (internals)

/// In-memory start times for requests. Not thread-safe by design (legacy behavior).
private var requestStartTimes = [String: Date]()

/// Forwards messages to the unified logging system using the provided `OSLogType`.
/// Best-effort support for legacy `os_log`-style formatting via `String(format:)`.
/// - Parameters:
///   - type: The desired log level (e.g., `.debug`, `.info`, `.error`, `.fault`).
///   - message: A `StaticString` message. (Privacy annotations are **not** supported here; prefer ``OTFLogger``.)
///   - args: C-style variadic arguments captured from the deprecated shims.
///   - category: The log category; defaults to the calling symbol name.
private func logger(_ type: OSLogType, _ message: StaticString, _ args: [CVarArg], category: String) {
    let subsystem = Bundle.main.bundleIdentifier ?? "OTFUtilities"
    let logger = Logger(subsystem: subsystem, category: category)
    
    // If there are variadic args, format with NSString(format:), otherwise use the StaticString directly.
    let rendered: String = {
        if args.isEmpty {
            return String(describing: message)
        } else {
            let format = String(describing: message)
            return withVaList(args) { NSString(format: format, arguments: $0) as String }
        }
    }()
    
    switch type {
    case .debug: logger.debug("\(rendered)")
    case .info:  logger.info("\(rendered)")
    case .error: logger.error("\(rendered)")
    case .fault: logger.critical("\(rendered)")
    default: logger.log("\(rendered)")
    }
}

/// Cached timestamp formatter (avoids cost of DateFormatter creation on each call).
private let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

/// Current timestamp string for logs.
private func logTimestamp() -> String {
    logDateFormatter.string(from: Date())
}

/// Generates a **process-lifetime** request key from method, URL, headers (sorted), and body text.
///
/// - Important: This is not a cryptographic hash and is not stable across app launches or processes.
///   It is only intended for temporary correlation between `logRequest(_:)` and `logResponse(...)` in the
///   same process lifetime.
/// - Parameters:
///   - method: HTTP method (e.g., "GET").
///   - url: Request URL string.
///   - headers: Request headers. Keys are sorted to achieve consistent ordering.
///   - body: Request body as text.
/// - Returns: An opaque string suitable as a dictionary key for in-process correlation.
private func generateRequestKey(method: String, url: String, headers: [String: String], body: String) -> String {
    let headersString = headers.sorted { $0.key < $1.key }
        .map { "\($0.key): \($0.value)" }
        .joined(separator: ", ")
    
    let rawKey = "\(method) \(url) \(headersString) \(body)"
    return rawKey.hashValue.description
}
