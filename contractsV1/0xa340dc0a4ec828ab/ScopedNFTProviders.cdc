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

import StringUtils from "./../../standardsV1/StringUtils.cdc"

// ScopedNFTProviders
//
// TO AVOID RISK, PLEASE DEPLOY YOUR OWN VERSION OF THIS CONTRACT SO THAT
// MALICIOUS UPDATES ARE NOT POSSIBLE
//
// ScopedNFTProviders are meant to solve the issue of unbounded access to NFT Collections.
// A provider can be given extensible filters which allow limited access to resources based on any trait on the NFT itself.
//
// By using a scoped provider, only a subset of assets can be taken if the provider leaks
// instead of the entire nft collection.
access(all)
contract ScopedNFTProviders{ 
	access(all)
	struct interface NFTFilter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdraw(_ nft: &{NonFungibleToken.NFT}): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markWithdrawn(_ nft: &{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails():{ String: AnyStruct}
	}
	
	access(all)
	struct NFTIDFilter: NFTFilter{ 
		// the ids that are allowed to be withdrawn.
		// If ids[num] is false, the id cannot be withdrawn anymore
		access(self)
		let ids:{ UInt64: Bool}
		
		init(_ ids: [UInt64]){ 
			let d:{ UInt64: Bool} ={} 
			for i in ids{ 
				d[i] = true
			}
			self.ids = d
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdraw(_ nft: &{NonFungibleToken.NFT}): Bool{ 
			return self.ids[nft.id] != nil && self.ids[nft.id] == true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markWithdrawn(_ nft: &{NonFungibleToken.NFT}){ 
			self.ids[nft.id] = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails():{ String: AnyStruct}{ 
			return{ "ids": self.ids}
		}
	}
	
	access(all)
	struct UUIDFilter: NFTFilter{ 
		// the ids that are allowed to be withdrawn.
		// If ids[num] is false, the id cannot be withdrawn anymore
		access(self)
		let uuids:{ UInt64: Bool}
		
		init(_ uuids: [UInt64]){ 
			let d:{ UInt64: Bool} ={} 
			for i in uuids{ 
				d[i] = true
			}
			self.uuids = d
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdraw(_ nft: &{NonFungibleToken.NFT}): Bool{ 
			return self.uuids[nft.uuid] != nil && self.uuids[nft.uuid]! == true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markWithdrawn(_ nft: &{NonFungibleToken.NFT}){ 
			self.uuids[nft.uuid] = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails():{ String: AnyStruct}{ 
			return{ "uuids": self.uuids}
		}
	}
	
	// ScopedNFTProvider
	//
	// Wrapper around an NFT Provider that is restricted to specific ids.
	access(all)
	resource ScopedNFTProvider: NonFungibleToken.Provider{ 
		access(self)
		let provider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		access(self)
		let filters: [{NFTFilter}]
		
		// block timestamp that this provider can no longer be used after
		access(self)
		let expiration: UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isExpired(): Bool{ 
			if let expiration = self.expiration{ 
				return getCurrentBlock().timestamp >= expiration
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		init(provider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, filters: [{NFTFilter}], expiration: UFix64?){ 
			self.provider = provider
			self.expiration = expiration
			self.filters = filters
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdraw(_ id: UInt64): Bool{ 
			if self.isExpired(){ 
				return false
			}
			let nft = (self.provider.borrow()!).borrowNFT(id)
			if nft == nil{ 
				return false
			}
			var i = 0
			while i < self.filters.length{ 
				if !self.filters[i].canWithdraw(nft!){ 
					return false
				}
				i = i + 1
			}
			return true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun check(): Bool{ 
			return self.provider.check()
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				!self.isExpired():
					"provider has expired"
			}
			let nft <- (self.provider.borrow()!).withdraw(withdrawID: withdrawID)
			let ref = &nft as &{NonFungibleToken.NFT}
			var i = 0
			while i < self.filters.length{ 
				if !self.filters[i].canWithdraw(ref){ 
					panic(StringUtils.join(["cannot withdraw nft. filter of type", self.filters[i].getType().identifier, "failed."], " "))
				}
				self.filters[i].markWithdrawn(ref)
				i = i + 1
			}
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): [{String: AnyStruct}]{ 
			let details: [{String: AnyStruct}] = []
			for f in self.filters{ 
				details.append(f.getDetails())
			}
			return details
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createScopedNFTProvider(
		provider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
		filters: [{
			NFTFilter}
		],
		expiration: UFix64?
	): @ScopedNFTProvider{ 
		return <-create ScopedNFTProvider(
			provider: provider,
			filters: filters,
			expiration: expiration
		)
	}
}
