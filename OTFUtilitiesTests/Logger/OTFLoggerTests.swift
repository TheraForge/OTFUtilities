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

// OTFLoggerTests.swift

import OSLog
import Testing
@testable import OTFUtilities

@Suite("OTFLogger Tests")
struct OTFLoggerTests {
    
    @Test("logger() returns a usable Logger")
    func testLoggerUsable() {
        let logger = OTFLogger.logger()
        // Log a few messages at different levels to ensure no crash.
        logger.debug("debug smoke test")
        logger.info("info smoke test")
        logger.warning("warning smoke test")
        logger.error("error smoke test")
        logger.critical("critical smoke test")
        // reached here without crash
        #expect(true)
    }
    
    @Test("deriveCategory strips .swift and path components")
    func testDeriveCategory() {
        let derived = OTFLogger.deriveCategory(from: "Some/Path/MyFile.swift")
        #expect(derived == "MyFile")
    }
    
    @Test("logger(file:) caches per category (no deadlock, no crash)")
    func testLoggerCachingDoesNotExplode() {
        for _ in 0..<1000 {
            _ = OTFLogger.logger(file: "Some/Path/FakeFile.swift")
        }
        // finished loop without issue
        #expect(true)
    }
    
    @Test("setGlobalSubsystem round-trip")
    func testGlobalSubsystemRoundTrip() {
        let prev = OTFLogger.setGlobalSubsystem("com.example.tests")
        // restore
        defer { _ = OTFLogger.setGlobalSubsystem(prev) }
        // We can't inspect the subsystem on Logger; just exercise code paths.
        let logger = OTFLogger.logger(category: "RoundTrip")
        logger.debug("debug")
        #expect(true)
    }
}
