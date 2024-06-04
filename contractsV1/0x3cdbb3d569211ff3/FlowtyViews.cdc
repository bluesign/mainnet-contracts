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

	// MetadataViews used by products at Flowty
// For more information, please see our developer docs:
//
// https://docs.flowty.io/developer-docs/
access(all)
contract FlowtyViews{ 
	
	// DNA is only needed for NFTs that can change dynamically. It is used
	// to prevent an NFT from being sold that's been changed between the time of
	// making a listing, and that listing being filled.
	// 
	// If implemented, DNA is recorded when a listing is made.
	// When the same listing is being filled, the DNA will again be checked.
	// If the DNA of an item when being filled doesn't match what was recorded when
	// listed, do not permit filling the listing.
	access(all)
	struct DNA{ 
		access(all)
		let value: String
		
		init(_ value: String){ 
			self.value = value
		}
	}
}
