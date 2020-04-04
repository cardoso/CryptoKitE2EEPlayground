# CryptoKit Basics: End-to-End Encryption


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

Continue reading at https://dev.to/cardoso/cryptokit-basics-end-to-end-encryption-1d6d
