//
//  ArrayExtention.swift
//  OTFUtilities
//
//  Created by Zeeshan on 11/10/2023.
//

import Sodium

extension Array where Element == UInt8 {
    func bytesToHex(spacing: String) -> String {
        var hexString: String = ""
        var count = self.count
        for byte in self
        {
            hexString.append(String(format:"%02X", byte))
            count = count - 1
            if count > 0
            {
                hexString.append(spacing)
            }
        }
        return hexString
    }
    
    func splitFile() -> (left: [Element], right: [Element]) {
            let size = self.count
            let splitIndex = SecretStream.XChaCha20Poly1305.HeaderBytes
            let leftSplit = self[0 ..< splitIndex]
            let rightSplit = self[splitIndex ..< size]
     
            return (left: Array(leftSplit), right: Array(rightSplit))
        }
}
