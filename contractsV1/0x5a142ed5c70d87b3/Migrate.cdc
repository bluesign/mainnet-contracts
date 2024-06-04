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

	import MonoCat from "../0x8529aaf64c168952/MonoCat.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Migrate{ 
	// save monocats owners address
	access(all)
	struct StroedMonoCats{ 
		access(all)
		let tokenId: UInt64
		
		access(all)
		let lastFlowOwner: Address
		
		access(all)
		let firstEthOwner: String
		
		init(tokenId: UInt64, lastFlowOwner: Address, firstEthOwner: String){ 
			self.tokenId = tokenId
			self.lastFlowOwner = lastFlowOwner
			self.firstEthOwner = firstEthOwner
		}
	}
	
	access(self)
	let collection: @{NonFungibleToken.Collection}
	
	// store
	access(self)
	let storedMonoCats: [StroedMonoCats]
	
	access(all)
	event Migrated(tokenId: UInt64, lastFlowOwner: Address, firstEthOwner: String)
	
	access(all)
	event ContractInitialized()
	
	access(TMP_ENTITLEMENT_OWNER)
	fun recycleMonoCats(tokenIds: [UInt64], acct: AuthAccount, ethAddress: String){ 
		// get user's collection
		let col = acct.borrow<&MonoCat.Collection>(from: MonoCat.CollectionStoragePath)
		if col == nil{ 
			panic("You don't have a MonoCats collection.")
		}
		
		// transfer to contract's collection
		for id in tokenIds{ 
			let nft <- (col!).withdraw(withdrawID: id)
			self.collection.deposit(token: <-nft)
			// save to store
			self.storedMonoCats.append(StroedMonoCats(tokenId: id, lastFlowOwner: acct.address, firstEthOwner: ethAddress))
			// emit event
			emit Migrated(tokenId: id, lastFlowOwner: acct.address, firstEthOwner: ethAddress)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllRetrievableMonoCatsIds(ethAddress: String): [UInt64]{ 
		let ret: [UInt64] = []
		for cat in self.storedMonoCats{ 
			if cat.firstEthOwner == ethAddress{ 
				ret.append(cat.tokenId)
			}
		}
		return ret
	}
	
	init(){ 
		self.collection <- MonoCat.createEmptyCollection(nftType: Type<@MonoCat.Collection>())
		self.storedMonoCats = []
		emit ContractInitialized()
	}
}
