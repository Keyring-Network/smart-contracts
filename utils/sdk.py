from web3 import Web3
from eth_utils import keccak
import json

class NonAdminAPI:
    def __init__(self, web3: Web3, contract_address: str, abi: str):
        self.web3 = web3
        self.contract_address = contract_address
        self.abi = json.loads(abi)
        self.contract = self.web3.eth.contract(address=self.contract_address, abi=self.abi)

    def admin(self):
        return self.contract.functions.admin().call()

    def get_key_hash(self, key: bytes) -> bytes:
        return keccak(key)

    def key_exists(self, key_hash: bytes) -> bool:
        return self.contract.functions.keyExists(key_hash).call()

    def key_valid_from(self, key_hash: bytes) -> int:
        return self.contract.functions.keyValidFrom(key_hash).call()

    def key_valid_to(self, key_hash: bytes) -> int:
        return self.contract.functions.keyValidTo(key_hash).call()

    def key_details(self, key_hash: bytes):
        return self.contract.functions.keyDetails(key_hash).call()

    def entity_blacklisted(self, policy_id: int, entity: str) -> bool:
        return self.contract.functions.entityBlacklisted(policy_id, entity).call()

    def entity_exp(self, policy_id: int, entity: str) -> int:
        return self.contract.functions.entityExp(policy_id, entity).call()

    def entity_data(self, policy_id: int, entity: str):
        return self.contract.functions.entityData(policy_id, entity).call()

    def check_credential(self, policy_id: int, entity: str) -> bool:
        return self.contract.functions.checkCredential(policy_id, entity).call()

    def check_two_credentials(self, policy_id: int, entity_a: str, entity_b: str) -> bool:
        return self.contract.functions.checkCredential(policy_id, entity_a, entity_b).call()

class AdminAPI:
    def __init__(self, web3: Web3, contract_address: str, abi: str, admin_private_key: str):
        self.web3 = web3
        self.contract_address = contract_address
        self.abi = json.loads(abi)
        self.contract = self.web3.eth.contract(address=self.contract_address, abi=self.abi)
        self.admin_private_key = admin_private_key
        self.admin_address = self.web3.eth.account.privateKeyToAccount(admin_private_key).address

    def _get_nonce(self):
        """Internal method to get the pending nonce for the admin address."""
        return self.web3.eth.getTransactionCount(self.admin_address, block_identifier='pending')

    def create_credential(self, trading_address: str, policy_id: int, valid_from: int, valid_until: int, cost: int, key: bytes, signature: bytes, backdoor: bytes):
        txn = self.contract.functions.createCredential(
            trading_address,
            policy_id,
            valid_from,
            valid_until,
            cost,
            key,
            signature,
            backdoor
        ).buildTransaction({
            'from': self.admin_address,
            'value': self.web3.toWei(cost, 'wei'),
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def set_admin(self, new_admin: str):
        txn = self.contract.functions.setAdmin(new_admin).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def register_key(self, valid_from: int, valid_to: int, key: bytes):
        txn = self.contract.functions.registerKey(valid_from, valid_to, key).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def revoke_key(self, key_hash: bytes):
        txn = self.contract.functions.revokeKey(key_hash).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def blacklist_entity(self, policy_id: int, entity: str):
        txn = self.contract.functions.blacklistEntity(policy_id, entity).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def unblacklist_entity(self, policy_id: int, entity: str):
        txn = self.contract.functions.unblacklistEntity(policy_id, entity).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

    def collect_fees(self, to: str):
        txn = self.contract.functions.collectFees(to).buildTransaction({
            'from': self.admin_address,
            'nonce': self._get_nonce()
        })
        signed_txn = self.web3.eth.account.signTransaction(txn, private_key=self.admin_private_key)
        txn_hash = self.web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        return self.web3.eth.waitForTransactionReceipt(txn_hash)

class KeyringCoreV2SDK(NonAdminAPI, AdminAPI):
    def __init__(self, web3: Web3, contract_address: str, abi: str, admin_private_key: str = None):
        NonAdminAPI.__init__(self, web3, contract_address, abi)
        if admin_private_key:
            AdminAPI.__init__(self, web3, contract_address, abi, admin_private_key)
