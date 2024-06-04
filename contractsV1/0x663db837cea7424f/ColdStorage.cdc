/*
This tool adds a new entitlemtent called TMP_ENTITLEMENT_OWNER to some functions that it cannot be sure if it is safe to make access(all)
those functions you should check and update their entitlemtents ( or change to all access )

Please see: 
https://cadence-lang.org/docs/cadence-migration-guide/nft-guide#update-all-pub-access-modfiers

IMPORTANT SECURITY NOTICE
Please familiarize yourself with the new entitlements feature because it is extremely important for you to understand in order to build safe smart contracts.
If you change pub to access(all) without paying attention to potential downcasting from public interfaces, you might expose private functions like withdraw 
that will cause security problems for your contract.

*/

	import Crypto

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract ColdStorage{ 
	access(all)
	struct Key{ 
		access(all)
		let publicKey: [UInt8]
		
		access(all)
		let signatureAlgorithm: UInt8
		
		access(all)
		let hashAlgorithm: UInt8
		
		init(
			publicKey: [
				UInt8
			],
			signatureAlgorithm: SignatureAlgorithm,
			hashAlgorithm: HashAlgorithm
		){ 
			self.publicKey = publicKey
			self.signatureAlgorithm = signatureAlgorithm.rawValue
			self.hashAlgorithm = hashAlgorithm.rawValue
		}
	}
	
	access(all)
	struct interface ColdStorageRequest{ 
		access(all)
		var signature: Crypto.KeyListSignature
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var spenderAddress: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun signableBytes(): [UInt8]
	}
	
	access(all)
	struct WithdrawRequest: ColdStorageRequest{ 
		access(all)
		var signature: Crypto.KeyListSignature
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var spenderAddress: Address
		
		access(all)
		var recipientAddress: Address
		
		access(all)
		var amount: UFix64
		
		init(spenderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signature: Crypto.KeyListSignature){ 
			self.spenderAddress = spenderAddress
			self.recipientAddress = recipientAddress
			self.amount = amount
			self.seqNo = seqNo
			self.signature = signature
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun signableBytes(): [UInt8]{ 
			let spenderAddress = self.spenderAddress.toBytes()
			let recipientAddressBytes = self.recipientAddress.toBytes()
			let amountBytes = self.amount.toBigEndianBytes()
			let seqNoBytes = self.seqNo.toBigEndianBytes()
			return spenderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
		}
	}
	
	access(all)
	resource PendingWithdrawal{ 
		access(self)
		var pendingVault: @{FungibleToken.Vault}
		
		access(self)
		var request: WithdrawRequest
		
		init(pendingVault: @{FungibleToken.Vault}, request: WithdrawRequest){ 
			self.pendingVault <- pendingVault
			self.request = request
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun _execute(fungibleTokenReceiverPath: PublicPath){ 
			var pendingVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			self.pendingVault <-> pendingVault
			let recipient = getAccount(self.request.recipientAddress)
			let receiver =
				(recipient.capabilities.get<&{FungibleToken.Receiver}>(fungibleTokenReceiverPath)!)
					.borrow()
				?? panic("Unable to borrow receiver reference for recipient")
			receiver.deposit(from: <-pendingVault)
		}
	}
	
	access(all)
	resource interface PublicVault{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getSequenceNumber(): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getKey(): Key
		
		access(TMP_ENTITLEMENT_OWNER)
		fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal
	}
	
	access(all)
	resource Vault: FungibleToken.Receiver, PublicVault{ 
		access(self)
		var address: Address
		
		access(self)
		var key: Key
		
		access(self)
		var contents: @{FungibleToken.Vault}
		
		access(self)
		var seqNo: UInt64
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			self.contents.deposit(from: <-from)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSequenceNumber(): UInt64{ 
			return self.seqNo
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): UFix64{ 
			return self.contents.balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getKey(): Key{ 
			return self.key
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal{ 
			pre{ 
				self.isValidSignature(request: request)
			}
			post{ 
				self.seqNo == request.seqNo + UInt64(1)
			}
			self.incrementSequenceNumber()
			return <-create PendingWithdrawal(pendingVault: <-self.contents.withdraw(amount: request.amount), request: request)
		}
		
		access(self)
		fun incrementSequenceNumber(){ 
			self.seqNo = self.seqNo + UInt64(1)
		}
		
		access(self)
		view fun isValidSignature(request:{ ColdStorage.ColdStorageRequest}): Bool{ 
			pre{ 
				self.seqNo == request.seqNo
				self.address == request.spenderAddress
			}
			return ColdStorage.validateSignature(key: self.key, signature: request.signature, message: request.signableBytes())
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
		
		init(address: Address, key: Key, contents: @{FungibleToken.Vault}){ 
			self.key = key
			self.seqNo = UInt64(0)
			self.contents <- contents
			self.address = address
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createVault(address: Address, key: Key, contents: @{FungibleToken.Vault}): @Vault{ 
		return <-create Vault(address: address, key: key, contents: <-contents)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun validateSignature(
		key: Key,
		signature: Crypto.KeyListSignature,
		message: [
			UInt8
		]
	): Bool{ 
		let keyList = Crypto.KeyList()
		let signatureAlgorithm =
			SignatureAlgorithm(rawValue: key.signatureAlgorithm)
			?? panic("invalid signature algorithm")
		let hashAlgorithm =
			HashAlgorithm(rawValue: key.hashAlgorithm) ?? panic("invalid hash algorithm")
		keyList.add(
			PublicKey(publicKey: key.publicKey, signatureAlgorithm: signatureAlgorithm),
			hashAlgorithm: hashAlgorithm,
			weight: 1000.0
		)
		return keyList.verify(signatureSet: [signature], signedData: message)
	}
}
