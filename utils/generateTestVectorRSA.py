from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Hash import SHA256
from eth_abi.packed import encode_packed
from eth_utils import to_bytes
from binascii import hexlify
import json

def pack_message(tradingAddress, policyId, createBefore, validUntil, cost, backdoor):
    # Convert the address to bytes
    tradingAddress_bytes = to_bytes(hexstr=tradingAddress)
    
    # Encode the values according to the specified types
    message = encode_packed(
        ['address', 'uint8', 'uint24', 'uint32', 'uint32', 'uint160', 'bytes'],
        [tradingAddress_bytes, 0, policyId, createBefore, validUntil, cost, backdoor]
    )
    return message

# Function to generate RSA key with public exponent 3
def generate_rsa_key_with_exponent_3():
    key = RSA.generate(1024, e=3)
    return key.export_key(), key.publickey().export_key()

def encode_data(tradingAddress, policyId, createBefore, validUntil, cost, backdoor):
    return pack_message(tradingAddress, policyId, createBefore, validUntil, cost, backdoor)

def sign_message(message, private_key):
    # Hash the message using SHA256
    hash_obj = SHA256.new(message)
    # Sign the message using RSA private key
    rsa_key = RSA.import_key(private_key)
    # verify this is not being hashed internally
    signature = pkcs1_15.new(rsa_key).sign(hash_obj)
    return signature

# For verification
def verify_signature(public_key, message, signature):
    rsa_key = RSA.import_key(public_key)
    hash_obj = SHA256.new(message)
    try:
        pkcs1_15.new(rsa_key).verify(hash_obj, signature)
    except (ValueError, TypeError):
        print("The signature is not valid.")

def generateVector():
    # Example usage
    tradingAddress = "0x0123456789abcDEF0123456789abCDef01234567"
    policyId = 123456
    createBefore = 1625247600
    validUntil = 1627849600
    cost = 1000000000000000000  # Example cost in wei
    backdoor = b"example_backdoor_data"

    # Generate a 1024-bit RSA key with public exponent 3 (for demonstration purposes)
    private_key, public_key = generate_rsa_key_with_exponent_3()

    # Encode the data
    encoded_message = encode_data(tradingAddress, policyId, createBefore, validUntil, cost, backdoor)

    # Sign the encoded message
    signature = sign_message(encoded_message, private_key)

    rsa_key = RSA.import_key(public_key)

    # Verify the signature (optional)
    verify_signature(public_key, encoded_message, signature)
    return {
        "tradingAddress": tradingAddress,
        "policyId": policyId,
        "createBefore": createBefore,
        "validUntil": validUntil,
        "cost": cost,
        "backdoor": "0x" + backdoor.hex(),
        "key": "0x" + hex(rsa_key.public_key().n)[2:],
        "signature": "0x" + signature.hex(),
        "expected": True
    }

def writeVectors(vectors):
    with open('test_vectors.json', "w") as f:
        f.write(json.dumps(vectors))
        
def makeVectors():
    vectors = {"vectors": [None]*100}
    for i in range(100):
        vectors["vectors"][i] = generateVector()
    return vectors

vectors = makeVectors()
writeVectors(vectors)
    
