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

	import NFTStorefrontV2 from "./../../standardsV1/NFTStorefrontV2.cdc"

access(all)
contract FlowtyStorefront{ 
	access(all)
	fun getStorefrontRef(owner: Address): &NFTStorefrontV2.Storefront{ 
		return getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
			NFTStorefrontV2.StorefrontPublicPath
		).borrow()
		?? panic("Could not borrow public storefront from address")
	}
	
	access(all)
	fun getStorefrontRefSafe(owner: Address): &NFTStorefrontV2.Storefront?{ 
		return getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
			NFTStorefrontV2.StorefrontPublicPath
		).borrow()
	}
}
