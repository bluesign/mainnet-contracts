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

	access(all)
contract HoodlumsMetadata{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event MetadataSetted(tokenID: UInt64, metadata:{ String: String})
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	let metadata:{ UInt64:{ String: String}}
	
	access(all)
	var sturdyRoyaltyAddress: Address
	
	access(all)
	var artistRoyaltyAddress: Address
	
	access(all)
	var sturdyRoyaltyCut: UFix64
	
	access(all)
	var artistRoyaltyCut: UFix64
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadata(tokenID: UInt64, metadata:{ String: String}){ 
			HoodlumsMetadata.metadata[tokenID] = metadata
			emit MetadataSetted(tokenID: tokenID, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSturdyRoyaltyAddress(sturdyRoyaltyAddress: Address){ 
			HoodlumsMetadata.sturdyRoyaltyAddress = sturdyRoyaltyAddress
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArtistRoyaltyAddress(artistRoyaltyAddress: Address){ 
			HoodlumsMetadata.artistRoyaltyAddress = artistRoyaltyAddress
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSturdyRoyaltyCut(sturdyRoyaltyCut: UFix64){ 
			HoodlumsMetadata.sturdyRoyaltyCut = sturdyRoyaltyCut
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArtistRoyaltyCut(artistRoyaltyCut: UFix64){ 
			HoodlumsMetadata.artistRoyaltyCut = artistRoyaltyCut
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadata(tokenID: UInt64):{ String: String}?{ 
		return HoodlumsMetadata.metadata[tokenID]
	}
	
	init(){ 
		self.AdminStoragePath = /storage/HoodlumsMetadataAdmin
		self.metadata ={} 
		self.sturdyRoyaltyAddress = self.account.address
		self.artistRoyaltyAddress = self.account.address
		self.sturdyRoyaltyCut = 0.05
		self.artistRoyaltyCut = 0.05
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
