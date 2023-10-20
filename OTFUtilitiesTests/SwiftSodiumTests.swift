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
import XCTest
import OTFUtilities
import Sodium

class SwiftSodiumTests: XCTestCase {
    
    var swiftSodium = SwiftSodium()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    
    func testEncryptAndDecryptFile() {
        
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        
        // fetch file
        guard let filePath = Bundle(for: type(of: self)).path(forResource: "user", ofType: "png"),
              let image = UIImage(contentsOfFile: filePath),
              let data = image.pngData() else {
            fatalError("Image not available")
        }
        
        let originalFileBytes = swiftSodium.getArrayOfBytesFromData(FileData: data as NSData)
        
        // encryption process
        let documentPushStream = swiftSodium.getPushStream(secretKey: fileKey)!
        let fileencryption = swiftSodium.encryptFile(pushStream: documentPushStream, fileBytes: originalFileBytes)
        let encryptedFileWithHeader = [documentPushStream.header(), fileencryption].flatMap({ (element: [UInt8]) -> [UInt8] in
            return element
        })
        
        XCTAssertNotNil(encryptedFileWithHeader)
        
        // decryptiion
        let (header, encryptedFile) = encryptedFileWithHeader.splitFile()
        let decrypt = swiftSodium.decryptFile(secretKey: fileKey, header: header, encryptedFile: encryptedFile)
        guard let (decryptedFile, _)   = decrypt else { fatalError("File not decrypted") }
        XCTAssertEqual(originalFileBytes, decryptedFile)
        
    }
    
    func  testencryptAndDecryptKey(){
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let keyPair = swiftSodium.sodium.box.keyPair(seed: masterKey)!
        // encryption
        let encryptedkey : Bytes? = swiftSodium.encryptKey(bytes: masterKey, publicKey: keyPair.publicKey)
        let encryptedkeyHex = encryptedkey?.bytesToHex(spacing: "").lowercased()
        XCTAssertNotNil(encryptedkey)
        
        let hexToData = swiftSodium.hexStringToData(string: encryptedkeyHex!)
        let dataToBytes = swiftSodium.getArrayOfBytesFromData(FileData: hexToData as NSData)
        
        // decryption
        let decryptedkey : Bytes? = swiftSodium.decryptKey(bytes: dataToBytes, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey)
        XCTAssertNotNil(decryptedkey)
        
        XCTAssertEqual(masterKey, decryptedkey)
    }
    
    func testMasterKeyGeneration() {
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        XCTAssertNotNil(masterKey)
    }
    
    func testgenerateKeypairFromMasterKey() {
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let ketPair = swiftSodium.sodium.box.keyPair(seed: masterKey)
        XCTAssertNotNil(ketPair)
    }
    
    func testDerivedKeyGeneration(){
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        XCTAssertNotNil(fileKey)
        
    }
    
    func testGenerateFileHashKey(){
        let data = "Hello World!"
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        let fileHashKey = swiftSodium.generateGenericHashWithKey(message: data.bytes, fileKey: fileKey)
        XCTAssertNotNil(fileHashKey)
    }
    
    func testGenerateFileHashKeyWithoutKey(){
        let message = "Hello World!"
        let fileHashKey = swiftSodium.generateGenericHashWithoutKey(message: message.bytes)
        XCTAssertNotNil(fileHashKey)
    }
    
    func testXChaCha20Poly1305encryptionAndDecryption(){
        let data = "Hello World!"
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
        let fileKey = swiftSodium.generateDeriveKey(key: defaultStorageKey)
        let pushStream : SecretStream.XChaCha20Poly1305.PushStream = swiftSodium.getPushStream(secretKey: fileKey)!
        let fileencryption = swiftSodium.encryptFile(pushStream: pushStream, fileBytes: data.bytes)
        XCTAssertNotNil(fileencryption)
        let (filedecryption, _) = swiftSodium.decryptFile(secretKey: fileKey, header: pushStream.header(), encryptedFile: fileencryption)!
        XCTAssertNotNil(filedecryption)
        XCTAssertEqual(data, filedecryption.utf8String ?? "")
    }
    
    func testGenerateDefaultStorageKey(){
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: masterKey)
        XCTAssertNotNil(defaultStorageKey)
    }
    
    func testGenerateConfidentialStorageKey(){
        let masterKey = swiftSodium.generateMasterKey(password: "1231231231", email: "zeeshan.ahmed@invozone.com")
        let confidentialStorageKey = swiftSodium.generateConfidentialStorageKey(masterKey: masterKey)
        XCTAssertNotNil(confidentialStorageKey)
    }
    
    func testbytesToHex(){
        let bytes : [UInt8] = [48, 49, 48, 50, 48, 51, 48, 52, 48, 53]
        let hex = bytes.bytesToHex(spacing: "").lowercased()
        let convertedBytes = swiftSodium.getArrayOfBytesFromData(FileData: swiftSodium.hexStringToData(string: hex) as NSData)
        XCTAssertEqual(bytes, convertedBytes)
    }
}
