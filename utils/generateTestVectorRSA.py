from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Hash import SHA256
from eth_abi.packed import encode_packed
from eth_utils import to_bytes
from binascii import hexlify

def pack_message(trading_address, policy_id, creat_before, valid_until, cost, backdoor):
    # Convert the address to bytes
    trading_address_bytes = to_bytes(hexstr=trading_address)
    
    # Encode the values according to the specified types
    message = encode_packed(
        ['address', 'uint8', 'uint24', 'uint32', 'uint32', 'uint160', 'bytes'],
        [trading_address_bytes, 0, policy_id, creat_before, valid_until, cost, backdoor]
    )
    print(hexlify(message))
    return message

# Function to generate RSA key with public exponent 3
def generate_rsa_key_with_exponent_3():
    key = RSA.generate(1024, e=3)
    return key.export_key(), key.publickey().export_key()

def encode_data(trading_address, policy_id, creat_before, valid_until, cost, backdoor):
    return pack_message(trading_address, policy_id, creat_before, valid_until, cost, backdoor)

def sign_message(message, private_key):
    # Hash the message using SHA256
    hash_obj = SHA256.new(message)
    # Sign the message using RSA private key
    rsa_key = RSA.import_key(private_key)
    # verify this is not being hashed internally
    signature = pkcs1_15.new(rsa_key).sign(hash_obj)
    return signature

# Example usage
trading_address = "0x0123456789abcDEF0123456789abCDef01234567"
policy_id = 123456
creat_before = 1625247600
valid_until = 1627849600
cost = 1000000000000000000  # Example cost in wei
backdoor = b"example_backdoor_data"

# Generate a 1024-bit RSA key with public exponent 3 (for demonstration purposes)
private_key, public_key = generate_rsa_key_with_exponent_3()

# Encode the data
encoded_message = encode_data(trading_address, policy_id, creat_before, valid_until, cost, backdoor)

# Sign the encoded message
signature = sign_message(encoded_message, private_key)

rsa_key = RSA.import_key(public_key)

# Print all properly encoded data
print(f"Trading Address: {trading_address}")
print(f"Policy ID: {policy_id}")
print(f"Create Before: {creat_before}")
print(f"Valid Until: {valid_until}")
print(f"Cost: {cost}")
print(f"Backdoor: {backdoor.hex()}")
print(f"Encoded Message: {encoded_message.hex()}")
print(f"Key: {hex(rsa_key.public_key().n)[2:]}")
print(f"Signature: {signature.hex()}")

# For verification (optional)
def verify_signature(public_key, message, signature):
    rsa_key = RSA.import_key(public_key)
    hash_obj = SHA256.new(message)
    try:
        pkcs1_15.new(rsa_key).verify(hash_obj, signature)
        print("The signature is valid.")
    except (ValueError, TypeError):
        print("The signature is not valid.")

# Verify the signature (optional)
verify_signature(public_key, encoded_message, signature)
