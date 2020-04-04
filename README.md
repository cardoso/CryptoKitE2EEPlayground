---
title: CryptoKit Basics: End-to-End Encryption
published: true
description: How to achieve basic end-to-end encryption in your Swift App using Apple's CryptoKit.
tags: Swift, Cryptography, iOS, Security
---

Security can be a major concern for companies and developers building applications, especially in the medical field where data breaches are severely penalized. This is where end-to-end encryption comes into play.

In this guide, you'll learn how to implement a basic end-to-end encryption flow in your Swift application for iOS, macOS, other Apple things, and even Linux, using Apple's own [CryptoKit](https://developer.apple.com/documentation/cryptokit) framework.

### What is CryptoKit? 
> CryptoKit is a new Swift framework that makes it easier and safer than ever to perform cryptographic operations, whether you simply need to compute a hash or are implementing a more advanced authentication protocol.
> - [WWDC19: Cryptography and Your Apps](https://developer.apple.com/videos/play/wwdc2019/709/)

### What is end-to-end encryption?
> End-to-end encryption is a system of communication where the only people who can read the messages are the people communicating. No eavesdropper can access the cryptographic keys needed to decrypt the conversation—not even a company that runs the messaging service.
> - [Hacker Lexicon: What Is End-to-End Encryption](https://www.wired.com/2014/11/hacker-lexicon-end-to-end-encryption/)

### What you need
CryptoKit is available on the following platforms:
- iOS 13.0+
- macOS 10.15+
- Mac Catalyst 13.0+
- tvOS 13.0+
- watchOS 6.0+
- Linux (as [Swift Crypto](#what-is-swift-crypto))

### Step 1: Generating Key Pairs
Cryptographic key pairs are central to end-to-end encryption: A public key is what you use to encrypt data for someone, and a private key is what you use to decrypt data that was encrypted for you. Each user in your application should have a key pair, with their public key available 
in a trusted service for other users to fetch, and their private keys stored securely on their device. The trusted service can be written in Swift using [Vapor](https://vapor.codes/), or another language and framework of your choice.

We will first generate a private key, then extract the associated public key from it, which will be sent to the trusted service. In this guide we'll use the [Curve25519](https://en.wikipedia.org/wiki/Curve25519#Popularity) algorithms, but the others should work similarly.

```swift
import CryptoKit

// generate key pair
let privateKey = Curve25519.KeyAgreement.PrivateKey()
let publicKey = privateKey.publicKey

// publish public key in trusted service
TrustedService.publishKey(publicKey, for: myIdentity)
```

The public key has a `var rawRepresentation: Data` property which can be used to serialize it into the payload for the trusted service.

### Step 2: Encrypting Data
To encrypt data for a user (recipient), first you need to fetch their public key from the trusted service.

```swift
let recipientPublicKey = TrustedService.fetchPublicKey(of: recipientIdentity)
```

The initializer `Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data)` can be used to deserialize the public key coming from the trusted service.

#### Step 2.1: Deriving a Symmetric Key
Public keys can't be used to encrypt data directly. They're used by the two parties communicating to agree on a symmetric key for encryption, via a [Diffie-Hellmann key agreement](https://en.wikipedia.org/wiki/Key-agreement_protocol). To do this, we will use the sender's private key and the recipient's public key to generate a shared secret, from which we can derive the symmetric key using the [HKDF](https://en.wikipedia.org/wiki/HKDF) key derivation function.

```swift
let sharedSecret = try! privateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                        salt: protocolSalt,
                                                        sharedInfo: Data(),
                                                        outputByteCount: 32)
```

The protocol salt is a value that alters the outcome of the symmetric key derivation. Choose one that will remain constant for your use case, for example: `"My Key Agreement Salt".data(using: .utf8)!`

#### Step 2.2: Encrypting the Data with the Symmetric Key
Now, we can finally use that symmetric key to perform the encryption. This job can be done by one of the ciphers CryptoKit supports. In this guide, we'll use [ChaChaPoly](https://developer.apple.com/documentation/cryptokit/chachapoly), which can be three times faster than AES in mobile devices, according to [Adam Langley](https://www.imperialviolet.org/2014/02/27/tlssymmetriccrypto.html) and other researchers.

```swift
let sensitiveMessage = "The result of your test is positive".data(using: .utf8)!
let encryptedData = try! ChaChaPoly.seal(sensitiveMessage, using: symmetricKey).combined
```

The `encryptedData` can now be safely sent to our recipient.

### Step 3: Decrypting Data
To decrypt the data received, the recipient will need to derive the same symmetric key used to encrypt the data. But before it can be derived, we need the sender's public key.

```swift
let senderPublicKey = TrustedService.fetchPublicKey(of: senderIdentity)
``` 

#### Step 3.1: Deriving the Symmetric Key
To derive the symmetric key, we will perform the same process we performed in step 2.1, except now we will use the recipient's private key and the sender's public key. This will allows us to regenerate the shared secret, which can be used for the derivation of the same symmetric key.

```swift
let sharedSecret = try! privateKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                        salt: protocolSalt,
                                                        sharedInfo: Data(),
                                                        outputByteCount: 32)
```

We just shared a symmetric key between users without it ever existing outside their devices! 🤯

#### Step 3.2: Decrypting the Data with the Symmetric Key
Now we can use the symmetric key to decrypt the data.

```swift
let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedData)
let decryptedData = try! ChaChaPoly.open(sealedBox, using: symmetricKey)

let sensitiveMessage = String(data: decryptedData, encoding: .utf8)
print(sensitiveMessage) // "The result of your test is positive"
```

End-to-end encryption achieved!

### Stay tuned
The process described in this guide guarantees one thing: Encryption. This means the data encrypted for a user can only be decrypted by that user.

Not guaranteed: Authentication and Integrity. This means that you cannot know for sure that the encrypted data came from someone in particular and that it was not modified in transit. As such, you are vulnerable to some forms of [man-in-the-middle](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) attacks.

To guarantee Authentication and Integrity, we'll look into CryptoKit's capabilities of creating and verifying signatures in a future article. Stay tuned!

## Extras
### Swift Playground
I uploaded a Swift Playground to GitHub that follows roughly the same flow described in this article, minus the TrustedService. Here's a [link](https://github.com/cardoso/CryptoKitE2EE) to it. Make sure to give it a 🌟.

### Storing Private Keys Securely on the Device
Apple recommends using the device's keychain. It's explained in detail in this [guide](https://developer.apple.com/documentation/cryptokit/storing_cryptokit_keys_in_the_keychain).

### What is Swift Crypto?
> Swift Crypto is an open-source implementation of a substantial portion of the API of Apple CryptoKit suitable for use on Linux platforms. It enables cross-platform or server applications with the advantages of CryptoKit.
> - [Swift Crypto's GitHub README](https://github.com/apple/swift-crypto#swift-crypto)

### Found any mistakes?
Though I have some industry experience with end-to-end encryption, I don't call myself an expert. Please do reach out about it at matheus@cardo.so or DM me via twitter at [@cardosodev](https://twitter.com/cardosodev).
