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

import FindMarket from "./FindMarket.cdc"

import FindViews from "./FindViews.cdc"

import FIND from "./FIND.cdc"

access(all)
contract FindFurnace{ 
	access(all)
	event Burned(
		from: Address,
		fromName: String?,
		uuid: UInt64,
		nftInfo: FindMarket.NFTInfo,
		context:{ 
			String: String
		}
	)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun burn(pointer: FindViews.AuthNFTPointer, context:{ String: String}){ 
		if !pointer.valid(){ 
			panic("Invalid NFT Pointer. Type : ".concat(pointer.itemType.identifier).concat(" ID : ").concat(pointer.uuid.toString()))
		}
		let vr = pointer.getViewResolver()
		let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
		let owner = pointer.owner()
		emit Burned(
			from: owner,
			fromName: FIND.reverseLookup(owner),
			uuid: pointer.uuid,
			nftInfo: nftInfo,
			context: context
		)
		destroy pointer.withdraw()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun burnWithoutValidation(pointer: FindViews.AuthNFTPointer, context:{ String: String}){ 
		let vr = pointer.getViewResolver()
		let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
		let owner = pointer.owner()
		emit Burned(
			from: owner,
			fromName: FIND.reverseLookup(owner),
			uuid: pointer.uuid,
			nftInfo: nftInfo,
			context: context
		)
		destroy pointer.withdraw()
	}
}
