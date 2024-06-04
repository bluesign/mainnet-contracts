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

	/*
	Description: Contract for SportsIcon management of primary sale listings
*/

import SportsIconNFTStorefront from "../0x03c8261a06cb1b42/SportsIconNFTStorefront.cdc"

access(all)
contract SportsIconPrimarySalePrices{ 
	access(all)
	struct PrimarySaleListing{ 
		access(all)
		let totalPrice: UFix64
		
		access(self)
		let saleCuts: [SportsIconNFTStorefront.SaleCut]
		
		init(totalPrice: UFix64, saleCuts: [SportsIconNFTStorefront.SaleCut]){ 
			self.totalPrice = totalPrice
			assert(
				saleCuts.length > 0,
				message: "Listing must have at least one payment cut recipient"
			)
			self.saleCuts = saleCuts
			var salePrice = 0.0
			for cut in self.saleCuts{ 
				cut.receiver.borrow() ?? panic("Cannot borrow receiver")
				salePrice = salePrice + cut.amount
			}
			assert(salePrice >= 0.0, message: "Listing must have non-negative price")
			assert(
				salePrice == totalPrice,
				message: "Cuts do not line up to stored total price of listing."
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleCuts(): [SportsIconNFTStorefront.SaleCut]{ 
			return self.saleCuts
		}
	}
	
	// Mapping of SportsIcon SetID to FungibleTokenType to Price
	access(self)
	let primarySalePrices:{ UInt64:{ String: PrimarySaleListing}}
	
	access(account)
	fun updateSalePrice(setID: UInt64, currency: String, primarySaleListing: PrimarySaleListing?){ 
		if self.primarySalePrices[setID] == nil{ 
			self.primarySalePrices[setID] ={} 
		}
		if primarySaleListing == nil{ 
			(self.primarySalePrices[setID]!).remove(key: currency)
		} else{ 
			(self.primarySalePrices[setID]!).insert(key: currency, primarySaleListing!)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getListing(setID: UInt64, currency: String): PrimarySaleListing?{ 
		if self.primarySalePrices[setID] == nil{ 
			return nil
		}
		if (self.primarySalePrices[setID]!)[currency] == nil{ 
			return nil
		}
		return (self.primarySalePrices[setID]!)[currency]!
	}
	
	init(){ 
		self.primarySalePrices ={} 
	}
}
