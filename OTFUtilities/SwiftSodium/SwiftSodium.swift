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
import Sodium

public class SwiftSodium {
    
    public let sodium = Sodium()
    
    public init() {}
    
    public func encryptFile(data: Data, serderSecretKey: Box.KeyPair.SecretKey, receiverPublicKey: Box.KeyPair.PublicKey) -> Bytes {
        
        let bytesImage = getArrayOfBytesFromData(FileData: data as NSData)
        let encryptedFile: Bytes =
        sodium.box.seal(
            message: bytesImage,
            recipientPublicKey: receiverPublicKey,
            senderSecretKey: serderSecretKey)!
        
        return encryptedFile
    }
    
    public func getPushStream(secretKey: Bytes) -> SecretStream.XChaCha20Poly1305.PushStream? {
        let pushStream = sodium.secretStream.xchacha20poly1305.initPush(secretKey: secretKey)
        return pushStream
    }
    
    public func encryptFile(pushStream: SecretStream.XChaCha20Poly1305.PushStream, fileBytes: Bytes) -> Bytes {
        let encryption = pushStream.push(message: fileBytes)!
        return encryption
    }
    

    public func decryptFile(secretKey: Bytes, header: Bytes, encryptedFile: Bytes) -> (Bytes, SecretStream.XChaCha20Poly1305.Tag)? {
         let pullStream = sodium.secretStream.xchacha20poly1305.initPull(secretKey: secretKey, header: header)!
        let decryptFile = pullStream.pull(cipherText: encryptedFile)
        return decryptFile
    }
    
    
    public func decryptFile(data: Bytes, serderPublicKey: Box.KeyPair.PublicKey, receiverSecretKey: Box.KeyPair.SecretKey) -> Data {
        let decryptedFile =
        sodium.box.open(
            nonceAndAuthenticatedCipherText: data,
            senderPublicKey: serderPublicKey,
            recipientSecretKey: receiverSecretKey)
        let bytesToData = Data(decryptedFile!)
        return bytesToData
    }
    
    // Secret Box
    public func encryptKey(bytes: Bytes, publicKey: Box.KeyPair.PublicKey, email: String) -> Bytes {
        guard let nonce = sodium.genericHash.hash(message: email.bytes, outputLength: sodium.secretBox.NonceBytes) else { fatalError("Error while generating seed from string") }
        let encryptedBytes: Bytes = sodium.secretBox.seal(message: bytes, secretKey: publicKey, nonce: nonce)!
        return encryptedBytes
    }
    
    public func decryptKey(bytes: Bytes, publicKey: Box.KeyPair.PublicKey, email: String) -> Bytes {
        guard let nonce = sodium.genericHash.hash(message: email.bytes, outputLength: sodium.secretBox.NonceBytes) else { fatalError("Error while generating seed from string") }
        let decryptedBytes: Bytes = sodium.secretBox.open(authenticatedCipherText: bytes, secretKey: publicKey, nonce: nonce)!
        return decryptedBytes
    }
    
    // Sealed Box
    public func encryptKey(bytes: Bytes, publicKey: Bytes) -> Bytes {
        let encryptedBytes: Bytes = sodium.box.seal(message: bytes, recipientPublicKey: publicKey)!
        return encryptedBytes
    }
    
    public func decryptKey(bytes: Bytes, publicKey: Box.KeyPair.PublicKey, secretKey: Box.KeyPair.SecretKey) -> Bytes {
        let decryptedBytes: Bytes = sodium.box.open(anonymousCipherText: bytes, recipientPublicKey: publicKey, recipientSecretKey: secretKey)!
        return decryptedBytes
    }
    
    public func saveKey(key: Bytes, keychainKey: String) {
        let data = NSData(bytes: key, length: key.count)
        let result = KeychainService.saveKey(key: keychainKey, data: data)
        print(result)
    }
    
    public func loadKey(keychainKey: String) -> Data {
        if let receivedData = KeychainService.loadKey(key: keychainKey) {
            return receivedData
        }
        return Data()
    }
    
    public func saveStringValue(key: String, keychainKey: String) {
        let data = NSData(bytes: key, length: key.count)
        let result = KeychainService.saveKey(key: keychainKey, data: data)
        print(result)
    }
    
    public func independentIncreption(data: Data, serderSecretKey: Box.KeyPair.SecretKey) -> Bytes {
        let bytesImage = getArrayOfBytesFromData(FileData: data as NSData)
        let encryptedMessage: Bytes = sodium.secretBox.seal(message: bytesImage, secretKey: serderSecretKey)!
        return encryptedMessage
    }
    
    public func independentDecryption(serderSecretKey: Box.KeyPair.SecretKey, data: Bytes) -> Data  {
        if let decryptedMessage = sodium.secretBox.open(nonceAndAuthenticatedCipherText: data, secretKey: serderSecretKey) {
            let bytesToData = Data(decryptedMessage)
            return bytesToData
        }
        return Data()
    }
    
    public func getArrayOfBytesFromData(FileData: NSData) -> Array<UInt8> {
        let count = FileData.length / MemoryLayout<Int8>.size
        var bytes = [UInt8](repeating: 0, count: count)
        FileData.getBytes(&bytes, length: count * MemoryLayout<Int8>.size)
        var byteArray: Array = Array<UInt8>()
        for value in 0 ..< count {
            byteArray.append(bytes[value])
        }
        return byteArray
    }
    
    public func hexStringToData(string: String) -> Data {
       let stringArray = Array(string)
       var data: Data = Data()
       for i in stride(from: 0, to: string.count, by: 2) {
           let pair: String = String(stringArray[i]) + String(stringArray[i+1])
           if let byteNum = UInt8(pair, radix: 16) {
               let byte = Data([byteNum])
               data.append(byte)
           }
           else{
               fatalError()
           }
       }
       return data
   }
    
    public func generateMasterKey(password: String, email: String) -> Bytes {
        guard let salt = sodium.genericHash.hash(message: email.bytes, outputLength: sodium.pwHash.SaltBytes) else { fatalError("Error while generating seed from string") }
        //        master key
        let masterKey = sodium.pwHash.hash(outputLength: 32, passwd: password.bytes, salt: salt, opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive)!
        return masterKey
    }
    
    public func generateDeriveKey(key: Bytes) -> Bytes {
        guard let deriveKey = sodium.keyDerivation.derive(secretKey: key,
            index: 1, length: key.count,
            context: "user_key") else {
            fatalError("error while generating master key")
        }
        return deriveKey
    }
    
    public func generateGenericHashWithKey(message : Bytes, fileKey: Bytes) -> Bytes {
        guard let fileHashKey = sodium.genericHash.hash(message: message, key: fileKey, outputLength: 32) else {
            fatalError("error while generateGenericHashWithKey")
        }
        return fileHashKey
    }
    
    public func generateGenericHashWithoutKey(message : Bytes) -> Bytes {
        guard let fileHashKey = sodium.genericHash.hash(message: message, key: nil, outputLength: 32) else {
            fatalError("error while generateGenericHashWithoutKey")
        }
        return fileHashKey
    }
    
    
    public func generateDefaultStorageKey(masterKey: Bytes) -> Bytes {
        guard let defaultStorageKey = sodium.keyDerivation.derive(secretKey: masterKey,
            index: 1, length: masterKey.count,
            context: "user_key") else {
            fatalError("error while generating master key")
        }
        return defaultStorageKey
    }
    
    public func generateConfidentialStorageKey(masterKey: Bytes) -> Bytes {
        guard let confidentialStorageKey = sodium.keyDerivation.derive(secretKey: masterKey,
            index: 2, length: masterKey.count,
            context: "user_key") else {
            fatalError("error while generating master key")
        }
        return confidentialStorageKey
    }
    
}

