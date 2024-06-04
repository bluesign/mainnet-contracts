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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	Collectico interface for Basic NFTs (M of N)
	(c) CollecticoLabs.com
 */

access(TMP_ENTITLEMENT_OWNER)
contract interface CollecticoStandardNFT{ 
	
	// Interface that the Items have to conform to
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IItem{ 
		// The unique ID that each Item has
		access(all)
		let id: UInt64
	}
	
	// Requirement that all conforming smart contracts have
	// to define a resource called Item that conforms to IItem
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Item: IItem, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
	}
}
