/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

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
}

//Error-level messages are intended for reporting critical errors and failures.

public func OTFError(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.error, message, args, category: category)
}

//Call this function to capture information that may be helpful, but isn’t essential, for troubleshooting.

public func OTFLog(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.info, message, args, category: category)
}

//Debug-level messages are intended for use in a development environment while actively debugging.

public func OTFDebug(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.debug, message, args, category: category)
}

//Fault-level messages are intended for capturing system-level or multi-process errors only.

public func OTFFault(_ message: StaticString, _ args: CVarArg..., category: String = #function) {
    OTFLogger(.fault, message, args, category: category)
}

func OTFLogger(_ type: OSLogType, _ message: StaticString, _ args: CVarArg... , category: String) {
    let appIdentifier = Bundle.main.bundleIdentifier ?? ""
    let log = OSLog(subsystem: "\(appIdentifier).logging", category: category)
    if #available(iOS 12.0, *), #available(watchOSApplicationExtension 5.0, *) {
        os_log(type, log: log, message, args)
    } else {
        os_log(message, log: log, type: type, args)
    }
}
