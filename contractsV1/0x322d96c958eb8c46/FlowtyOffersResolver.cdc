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

import Resolver from "../0xb8ea91944fd51c43/Resolver.cdc"

access(all)
contract FlowtyOffersResolver{ 
	access(all)
	let PublicPath: PublicPath
	
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	enum ResolverType: UInt8{ 
		access(all)
		case NFT
		
		access(all)
		case Global
	}
	
	access(all)
	resource OfferResolver: Resolver.ResolverPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun checkOfferResolver(item: &{NonFungibleToken.INFT, ViewResolver.Resolver}, offerParamsString:{ String: String}, offerParamsUInt64:{ String: UInt64}, offerParamsUFix64:{ String: UFix64}): Bool{ 
			if let expiry = offerParamsUInt64["expiry"]{ 
				assert(expiry > UInt64(getCurrentBlock().timestamp), message: "offer is expired")
			}
			switch offerParamsString["resolver"]!{ 
				case ResolverType.NFT.rawValue.toString():
					assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
					return true
				case ResolverType.Global.rawValue.toString():
					assert(item.getType().identifier == offerParamsString["nftType"], message: "item NFT does not have specified type")
					return true
				default:
					panic("Invalid Resolver on Offer: ".concat(offerParamsString["resolver"] ?? "unknown"))
			}
			return false
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createResolver(): @OfferResolver{ 
		return <-create OfferResolver()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getResolverCap(): Capability<&FlowtyOffersResolver.OfferResolver>{ 
		return self.account.capabilities.get<&FlowtyOffersResolver.OfferResolver>(
			FlowtyOffersResolver.PublicPath
		)!
	}
	
	init(){ 
		let p = "OffersResolver".concat(self.account.address.toString())
		self.PublicPath = PublicPath(identifier: p)!
		self.StoragePath = StoragePath(identifier: p)!
		let resolver <- create OfferResolver()
		self.account.storage.save(<-resolver, to: self.StoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&FlowtyOffersResolver.OfferResolver>(
				self.StoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.PublicPath)
	}
}
