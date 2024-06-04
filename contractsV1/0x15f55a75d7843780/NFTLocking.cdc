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

import TopShotLocking from "../0x0b2a3299cc857e29/TopShotLocking.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import Pinnacle from "../0xedf9df96c92f4595/Pinnacle.cdc"

access(all)
contract NFTLocking{ 
	access(all)
	fun isLocked(nftRef: &{NonFungibleToken.NFT}): Bool{ 
		let type = nftRef.getType()
		if type == Type<@TopShot.NFT>(){ 
			return TopShotLocking.isLocked(nftRef: nftRef)
		}
		if type == Type<@Pinnacle.NFT>(){ 
			let pinnacleNFTRef: &Pinnacle.NFT? = nftRef as? &Pinnacle.NFT
			if pinnacleNFTRef == nil{ 
				return false
			}
			return (pinnacleNFTRef!).isLocked()
		}
		return false
	}
	
	init(){} 
}
