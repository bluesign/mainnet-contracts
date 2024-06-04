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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TopShot from "./TopShot.cdc"

import Resolver from "../0xb8ea91944fd51c43/Resolver.cdc"

access(all)
contract ResolverSubedition{ 
	access(all)
	enum ResolverType: UInt8{ 
		access(all)
		case TopShotSubedition
	}
	
	access(all)
	resource OfferResolver: Resolver.ResolverPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun checkOfferResolver(item: &{NonFungibleToken.INFT, ViewResolver.Resolver}, offerParamsString:{ String: String}, offerParamsUInt64:{ String: UInt64}, offerParamsUFix64:{ String: UFix64}): Bool{ 
			if offerParamsString["resolver"] == ResolverType.TopShotSubedition.rawValue.toString(){ 
				let view = item.resolveView(Type<TopShot.TopShotMomentMetadataView>())!
				let metadata = view as! TopShot.TopShotMomentMetadataView
				let offersSubeditionId = offerParamsString["subeditionId"]
				let nftsSubeditionId = TopShot.getMomentsSubedition(nftID: item.id)
				assert(offersSubeditionId != nil, message: "subeditionId does not exist on Offer")
				assert(nftsSubeditionId != nil, message: "subeditionId does not exist on NFT")
				if offerParamsString["playId"] == metadata.playID.toString() && offerParamsString["setId"] == metadata.setID.toString() && offersSubeditionId! == (nftsSubeditionId!).toString(){ 
					return true
				}
			} else{ 
				panic("Invalid Resolver on Offer")
			}
			return false
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createResolver(): @OfferResolver{ 
		return <-create OfferResolver()
	}
}
