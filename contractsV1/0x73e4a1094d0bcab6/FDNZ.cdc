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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FDNZ{ 
	access(all)
	fun getAccountLinks(_ account: AuthAccount, domain: String): [{String: AnyStruct}]{ 
		var res: [{String: AnyStruct}] = []
		if domain == "public"{ 
			account.forEachPublic(fun (path: PublicPath, type: Type): Bool{ 
					res.append({"path": path, "borrowType": type, "target": account.getLinkTarget(path)})
					return true
				})
		}
		if domain == "private"{ 
			account.forEachPrivate(fun (path: PrivatePath, type: Type): Bool{ 
					res.append({"path": path, "borrowType": type, "target": account.getLinkTarget(path)})
					return true
				})
		}
		return res
	}
	
	access(all)
	fun getAccountStorageNFT(_ account: AuthAccount, path: String, uuid: UInt64): AnyStruct{ 
		var obj = account.borrow<&AnyResource>(from: StoragePath(identifier: path)!)!
		var meta = obj as? &{ViewResolver.ResolverCollection}
		var res:{ String: AnyStruct} ={} 
		var vr = meta?.borrowViewResolver(id: uuid)!
		if let views = vr?.getViews(){ 
			for mdtype in views{ 
				if mdtype == Type<MetadataViews.NFTView>(){ 
					continue
				}
				if mdtype == Type<MetadataViews.NFTCollectionData>(){ 
					continue
				}
				res[mdtype.identifier] = vr?.resolveView(mdtype)
			}
		}
		return res
	}
	
	access(all)
	fun getAccountStorageRaw(_ account: AuthAccount, path: String): AnyStruct{ 
		var obj = account.borrow<&AnyResource>(from: StoragePath(identifier: path)!)!
		return obj
	}
	
	access(all)
	fun getAccountStorage(_ account: AuthAccount, path: String): AnyStruct{ 
		var obj = account.borrow<&AnyResource>(from: StoragePath(identifier: path)!)!
		var meta = obj as? &{ViewResolver.ResolverCollection}
		if meta != nil && (meta!).getIDs().length > 0{ 
			var res:{ UInt64: AnyStruct} ={} 
			for id in (meta!).getIDs(){ 
				res[id] = (meta!).borrowViewResolver(id: id).resolveView(Type<MetadataViews.Display>())!
			}
			return res
		} else{ 
			var col = account.borrow<&AnyResource>(from: StoragePath(identifier: path)!)! as AnyStruct
			return col
		}
	}
	
	access(all)
	fun getAccountData(_ account: AuthAccount):{ String: AnyStruct}{ 
		var paths: [Path] = []
		var privatePaths: [Path] = []
		var publicPaths: [Path] = []
		var nft: [AnyStruct] = []
		var ft: [AnyStruct] = []
		account.forEachStored(fun (path: StoragePath, type: Type): Bool{ 
				if type.isSubtype(of: Type<@{NonFungibleToken.Collection}>()){ 
					var collection = account.borrow<&NonFungibleToken.Collection>(from: path)!
					nft.append({"path": path, "count": collection.ownedNFTs.length})
					paths.append(path)
				} else if type.isSubtype(of: Type<@{FungibleToken.Vault}>()){ 
					var vault = account.borrow<&FungibleToken.Vault>(from: path)!
					ft.append({"path": path, "balance": vault.balance})
					paths.append(path)
				} else{ 
					paths.append(path)
				}
				return true
			})
		account.forEachPublic(fun (path: PublicPath, type: Type): Bool{ 
				publicPaths.append(path)
				return true
			})
		account.forEachPrivate(fun (path: PrivatePath, type: Type): Bool{ 
				privatePaths.append(path)
				return true
			})
		let response:{ String: AnyStruct} ={} 
		
		//find profile
		var findProfile = account.borrow<&AnyResource>(from: /storage/findProfile)
		response["find"] = findProfile
		response["capacity"] = account.storageCapacity
		response["used"] = account.storageUsed
		response["available"] = 0
		response["paths"] = paths
		response["public"] = publicPaths
		response["private"] = privatePaths
		response["nft"] = nft
		response["ft"] = ft
		if account.storageCapacity > account.storageUsed{ 
			response["available"] = account.storageCapacity - account.storageUsed
		}
		return response
	}
}
