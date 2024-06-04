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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AvatarArtTransactionInfo{ 
	access(self)
	var acceptCurrencies: [Type]
	
	access(all)
	let FeeInfoStoragePath: StoragePath
	
	access(all)
	let FeeInfoPublicPath: PublicPath
	
	access(all)
	let TransactionAddressStoragePath: StoragePath
	
	access(all)
	let TransactionAddressPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event FeeUpdated(
		tokenId: UInt64,
		affiliate: UFix64,
		storing: UFix64,
		insurance: UFix64,
		contractor: UFix64,
		platform: UFix64,
		author: UFix64
	)
	
	access(all)
	event TransactionAddressUpdated(
		tokenId: UInt64,
		storing: Address?,
		insurance: Address?,
		contractor: Address?,
		platform: Address?,
		author: Address?
	)
	
	access(all)
	struct FeeInfoItem{ 
		access(all)
		let affiliate: UFix64
		
		access(all)
		let storing: UFix64
		
		access(all)
		let insurance: UFix64
		
		access(all)
		let contractor: UFix64
		
		access(all)
		let platform: UFix64
		
		access(all)
		let author: UFix64
		
		// initializer
		init(
			_affiliate: UFix64,
			_storing: UFix64,
			_insurance: UFix64,
			_contractor: UFix64,
			_platform: UFix64,
			_author: UFix64
		){ 
			self.affiliate = _affiliate
			self.storing = _storing
			self.insurance = _insurance
			self.contractor = _contractor
			self.platform = _platform
			self.author = _author
		}
	}
	
	access(all)
	resource interface PublicFeeInfo{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getFee(tokenId: UInt64): AvatarArtTransactionInfo.FeeInfoItem?
	}
	
	access(all)
	resource FeeInfo: PublicFeeInfo{ 
		//Store fee for each NFT
		access(all)
		var fees:{ UInt64: FeeInfoItem}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFee(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64){ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			self.fees[tokenId] = FeeInfoItem(_affiliate: affiliate, _storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform, _author: author)
			emit FeeUpdated(tokenId: tokenId, affiliate: affiliate, storing: storing, insurance: insurance, contractor: contractor, platform: platform, author: author)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFee(tokenId: UInt64): FeeInfoItem?{ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			return self.fees[tokenId]
		}
		
		// initializer
		init(){ 
			self.fees ={} 
		}
	}
	
	// destructor
	access(all)
	struct TransactionRecipientItem{ 
		access(all)
		let storing: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let insurance: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let contractor: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let platform: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let author: Capability<&{FungibleToken.Receiver}>?
		
		// initializer
		init(
			_storing: Capability<&{FungibleToken.Receiver}>?,
			_insurance: Capability<&{FungibleToken.Receiver}>?,
			_contractor: Capability<&{FungibleToken.Receiver}>?,
			_platform: Capability<&{FungibleToken.Receiver}>?,
			_author: Capability<&{FungibleToken.Receiver}>?
		){ 
			self.storing = _storing
			self.insurance = _insurance
			self.contractor = _contractor
			self.platform = _platform
			self.author = _author
		}
	}
	
	access(all)
	resource interface PublicTransactionAddress{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(
			tokenId: UInt64,
			payType: Type
		): AvatarArtTransactionInfo.TransactionRecipientItem?
	}
	
	access(all)
	resource TransactionAddress: PublicTransactionAddress{ 
		//Store fee for each NFT
		// map tokenID => { payTypeIdentifier => TransactionRecipientItem }
		access(all)
		var addresses:{ UInt64:{ String: TransactionRecipientItem}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAddress(tokenId: UInt64, payType: Type, storing: Capability<&{FungibleToken.Receiver}>?, insurance: Capability<&{FungibleToken.Receiver}>?, contractor: Capability<&{FungibleToken.Receiver}>?, platform: Capability<&{FungibleToken.Receiver}>?, author: Capability<&{FungibleToken.Receiver}>?){ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			let address = self.addresses[tokenId] ??{} 
			address.insert(key: payType.identifier, TransactionRecipientItem(_storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform, _author: author))
			self.addresses[tokenId] = address
			emit TransactionAddressUpdated(tokenId: tokenId, storing: storing?.address, insurance: insurance?.address, contractor: contractor?.address, platform: platform?.address, author: author?.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(tokenId: UInt64, payType: Type): TransactionRecipientItem?{ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			if let addr = self.addresses[tokenId]{ 
				return addr[payType.identifier]
			}
			return nil
		}
		
		// initializer
		init(){ 
			self.addresses ={} 
		}
	}
	
	// destructor
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setAcceptCurrencies(types: [Type]){ 
			for type in types{ 
				assert(type.isSubtype(of: Type<@{FungibleToken.Vault}>()), message: "Should be a sub type of FungibleToken.Vault")
			}
			AvatarArtTransactionInfo.acceptCurrencies = types
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAcceptCurrentcies(): [Type]{ 
		return self.acceptCurrencies
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isCurrencyAccepted(type: Type): Bool{ 
		return self.acceptCurrencies.contains(type)
	}
	
	init(){ 
		self.acceptCurrencies = []
		self.FeeInfoStoragePath = /storage/avatarArtTransactionInfoFeeInfo04
		self.FeeInfoPublicPath = /public/avatarArtTransactionInfoFeeInfo04
		self.TransactionAddressStoragePath = /storage/avatarArtTransactionInfoRecepientAddress04
		self.TransactionAddressPublicPath = /public/avatarArtTransactionInfoRecepientAddress04
		let feeInfo <- create FeeInfo()
		self.account.storage.save(<-feeInfo, to: self.FeeInfoStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&AvatarArtTransactionInfo.FeeInfo>(
				AvatarArtTransactionInfo.FeeInfoStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: AvatarArtTransactionInfo.FeeInfoPublicPath
		)
		let transactionAddress <- create TransactionAddress()
		self.account.storage.save(<-transactionAddress, to: self.TransactionAddressStoragePath)
		var capability_2 =
			self.account.capabilities.storage.issue<&AvatarArtTransactionInfo.TransactionAddress>(
				AvatarArtTransactionInfo.TransactionAddressStoragePath
			)
		self.account.capabilities.publish(
			capability_2,
			at: AvatarArtTransactionInfo.TransactionAddressPublicPath
		)
		self.AdminStoragePath = /storage/avatarArtTransactionInfoAdmin04
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
