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

#if os(iOS)
import Sodium
#endif

extension Array where Element == UInt8 {
    
    /// Converts the byte array to an **uppercase** hexadecimal string.
    ///
    /// Each byte is formatted as two hexadecimal characters (`%02X`), and the given
    /// `spacing` string is inserted *between* bytes for readability (for example `" "` or `":"`).
    ///
    /// - Parameter spacing: The delimiter to place between each formatted byte. Use an empty string for a compact hex string.
    /// - Returns: A hex string representation of the byte array.
    func bytesToHex(spacing: String) -> String {
        var hexString: String = ""
        var count = self.count
        for byte in self {
            hexString.append(String(format: "%02X", byte))
            count -= 1
            if count > 0 { hexString.append(spacing) }
        }
        return hexString
    }
    
    #if os(iOS)
    /// Splits a `libsodium` SecretStream ciphertext into header and body.
    ///
    /// `libsodium`'s `XChaCha20-Poly1305` secret stream prepends a fixed-size header
    /// (`SecretStream.XChaCha20Poly1305.HeaderBytes`) to the encrypted data. This helper
    /// slices the current byte array into:
    /// - `left`: the header bytes (to be provided when initializing a pull stream)
    /// - `right`: the remaining ciphertext bytes
    ///
    /// - Warning: This function performs no validation that the array length is at least `HeaderBytes`.
    ///   Supplying a shorter array will trap at runtime. Callers should validate the input length first.
    /// - Returns: A tuple `(left: header, right: ciphertext)`.
    func splitFile() -> (left: [Element], right: [Element]) {
        let size = self.count
        let splitIndex = SecretStream.XChaCha20Poly1305.HeaderBytes
        let leftSplit = self[0 ..< splitIndex]
        let rightSplit = self[splitIndex ..< size]
        return (left: Array(leftSplit), right: Array(rightSplit))
    }
    #endif
}
