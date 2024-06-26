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

	import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FIND from "./FIND.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FindVerifier{ 
	access(all)
	struct interface Verifier{ 
		access(all)
		let description: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool
	}
	
	access(all)
	struct HasOneFLOAT: Verifier{ 
		access(all)
		let floatEventIds: [UInt64]
		
		access(all)
		let description: String
		
		init(_ floatEventIds: [UInt64]){ 
			pre{ 
				floatEventIds.length > 0:
					"list cannot be empty"
			}
			self.floatEventIds = floatEventIds
			var desc = "User with one of these FLOATs are verified : "
			for floatEventId in floatEventIds{ 
				desc = desc.concat(floatEventId.toString()).concat(", ")
			}
			desc = desc.slice(from: 0, upTo: desc.length - 2)
			self.description = desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			if self.floatEventIds.length == 0{ 
				return true
			}
			let user: Address = param["address"]! as! Address
			let float = getAccount(user).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>()
			if float == nil{ 
				return false
			}
			let floatsCollection = float!
			for eventId in self.floatEventIds{ 
				let ids = floatsCollection.ownedIdsFromEvent(eventId: eventId)
				if ids.length > 0{ 
					return true
				}
			}
			return false
		}
	}
	
	access(all)
	struct HasAllFLOAT: Verifier{ 
		access(all)
		let floatEventIds: [UInt64]
		
		access(all)
		let description: String
		
		init(_ floatEventIds: [UInt64]){ 
			pre{ 
				floatEventIds.length > 0:
					"list cannot be empty"
			}
			self.floatEventIds = floatEventIds
			var desc = "User with all of these FLOATs are verified : "
			for floatEventId in floatEventIds{ 
				desc = desc.concat(floatEventId.toString()).concat(", ")
			}
			desc = desc.slice(from: 0, upTo: desc.length - 2)
			self.description = desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			if self.floatEventIds.length == 0{ 
				return true
			}
			let user: Address = param["address"]! as! Address
			let float = getAccount(user).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>()
			if float == nil{ 
				return false
			}
			let floatsCollection = float!
			let checked: [UInt64] = []
			for eventId in self.floatEventIds{ 
				let ids = floatsCollection.ownedIdsFromEvent(eventId: eventId)
				if ids.length > 0{ 
					checked.append(ids[0])
				}
			}
			if checked.length == self.floatEventIds.length{ 
				return true
			}
			return false
		}
	}
	
	access(all)
	struct IsInWhiteList: Verifier{ 
		access(all)
		let addressList: [Address]
		
		access(all)
		let description: String
		
		init(_ addressList: [Address]){ 
			pre{ 
				addressList.length > 0:
					"list cannot be empty"
			}
			self.addressList = addressList
			var desc = "Only these wallet addresses are verified : "
			for addr in addressList{ 
				desc = desc.concat(addr.toString()).concat(", ")
			}
			desc = desc.slice(from: 0, upTo: desc.length - 2)
			self.description = desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			let user: Address = param["address"]! as! Address
			return self.addressList.contains(user)
		}
	}
	
	// Has Find Name 
	access(all)
	struct HasFINDName: Verifier{ 
		access(all)
		let findNames: [String]
		
		access(all)
		let description: String
		
		init(_ findNames: [String]){ 
			pre{ 
				findNames.length > 0:
					"list cannot be empty"
			}
			self.findNames = findNames
			var desc = "Users with one of these find names are verified : "
			for name in findNames{ 
				desc = desc.concat(name.concat(", "))
			}
			desc = desc.slice(from: 0, upTo: desc.length - 2)
			self.description = desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			if self.findNames.length == 0{ 
				return true
			}
			let user: Address = param["address"]! as! Address
			let cap = getAccount(user).capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
			if !cap.check(){ 
				return false
			}
			let ref = cap.borrow()!
			let names = ref.getLeases()
			var longerArray = self.findNames
			var shorterArray = names
			if shorterArray.length > longerArray.length{ 
				longerArray = names
				shorterArray = self.findNames
			}
			for name in shorterArray{ 
				if longerArray.contains(name){ 
					return true
				}
			}
			return false
		}
	}
	
	// Has a no. of NFTs in given path 
	access(all)
	struct HasNFTsInPath: Verifier{ 
		access(all)
		let path: PublicPath
		
		access(all)
		let threshold: Int
		
		access(all)
		let description: String
		
		init(path: PublicPath, threshold: Int){ 
			pre{ 
				threshold > 0:
					"threshold should be greater than zero"
			}
			self.path = path
			self.threshold = threshold
			var desc = "Users with at least ".concat(threshold.toString()).concat(" nos. of NFT in path ".concat(path.toString()).concat(" are verified"))
			self.description = desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			if self.threshold == 0{ 
				return true
			}
			let user: Address = param["address"]! as! Address
			let cap = getAccount(user).capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.path)
			if !cap.check(){ 
				let mvCap = getAccount(user).capabilities.get<&{ViewResolver.ResolverCollection}>(self.path)
				if !mvCap.check(){ 
					return false
				}
				return (mvCap.borrow()!).getIDs().length >= self.threshold
			}
			return (cap.borrow()!).getIDs().length >= self.threshold
		}
	}
	
	// Has given NFTs in given path with rarity  (can cache this with uuid) 
	access(all)
	struct HasNFTWithRarities: Verifier{ 
		access(all)
		let path: PublicPath
		
		access(all)
		let rarities: [MetadataViews.Rarity]
		
		access(self)
		let rarityIdentifiers: [String]
		
		access(all)
		let description: String
		
		// leave this here for caching in case useful, but people might be able to change rarity
		access(self)
		let cache:{ UInt64: Bool}
		
		init(path: PublicPath, rarities: [MetadataViews.Rarity]){ 
			pre{ 
				rarities.length > 0:
					"list cannot be empty"
			}
			self.path = path
			self.rarities = rarities
			let rarityIdentifiers: [String] = []
			var rarityDesc = ""
			for r in rarities{ 
				var rI = r.description ?? ""
				if r.description != nil{ 
					rarityDesc = rarityDesc.concat("description : ".concat(r.description!).concat(", "))
				}
				if r.score != nil{ 
					rI = rI.concat((r.score!).toString())
					rarityDesc = rarityDesc.concat("score : ".concat((r.score!).toString()).concat(", "))
				} else{ 
					rI = rI.concat(" ")
				}
				if r.max != nil{ 
					rI = rI.concat((r.max!).toString())
					rarityDesc = rarityDesc.concat("max score : ".concat((r.max!).toString()).concat(", "))
				} else{ 
					rI = rI.concat(" ")
				}
				if rI == "  "{ 
					panic("Rarity cannot be all nil")
				}
				rarityDesc = rarityDesc.slice(from: 0, upTo: rarityDesc.length - 2).concat("; ")
				rarityIdentifiers.append(rI)
			}
			self.rarityIdentifiers = rarityIdentifiers
			self.cache ={} 
			var desc = "Users with at least 1 NFT in path ".concat(path.toString()).concat(" with one of these rarities are verified : ").concat(rarityDesc)
			self.description = desc
		}
		
		access(self)
		fun rarityToIdentifier(_ r: MetadataViews.Rarity): String{ 
			var rI = r.description ?? ""
			if r.score != nil{ 
				rI = rI.concat((r.score!).toString())
			}
			if r.max != nil{ 
				rI = rI.concat((r.max!).toString())
			}
			return rI
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ param:{ String: AnyStruct}): Bool{ 
			if self.rarities.length == 0{ 
				return true
			}
			let user: Address = param["address"]! as! Address
			let mvCap = getAccount(user).capabilities.get<&{ViewResolver.ResolverCollection}>(self.path)
			if !mvCap.check(){ 
				return false
			}
			let ref = mvCap.borrow()!
			for id in ref.getIDs(){ 
				let resolver = ref.borrowViewResolver(id: id)!
				if let r = MetadataViews.getRarity(resolver){ 
					if self.rarityIdentifiers.contains(self.rarityToIdentifier(r)){ 
						return true
					}
				}
			}
			return false
		}
	}
}
