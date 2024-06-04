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
contract NeoViews{ 
	access(all)
	struct StickerView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let description: String
		
		access(all)
		let rarity: UInt64
		
		access(all)
		let location: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let typeId: UInt64
		
		access(all)
		let setId: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		init(
			id: UInt64,
			name: String,
			description: String,
			thumbnailHash: String,
			rarity: UInt64,
			location: UInt64,
			edition: UInt64,
			maxEdition: UInt64,
			typeId: UInt64,
			setId: UInt64
		){ 
			self.id = id
			self.name = name
			self.thumbnailHash = thumbnailHash
			self.description = description
			self.rarity = rarity
			self.location = location
			self.edition = edition
			self.maxEdition = maxEdition
			self.typeId = typeId
			self.setId = setId
		}
	}
	
	access(all)
	struct Royalties{ 
		access(all)
		let royalties:{ String: Royalty}
		
		access(TMP_ENTITLEMENT_OWNER)
		init(royalties:{ String: Royalty}){ 
			self.royalties = royalties
		}
	}
	
	/// Since the royalty discussion has not been finalized yet we use a temporary royalty view here, we can later add an adapter to emit the propper one
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cut: UFix64
		
		init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64){ 
			self.wallet = wallet
			self.cut = cut
		}
	}
	
	access(all)
	struct ExternalDomainViewUrl{ 
		access(all)
		let url: String
		
		init(url: String){ 
			self.url = url
		}
	}
}
