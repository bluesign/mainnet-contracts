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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Snapshot from "./Snapshot.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

// The `SnapshotLogic` contract is a basic implementation of the `ILogic` struct interface.
//
access(all)
contract SnapshotLogic{ 
	access(all)
	struct BasicLogic: Snapshot.ILogic{ 
		
		// This logic retrieves NFT information for
		// the Public Capability of `NonFungibleToken.CollectionPublic` and
		// the Public Capability of `TopShot.MomentCollectionPublic`.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwnedNFTs(address: Address):{ String:{ UInt64: Snapshot.NFTInfo}}{ 
			var nfts:{ String:{ UInt64: Snapshot.NFTInfo}} ={} 
			let account = getAccount(address)
			account.forEachPublic(fun (path: PublicPath, type: Type): Bool{ 
					let collection = account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(path).borrow<&{NonFungibleToken.CollectionPublic}>()
					if collection != nil{ 
						for index, id in (collection!).getIDs(){ 
							if index == 0{ 
								nfts[path.toString()] ={} 
							}
							let nft = (collection!).borrowNFT(id: id)
							(nfts[path.toString()]!).insert(key: nft.id, self.makeNFTInfo(nft: nft, path: path))
						}
						return true
					}
					let topshotCollection = account.capabilities.get<&{TopShot.MomentCollectionPublic}>(path).borrow<&{TopShot.MomentCollectionPublic}>()
					if topshotCollection != nil{ 
						for index, id in (topshotCollection!).getIDs(){ 
							if index == 0{ 
								nfts[path.toString()] ={} 
							}
							let nft = (topshotCollection!).borrowNFT(id: id)
							(nfts[path.toString()]!).insert(key: nft.id, self.makeNFTInfo(nft: nft, path: path))
						}
						return true
					}
					return true
				})
			return nfts
		}
		
		access(self)
		fun makeNFTInfo(nft: &{NonFungibleToken.NFT}, path: PublicPath): Snapshot.NFTInfo{ 
			var metadata: MetadataViews.Display? = nil
			if nft.getViews().contains(Type<MetadataViews.Display>()){ 
				metadata = nft.resolveView(Type<MetadataViews.Display>())! as? MetadataViews.Display
			}
			return Snapshot.NFTInfo(collectionPublicPath: path.toString(), nftType: nft.getType(), nftID: nft.id, metadata: metadata, extraMetadata: nil)
		}
	}
}
