# OTFUtilities

This is TheraForge ToolBox's Utilities framework, which provides various helper functions to other frameworks: for example, the OTFLogger facility and the functions required to perform end-to-end encryption using Swift Sodium.

## Change Log
<details closed>
  <summary>Release 1.0.2-beta</summary>
  
  - **OSLog Update**
    - Improved logging of all events
 - **Added Crash Logging**
</details>

<details closed>
  <summary>Release 1.0.1-beta</summary>
  
  - **OSLog Update**
    - Updated `OSLog` to support iOS 14.0+
    - Added the watchOS target
</details>


## Master Key

Create a `Master Key` by using the generateMasterKey function and by passing an email address and password to it. 
```
let masterKey = swiftSodium.generateMasterKey(email: "your email address", password: "your password")
```

## Default Storage Key

Create a `Default Storage Key` by using the generateDefaultStorageKey function and by passing your master key to it. 
```
let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: "your master key")
```

## Confidential Storage Key

Create a `Confidential Storage Key` by using the generateConfidentialStorageKey function and by passing your master key to it. 
```
let confidentialStorageKey = swiftSodium.generateConfidentialStorageKey(masterKey: "your master key")
```

## File Key

Create a `File Key` by using the generateDeriveKey function and by passing your default storage key to it. 
```
let fileKey = swiftSodium.generateDeriveKey(key: "your default storage key")
```

## GenericHash With Key

Create a `GenericHash With Key` by using the generateGenericHashWithKey function and by passing your document bytes and your file key to it. 
```
let hashKeyUsingKey = swiftSodium.generateGenericHashWithKey(message: "your document bytes", fileKey: "your file key")
```

## GenericHash Without Key

Create a `GenericHash Without Key` by using the generateGenericHashWithoutKey function and by passing your document bytes to it. 
```
let hashKeyUsingKey = swiftSodium.generateGenericHashWithoutKey(message: "your document bytes")
```

## Save Key

You can save the key in your Keychain by using the `saveKey` function.
```
swiftSodium.saveKey(key: "your key bytes", keychainKey: "key name")
```

## Load Key

You can load the key from your Keychain by using the `loadKey` function.
```
swiftSodium.loadKey(keychainKey: "your key name")
```

## Encrypt Key
You can encrypt your key by using the `encryptKey` function and by passing the key bytes and the recipient's Public Key to it.

```
let encryptkey : Bytes? = swiftSodium.encryptKey(bytes: "key bytes", publicKey: "recipient's Public Key")
```

## Decrypt Key
You can dencrypt your key by using the `decryptKey` function and by passing the encrypyted key bytes, the recipient's Public Key, and the recipient's Secret Key.

```
let decrryptedKey =  swiftSodium.decryptKey(bytes: "encrypyted key bytes", publicKey: "recipient's Public Key", secretKey: "recipient's Secret Key")
```

## Encrypt Document
You can encrypt your document by using the `encryptFile` function and by passing the push stream object and the document bytes.

```
let encryptedFile = swiftSodium.encryptFile(pushStream: "Push Stream Object", fileBytes: "document bytes")
```

## Decrypt Document
You can dencrypt your document by using the `decryptFile` function and by passing the file's key, the push stream header, and the encrypted document bytes.

```
guard let (file, tag) = swiftSodium.decryptFile(secretKey: "file's key", header: "push stream header", encryptedFile: "encrypted file bytes")
```

## Convert Hex To Data

You can convert `hexString to data` by using the hexStringToData function.
```
let data = swiftSodium.hexStringToData(string: "hexString")
```

# License <a name="License"></a>

This project is made available under the terms of a modified BSD license. See the [LICENSE](LICENSE.md) file.




