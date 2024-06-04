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

	// Popsycl NFT Marketplace
// Popsycl Rates contract
// Version		 : 0.0.1
// Blockchain	  : Flow www.onFlow.org
// Owner		   : Popsycl.com	
// Developer	   : RubiconFinTech.com
access(all)
contract PopsyclRates{ 
	
	// Market operator Address 
	access(all)
	var PopsyclMarketAddress: Address
	
	// Market fee percentage 
	access(all)
	var PopsyclMarketplaceFees: UFix64
	
	// creator royality
	access(all)
	var PopsyclCreatorRoyalty: UFix64
	
	/// Path where the `Configs` is stored
	access(all)
	let PopsyclStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun changeRated(newOperator: Address, marketCommission: UFix64, royality: UFix64){ 
			PopsyclRates.PopsyclMarketAddress = newOperator
			PopsyclRates.PopsyclMarketplaceFees = marketCommission
			PopsyclRates.PopsyclCreatorRoyalty = royality
		}
	}
	
	init(){ 
		self.PopsyclMarketAddress = 0x875c9668059b74db
		// 5% Popsycl Fee
		self.PopsyclMarketplaceFees = 0.05
		// 10% Royalty reward for original creater / minter for every re-sale
		self.PopsyclCreatorRoyalty = 0.1
		self.PopsyclStoragePath = /storage/PopsyclRates
		self.account.storage.save(<-create Admin(), to: self.PopsyclStoragePath)
	}
}
