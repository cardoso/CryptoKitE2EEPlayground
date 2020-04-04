import CryptoKit
import Foundation

var protocolSalt = "Hello, playground".data(using: .utf8)!


// generate key pairs
let sPrivateKey = Curve25519.KeyAgreement.PrivateKey()
let sPublicKey = sPrivateKey.publicKey


let rPrivateKey = Curve25519.KeyAgreement.PrivateKey()
let rPublicKey = rPrivateKey.publicKey

// sender derives symmetric key
let sSharedSecret = try! sPrivateKey.sharedSecretFromKeyAgreement(with: rPublicKey)
let sSymmetricKey = sSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                          salt: protocolSalt,
                                                          sharedInfo: Data(),
                                                          outputByteCount: 32)

let sSensitiveMessage = "The result of your test is positive".data(using: .utf8)!

// sender encrypts data
let encryptedData = try! ChaChaPoly.seal(sSensitiveMessage, using: sSymmetricKey).combined

// receiver derives same symmetric key
let rSharedSecret = try! rPrivateKey.sharedSecretFromKeyAgreement(with: sPublicKey)
let rSymmetricKey = rSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                          salt: protocolSalt,
                                                          sharedInfo: Data(),
                                                          outputByteCount: 32)

// receiver decrypts data
let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedData)
let decryptedData = try! ChaChaPoly.open(sealedBox, using: rSymmetricKey)
let rSensitiveMessage = String(data: decryptedData, encoding: .utf8)!

// assertions
sSymmetricKey == rSymmetricKey
sSensitiveMessage == decryptedData
