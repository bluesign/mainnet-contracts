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

	import FlowtyListingCallback from "./FlowtyListingCallback.cdc"

import FlowtyViews from "./FlowtyViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
DNAHandler

A contract which contains a resource that handles listing callbacks. Depending on the stage of the listing,
a the DNAHandler will either:
	- Record the DNA of an NFT
	- Compare the DNA of an NFT with its previously recorded value
	- Remove recorded DNA (it is no longer needed)

If the FlowtyViews.DNA metadata view is not on an NFT, the initial recording of DNA will not be done.
If, on the other hand, DNA was recorded on an item and then it is found to be missing when a listing is being filled,
that listing will not be valid, as an empty DNA metadata view is not a match to a previously recorded value. This is to
handle cases of NFT collections making returning DNA optional.
*/

access(all)
contract DNAHandler{ 
	access(all)
	resource Handler: FlowtyListingCallback.Handler{ 
		access(self)
		let recordedDNA:{ UInt64: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun handle(stage: FlowtyListingCallback.Stage, listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			switch stage{ 
				case FlowtyListingCallback.Stage.Created:
					return self.handleCreate(listing: listing, nft: nft)
				case FlowtyListingCallback.Stage.Filled:
					return self.handleFilled(listing: listing, nft: nft!)
				case FlowtyListingCallback.Stage.Completed:
					return self.handleCompleted(listing: listing, nft: nft)
				case FlowtyListingCallback.Stage.Destroyed:
					return self.handleDestroyed(listing: listing, nft: nft)
			}
			return true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun validateListing(listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			var res = false
			if let n = nft{ 
				res = true
				if let prev = self.recordedDNA[listing.uuid]{ 
					let dnaTmp = (nft!).resolveView(Type<FlowtyViews.DNA>()) ?? FlowtyViews.DNA("")
					let dna = dnaTmp as! FlowtyViews.DNA
					res = dna.value == prev
				}
			}
			return res
		}
		
		access(self)
		fun handleCreate(listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			if nft == nil{ 
				return true
			}
			let dnaTmp = (nft!).resolveView(Type<FlowtyViews.DNA>())
			if dnaTmp == nil{ 
				return true
			}
			let dna = dnaTmp! as! FlowtyViews.DNA
			self.recordedDNA[listing.uuid] = dna.value
			return true
		}
		
		access(self)
		fun handleFilled(listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}): Bool{ 
			assert(self.validateListing(listing: listing, nft: nft), message: "DNA of nft does not match recorded DNA when listing was created")
			return true
		}
		
		access(self)
		fun handleCompleted(listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			if let ref = nft{ 
				if let prev = self.recordedDNA[listing.uuid]{ 
					let dnaTmp = ref.resolveView(Type<FlowtyViews.DNA>()) ?? FlowtyViews.DNA("")
					let dna = dnaTmp as! FlowtyViews.DNA
					assert(dna.value == prev, message: "DNA of nft does not match recorded DNA when listing was created")
				}
			}
			self.recordedDNA.remove(key: listing.uuid)
			return true
		}
		
		access(self)
		fun handleDestroyed(listing: &{FlowtyListingCallback.Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			self.recordedDNA.remove(key: listing.uuid)
			return true
		}
		
		init(){ 
			self.recordedDNA ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createHandler(): @Handler{ 
		return <-create Handler()
	}
}
