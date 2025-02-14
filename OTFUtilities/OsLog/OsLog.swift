/*
 Copyright (c) 2024, Hippocrates Technologies Sagl. All rights reserved.

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

public enum LoggerCategory: String {
    case networking
    case events
    case xcTest
    case crash
}

private var requestStartTimes = [String: Date]()

// Error-level messages are intended for reporting critical errors and failures.
public func OTFError(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.error, message, args, category: category)
}

// Call this function to capture information that may be helpful, but isn’t essential, for troubleshooting.
public func OTFLog(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.info, message, args, category: category)
}

// Debug-level messages are intended for use in a development environment while actively debugging.
public func OTFDebug(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.debug, message, args, category: category)
}

// Fault-level messages are intended for capturing system-level or multi-process errors only.
public func OTFFault(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.fault, message, args, category: category)
}

func OTFLogger(_ type: OSLogType, _ message: StaticString, _ args: CVarArg..., category: String) {
    let appIdentifier = Bundle.main.bundleIdentifier ?? ""
    let log = OSLog(subsystem: "\(appIdentifier)", category: category)
    os_log(type, log: log, message)
}

// MARK: - Crash Handling

public func setupCrashLogging() {
    NSSetUncaughtExceptionHandler { exception in
        let stackTrace = exception.callStackSymbols.joined(separator: "\n")
        let message = "Uncaught Exception: \(exception.name.rawValue) - \(exception.reason ?? "Unknown reason")\n\(stackTrace)"
        OTFError("%@", message, category: LoggerCategory.crash.rawValue)
    }
    
    signal(SIGABRT) { _ in logCrash(signal: "SIGABRT") }
    signal(SIGILL)  { _ in logCrash(signal: "SIGILL") }
    signal(SIGSEGV) { _ in logCrash(signal: "SIGSEGV") }
    signal(SIGFPE)  { _ in logCrash(signal: "SIGFPE") }
    signal(SIGBUS)  { _ in logCrash(signal: "SIGBUS") }
    signal(SIGPIPE) { _ in logCrash(signal: "SIGPIPE") }
}

func logCrash(signal: String) {
    OTFError("App Crashed due to signal: %@", signal, category: LoggerCategory.crash.rawValue)
}

// Shared DateFormatter for timestamps
private let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

// Function to generate a timestamp
private func logTimestamp() -> String {
    return logDateFormatter.string(from: Date())
}

private func generateRequestKey(method: String, url: String, headers: [String: String], body: String) -> String {
    // Sort headers for consistency
    let headersString = headers.sorted { $0.key < $1.key }
        .map { "\($0.key): \($0.value)" }
        .joined(separator: ", ")
    
    let rawKey = "\(method) \(url) \(headersString) \(body)"
    return rawKey.hashValue.description
}

public func logRequest(_ request: URLRequest) {
    let timestamp = logTimestamp()
    let startTime = Date() // Capture request start time
    
    let method = request.httpMethod ?? "UNKNOWN"
    let urlString = request.url?.absoluteString ?? "UNKNOWN"
    let headers = request.allHTTPHeaderFields ?? [:]
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    
    let requestKey = generateRequestKey(method: method, url: urlString, headers: headers, body: body)
    requestStartTimes[requestKey] = startTime
    
    let logMessage = """
            \n➡️ [\(timestamp)] \nAPI Request: \(request.httpMethod ?? "UNKNOWN")
            \nURL: \(request.url?.absoluteString ?? "UNKNOWN")
            \nHeaders: \(request.allHTTPHeaderFields?.description ?? "None")
            """
    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        OTFLog("Body: %{private}@", bodyString, category: LoggerCategory.networking.rawValue)
    }
    //        OTFLog("%{public}@", logMessage, category: LoggerCategory.networking.rawValue)
    os_log("%{public}@", log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: LoggerCategory.networking.rawValue), logMessage)
}

public func logResponse(_ request: URLRequest?, response: URLResponse?, data: Data?, error: Error?) {
    let timestamp = logTimestamp()
    
    guard let request = request else {
        os_log("[%@] %{public}@", log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: LoggerCategory.networking.rawValue), timestamp, "Response received but request is missing.")
        return
    }
    
    let method = request.httpMethod ?? "UNKNOWN"
    let urlString = request.url?.absoluteString ?? "UNKNOWN"
    let headers = request.allHTTPHeaderFields ?? [:]
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    
    // Generate the same key as in logRequest
    let requestKey = generateRequestKey(method: method, url: urlString, headers: headers, body: body)
    var durationString = "Unknown"
    
    if let startTime = requestStartTimes[requestKey] {
        let duration = Date().timeIntervalSince(startTime)
        requestStartTimes.removeValue(forKey: requestKey) // Clean up
        
        if duration >= 1.0 {
            durationString = String(format: "%.3f s", duration)
        } else {
            durationString = String(format: "%.0f ms", duration * 1000)
        }
    }
    
    var logMessage = "\n⬅️ [\(timestamp)]\nAPI Response \n(Response Time: \(durationString) \nURL: \(urlString)\nResponse: )"
    
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
    
    os_log("[%@] %{public}@", log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: LoggerCategory.networking.rawValue), timestamp, logMessage)
}
