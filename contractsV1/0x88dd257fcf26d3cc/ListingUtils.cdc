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
contract ListingUtils{ 
	access(all)
	struct PurchaseModel{ 
		access(all)
		let listingResourceID: UInt64
		
		access(all)
		let storefrontAddress: Address
		
		access(all)
		let buyPrice: UFix64
		
		init(listingResourceID: UInt64, storefrontAddress: Address, buyPrice: UFix64){ 
			self.listingResourceID = listingResourceID
			self.storefrontAddress = storefrontAddress
			self.buyPrice = buyPrice
		}
	}
	
	access(all)
	struct ListingModel{ 
		access(all)
		let saleNFTID: UInt64
		
		access(all)
		let saleItemPrice: UFix64
		
		init(saleNFTID: UInt64, saleItemPrice: UFix64){ 
			self.saleNFTID = saleNFTID
			self.saleItemPrice = saleItemPrice
		}
	}
	
	access(all)
	struct SellItem{ 
		access(all)
		let listingId: UInt64
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let seller: Address
		
		init(listingId: UInt64, nftId: UInt64, seller: Address){ 
			self.listingId = listingId
			self.nftId = nftId
			self.seller = seller
		}
	}
}
