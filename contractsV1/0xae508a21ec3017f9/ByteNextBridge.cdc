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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract ByteNextBridge{ 
	access(all)
	let UserStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let UserPublicPath: PublicPath
	
	access(all)
	event FungibleRequested(
		account: Address,
		tokenType: String,
		destinationChain: UInt64,
		amount: UFix64,
		recipient: String
	)
	
	access(all)
	event NonFungibleRequested(
		account: Address,
		collectionType: String,
		destinationChain: UInt64,
		ids: [
			UInt64
		],
		recipient: String
	)
	
	access(all)
	event UserFungibleVerified(account: Address, tokenType: String, amount: UFix64, hash: String)
	
	access(all)
	event UserNonFungibleVerified(
		account: Address,
		collectionType: String,
		ids: [
			UInt64
		],
		hash: String
	)
	
	access(all)
	event FungibleFulfilled(account: Address, tokenType: String, amount: UFix64)
	
	access(all)
	event NonFungibleFulfilled(account: Address, collectionType: String, ids: [UInt64])
	
	access(self)
	let allowedChains:{ UInt64: Bool}
	
	access(self)
	let allowedFungibleTokens:{ String: Bool}
	
	access(self)
	let allowedNonFungibleTokens:{ String: Bool}
	
	access(self)
	let chainAddressLengths:{ UInt64: UInt64}
	
	access(self)
	let addedHashes:{ String: Bool}
	
	access(self)
	var feeTokenType: String
	
	access(self)
	let nonFungibleFees:{ UInt64: UFix64}
	
	access(self)
	var maxNftCountPerTransaction: UInt64
	
	access(self)
	var feeTokenReceiver: Capability<&{FungibleToken.Receiver}>?
	
	access(self)
	let fungibleTokenReceiver:{ String: Capability<&{FungibleToken.Receiver}>}
	
	access(self)
	let nonFungibleTokenReceiver:{ String: Capability<&{NonFungibleToken.Receiver}>}
	
	access(all)
	resource interface BridgeStorePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun verifyFungibleForUser(tokens: @{FungibleToken.Vault}, hash: String): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verifyNonFungibleForUser(collection: @{NonFungibleToken.Collection}, hash: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserFungibleBalance(tokenType: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserNonFungibleIds(collectionType: String): [UInt64]
	}
	
	access(all)
	resource BridgeStore: BridgeStorePublic{ 
		access(self)
		let userVaults: @{String:{ FungibleToken.Vault}}
		
		access(self)
		let userCollections: @{String:{ NonFungibleToken.Collection}}
		
		init(){ 
			self.userVaults <-{} 
			self.userCollections <-{} 
		}
		
		/**
				User call this function to bridge their tokens to `destinationChain`
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositFungible(destinationChain: UInt64, tokens: @{FungibleToken.Vault}, recipient: String){ 
			pre{ 
				ByteNextBridge.allowedChains[destinationChain] == true:
					"Destination chain is not supported"
				ByteNextBridge.chainAddressLengths[destinationChain] == UInt64(recipient.length):
					"recipient addres is invalid length"
				tokens.balance > 0.0:
					"amount to be bridge is zero"
			}
			let owner = self.owner ?? panic("owner is nil")
			var tokenAmount = tokens.balance
			var tokenType = self.getTokenType(type: tokens.getType())
			if !ByteNextBridge.isAllowedFungibleToken(tokenType: tokenType){ 
				panic("Token type is not supported")
			}
			let fungibleTokenReceiver = ByteNextBridge.fungibleTokenReceiver[tokenType] ?? panic("fungibleTokenReceiver has not been configured")
			//Transfer tokens to platform account
			let receiverRef = fungibleTokenReceiver.borrow() ?? panic("Can not borrow fungibleTokenReceiver")
			receiverRef.deposit(from: <-tokens)
			emit FungibleRequested(account: owner.address, tokenType: tokenType, destinationChain: destinationChain, amount: tokenAmount, recipient: recipient)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositNonFungible(destinationChain: UInt64, collection: @{NonFungibleToken.Collection}, feeTokens: @{FungibleToken.Vault}, recipient: String){ 
			pre{ 
				ByteNextBridge.allowedChains[destinationChain] == true:
					"Destination chain is not supported"
				ByteNextBridge.chainAddressLengths[destinationChain] == UInt64(recipient.length):
					"recipient addres is invalid length"
				collection.getIDs().length > 0:
					"There is no NFT to bridge"
				ByteNextBridge.nonFungibleTokenReceiver != nil:
					"nonFungibleTokenReceiver is not configured"
			}
			let owner = self.owner ?? panic("owner is nil")
			var collectionType: String = self.getTokenType(type: collection.getType())
			if !ByteNextBridge.isAllowedNonFungibleToken(collectionType: collectionType){ 
				panic("NFT type is not supported")
			}
			if ByteNextBridge.nonFungibleFees[destinationChain] != nil && ByteNextBridge.nonFungibleFees[destinationChain]! > 0.0{ 
				if feeTokens.balance != ByteNextBridge.nonFungibleFees[destinationChain]!{ 
					panic("Fee is invalid")
				}
				if feeTokens.getType().identifier != ByteNextBridge.feeTokenType{ 
					panic("Invalid fee token type")
				}
				if ByteNextBridge.feeTokenReceiver == nil{ 
					panic("feeTokenReceiver has not been configured yet")
				}
				let receiverRef = (ByteNextBridge.feeTokenReceiver!).borrow() ?? panic("Can not borrow feeTokenReceiver reference")
				(receiverRef!).deposit(from: <-feeTokens)
			} else{ 
				if feeTokens.balance > 0.0{ 
					panic("feeTokens has tokens")
				}
				destroy feeTokens
			}
			let ids = collection.getIDs()
			let nonFungibleTokenReceiver = ByteNextBridge.nonFungibleTokenReceiver[collectionType] ?? panic("nonFungibleTokenReceiver has not been configured")
			//Burn NFT
			let receiverRef = nonFungibleTokenReceiver.borrow() ?? panic("Can not borrow nonFungibleTokenReceiver")
			for id in ids{ 
				receiverRef.deposit(token: <-collection.withdraw(withdrawID: id))
			}
			destroy collection
			emit NonFungibleRequested(account: owner.address, collectionType: collectionType, destinationChain: destinationChain, ids: ids, recipient: recipient)
		}
		
		/**
				* Admins or any user can call this function to deposit specific fund for specific user
				* Normally, when a bridging is detected, admin will call this function so that user can fulfill their tokens
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verifyFungibleForUser(tokens: @{FungibleToken.Vault}, hash: String){ 
			pre{ 
				tokens.balance > 0.0:
					"Nothing to verify for user"
				ByteNextBridge.addedHashes[hash] == nil || ByteNextBridge.addedHashes[hash] == false:
					"This hash has been added before"
			}
			var tokenType = self.getTokenType(type: tokens.getType())
			var tokenAmount = tokens.balance
			//Add balance to user's vault
			self._depositBridgeVault(tokenType: tokenType, tokens: <-tokens)
			//Mark as this transaction hash has been processed to prevent duplicating
			ByteNextBridge.addedHashes[hash] = true
			emit UserFungibleVerified(account: (self.owner!).address, tokenType: tokenType, amount: tokenAmount, hash: hash)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verifyNonFungibleForUser(collection: @{NonFungibleToken.Collection}, hash: String){ 
			pre{ 
				collection.getIDs().length > 0:
					"Nothing to verify for user"
				ByteNextBridge.addedHashes[hash] == nil || ByteNextBridge.addedHashes[hash] == false:
					"This hash has been added before"
			}
			var collectionType = self.getTokenType(type: collection.getType())
			if !ByteNextBridge.isAllowedNonFungibleToken(collectionType: collectionType){ 
				panic("NFT type is not supported")
			}
			let owner = self.owner ?? panic("owner is nil")
			//Mark as this transaction hash has been processed to prevent duplicating
			ByteNextBridge.addedHashes[hash] = true
			let ids = collection.getIDs()
			self._depositNonFungible(collectionType: collectionType, collection: <-collection)
			emit UserNonFungibleVerified(account: (self.owner!).address, collectionType: collectionType, ids: ids, hash: hash)
		}
		
		/**
				User claim their tokens
				 */
		
		access(TMP_ENTITLEMENT_OWNER)
		fun fulfillFungible(tokenType: String): @{FungibleToken.Vault}{ 
			pre{ 
				self.owner != nil:
					"Owner is nil"
				self.userVaults.containsKey(tokenType):
					"tokenType is invalid or not existed"
			}
			let userVault <- self.userVaults.remove(key: tokenType)!
			if userVault.balance == 0.0{ 
				panic("Nothing for token type to fulfill")
			}
			emit FungibleFulfilled(account: (self.owner!).address, tokenType: tokenType, amount: userVault.balance)
			return <-userVault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun fulfillNonFungible(collectionType: String): @{NonFungibleToken.Collection}{ 
			pre{ 
				self.owner != nil:
					"Owner is nil"
				self.userCollections.containsKey(collectionType):
					"collectionType is invalid or not existed"
			}
			let collection <- self.userCollections.remove(key: collectionType)!
			let ids = collection.getIDs()
			if ids.length == 0{ 
				panic("Collect is empty for fulfilling")
			}
			emit NonFungibleFulfilled(account: (self.owner!).address, collectionType: collectionType, ids: ids)
			return <-collection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserFungibleBalance(tokenType: String): UFix64{ 
			if !self.userVaults.containsKey(tokenType){ 
				return 0.0
			}
			let userVault <- self.userVaults.remove(key: tokenType)!
			let balance = userVault.balance
			let emptyVault <- self.userVaults.insert(key: tokenType, <-userVault)
			destroy emptyVault
			return balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserNonFungibleIds(collectionType: String): [UInt64]{ 
			if !self.userCollections.containsKey(collectionType){ 
				return []
			}
			let collection <- self.userCollections.remove(key: collectionType)!
			let ids = collection.getIDs()
			let emptyCollection <- self.userCollections.insert(key: collectionType, <-collection)
			destroy emptyCollection
			return ids
		}
		
		access(self)
		fun getTokenType(type: Type): String{ 
			return type.identifier
		}
		
		access(self)
		fun _depositBridgeVault(tokenType: String, tokens: @{FungibleToken.Vault}){ 
			if self.userVaults.containsKey(tokenType){ 
				var oldVault: @{FungibleToken.Vault} <- self.userVaults.remove(key: tokenType)!
				tokens.deposit(from: <-oldVault)
			}
			var emptyVault <- self.userVaults.insert(key: tokenType, <-tokens)
			destroy emptyVault
		}
		
		access(self)
		fun _depositNonFungible(collectionType: String, collection: @{NonFungibleToken.Collection}){ 
			if self.userCollections.containsKey(collectionType){ 
				var oldCollection: @{NonFungibleToken.Collection} <- self.userCollections.remove(key: collectionType)!
				if oldCollection.getIDs().length > 0{ 
					for id in oldCollection.getIDs(){ 
						collection.deposit(token: <-oldCollection.withdraw(withdrawID: id))
					}
				}
				destroy oldCollection
			}
			var emptyCollection <- self.userCollections.insert(key: collectionType, <-collection)
			destroy emptyCollection
		}
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedChains(chainNumbers: [UInt64], value: Bool){ 
			pre{ 
				chainNumbers.length > 0:
					"chainNumbers is empty"
			}
			for chainNumber in chainNumbers{ 
				ByteNextBridge.allowedChains[chainNumber] = value
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setChainAddressLength(chainNumbers: [UInt64], addressLengths: [UInt64]){ 
			pre{ 
				chainNumbers.length > 0:
					"chainNumbers is empty"
				chainNumbers.length == addressLengths.length:
					"chainNumbers and addressLengths do not match"
			}
			var index = 0
			for chainNumber in chainNumbers{ 
				ByteNextBridge.chainAddressLengths[chainNumber] = addressLengths[index]
				index = index + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFeeTokenType(
			feeTokenType: String,
			feeTokenReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			ByteNextBridge.feeTokenType = feeTokenType
			ByteNextBridge.feeTokenReceiver = feeTokenReceiver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFungibleReceiver(
			tokenType: String,
			fungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			ByteNextBridge.fungibleTokenReceiver[tokenType] = fungibleTokenReceiver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setNonFungibleReceiver(
			collectionType: String,
			nonFungibleTokenReceiver: Capability<&{NonFungibleToken.Receiver}>
		){ 
			ByteNextBridge.nonFungibleTokenReceiver[collectionType] = nonFungibleTokenReceiver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFee(toChains: [UInt64], fees: [UFix64]){ 
			let count = toChains.length
			var index = 0
			while index < toChains.length{ 
				ByteNextBridge.nonFungibleFees[toChains[index]] = fees[index]
				index = index + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedFungibleToken(tokenTypes: [String], value: Bool){ 
			for tokenType in tokenTypes{ 
				ByteNextBridge.allowedFungibleTokens[tokenType] = value
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedNonFungibleToken(collectionTypes: [String], value: Bool){ 
			for collectionType in collectionTypes{ 
				ByteNextBridge.allowedNonFungibleTokens[collectionType] = value
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMaxNftCountPerTransaction(value: UInt64){ 
			ByteNextBridge.maxNftCountPerTransaction = value
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createBridgeStore(): @ByteNextBridge.BridgeStore{ 
		return <-create ByteNextBridge.BridgeStore()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isAllowedFungibleToken(tokenType: String): Bool{ 
		if self.allowedFungibleTokens.containsKey(tokenType)
		&& self.allowedFungibleTokens[tokenType] == true{ 
			return true
		}
		return false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isAllowedNonFungibleToken(collectionType: String): Bool{ 
		if self.allowedNonFungibleTokens.containsKey(collectionType)
		&& self.allowedNonFungibleTokens[collectionType] == true{ 
			return true
		}
		return false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFeeTokenType(): String{ 
		return self.feeTokenType
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFee(toChain: UInt64): UFix64{ 
		if !self.nonFungibleFees.containsKey(toChain){ 
			panic("toChain is invalid")
		}
		return self.nonFungibleFees[toChain]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMaxNftCountPerTransaction(): UInt64{ 
		return self.maxNftCountPerTransaction
	}
	
	init(){ 
		self.UserStoragePath = /storage/byteNextBridge
		self.AdminStoragePath = /storage/byteNextBridgeAdmin
		self.UserPublicPath = /public/byteNextBridge
		self.allowedChains ={} 
		self.chainAddressLengths ={} 
		self.allowedFungibleTokens ={} 
		self.allowedNonFungibleTokens ={} 
		self.addedHashes ={} 
		self.feeTokenType = ""
		self.nonFungibleFees ={} 
		self.feeTokenReceiver = nil
		self.fungibleTokenReceiver ={} 
		self.nonFungibleTokenReceiver ={} 
		self.maxNftCountPerTransaction = 50
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		self.account.storage.save(<-create BridgeStore(), to: self.UserStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&BridgeStore>(self.UserStoragePath)
		self.account.capabilities.publish(capability_1, at: self.UserPublicPath)
	}
}
