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

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all)
contract Resolver{ 
	// Current list of supported resolution rules.
	access(all)
	enum ResolverType: UInt8{ 
		access(all)
		case NFT
		
		access(all)
		case TopShotEdition
		
		access(all)
		case MetadataViewsEditions
	}
	
	// Public resource interface that defines a method signature for checkOfferResolver
	// which is used within the Resolver resource for offer acceptance validation
	access(all)
	resource interface ResolverPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun checkOfferResolver(
			item: &{ViewResolver.Resolver},
			offerParamsString:{ 
				String: String
			},
			offerParamsUInt64:{ 
				String: UInt64
			},
			offerParamsUFix64:{ 
				String: UFix64
			}
		): Bool
	}
	
	// Resolver resource holds the Offer exchange resolution rules.
	access(all)
	resource OfferResolver: ResolverPublic{ 
		// checkOfferResolver
		// Holds the validation rules for resolver each type of supported ResolverType
		// Function returns TRUE if the provided nft item passes the criteria for exchange
		access(TMP_ENTITLEMENT_OWNER)
		fun checkOfferResolver(item: &{NonFungibleToken.INFT, ViewResolver.Resolver}, offerParamsString:{ String: String}, offerParamsUInt64:{ String: UInt64}, offerParamsUFix64:{ String: UFix64}): Bool{ 
			if offerParamsString["resolver"] == ResolverType.NFT.rawValue.toString(){ 
				assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
				return true
			} else if offerParamsString["resolver"] == ResolverType.TopShotEdition.rawValue.toString(){ 
				// // Get the Top Shot specific metadata for this NFT
				let view = item.resolveView(Type<TopShot.TopShotMomentMetadataView>())!
				let metadata = view as! TopShot.TopShotMomentMetadataView
				if offerParamsString["playId"] == metadata.playID.toString() && offerParamsString["setId"] == metadata.setID.toString(){ 
					return true
				}
			} else if offerParamsString["resolver"] == ResolverType.MetadataViewsEditions.rawValue.toString(){ 
				if let views = item.resolveView(Type<MetadataViews.Editions>()){ 
					let editions = views as! [MetadataViews.Edition]
					var hasCorrectMetadataView = false
					for edition in editions{ 
						if edition.name == offerParamsString["editionName"]{ 
							hasCorrectMetadataView = true
						}
					}
					assert(hasCorrectMetadataView == true, message: "editionId does not exist on NFT")
					return true
				} else{ 
					panic("NFT does not use MetadataViews.Editions")
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
