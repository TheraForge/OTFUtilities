# OTFUtilities

This is TheraForge's Utilities framework that provide various helper function.

OTFUtilities implements the functions required to perform e2e encryption using swift Sodium.



## Master Key

Create a `Master Key` by using generateMasterKey funcion and pass email addrress and password. 
```
let masterKey = swiftSodium.generateMasterKey(email: "your email address", password: "your password")
```

## Default Storage Key

Create a `Default Storage Key` by using generateDefaultStorageKey funcion and pass your master key. 
```
let defaultStorageKey = swiftSodium.generateDefaultStorageKey(masterKey: "your master key")
```

## Confidential Storage Key

Create a `Confidential Storage Key` by using generateConfidentialStorageKey function and pass your master key. 
```
let confidentialStorageKey = swiftSodium.generateConfidentialStorageKey(masterKey: "your master key")
```

## File Key

Create a `File Key` by using generateDeriveKey function and pass your default storage key. 
```
let fileKey = swiftSodium.generateDeriveKey(key: "your default storage key")
```

## GenericHash With Key

Create a `GenericHash With Key` by using generateGenericHashWithKey function and pass your document bytes and your file key. 
```
let hashKeyUsingKey = swiftSodium.generateGenericHashWithKey(message: "your document bytes", fileKey: "your file key")
```

## GenericHash Without Key

Create a `GenericHash Without Key` by using generateGenericHashWithoutKey function and pass your document bytes. 
```
let hashKeyUsingKey = swiftSodium.generateGenericHashWithoutKey(message: "your document bytes")
```

## Save Key

You can save the key in your keychain by using `saveKey` function.
```
swiftSodium.saveKey(key: "your key bytes", keychainKey: "key name")
```

## Load Key

You can load the key from your keychain by using `loadKey` function.
```
swiftSodium.loadKey(keychainKey: "your key name")
```

## Encrypt Key
You can encrypt your key by using `encryptKey` function and pass key bytes and recipient Public Key.

```
let encryptkey : Bytes? = swiftSodium.encryptKey(bytes: "key in bytes", publicKey: "recipient Public Key")
```

## Decrypt Key
You can encrypt your key by using `decryptKey` function and pass encrypyted key bytes, recipient Public Key and recipient Secret Key.

```
let decrryptedKey =  swiftSodium.decryptKey(bytes: "encrypyted key bytes", publicKey: "recipient Public Key", secretKey: "recipient Secret Key")
```

## Encrypt Document
You can encrypt your document by using `encryptFile` function and pass Push Stream Object and document in bytes.

```
let encryptedFile = swiftSodium.encryptFile(pushStream: "Push Stream Object", fileBytes: "document in bytes")
```

## Decrypt Document
You can encrypt your document by using `decryptFile` function and pass Push Stream Header, file key and encrypted document in bytes.

```
guard let (file, tag) = swiftSodium.decryptFile(secretKey: "file key", header: "push stream header", encryptedFile: "encrypted File key")
```

## Convert Hex To Data

you can create `hexString To Data` by using hexStringToData function.
```
let data = swiftSodium.hexStringToData(string: "hexString")
```

# License <a name="License"></a>

This project is made available under the terms of a modified BSD license. See the [LICENSE](LICENSE.md) file.




