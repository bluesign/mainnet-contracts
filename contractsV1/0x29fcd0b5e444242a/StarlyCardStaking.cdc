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

import StarlyIDParser from "../0x5b82f21c0edf76e3/StarlyIDParser.cdc"

import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"

import StarlyMetadataViews from "../0x5b82f21c0edf76e3/StarlyMetadataViews.cdc"

access(all)
contract StarlyCardStaking{ 
	access(all)
	struct CollectionData{ 
		access(all)
		let editions:{ String: UFix64}
		
		init(editions:{ String: UFix64}){ 
			self.editions = editions
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRemainingResource(starlyID: String, remainingResource: UFix64){ 
			self.editions.insert(key: starlyID, remainingResource)
		}
	}
	
	access(contract)
	var collections:{ String: CollectionData}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRemainingResource(collectionID: String, starlyID: String): UFix64?{ 
		if let collection = StarlyCardStaking.collections[collectionID]{ 
			return collection.editions[starlyID]
		} else{ 
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRemainingResourceWithDefault(starlyID: String): UFix64{ 
		let metadata =
			StarlyMetadata.getCardEdition(starlyID: starlyID) ?? panic("Missing metadata")
		let collectionID = metadata.collection.id
		let initialResource = metadata.score ?? 0.0
		return StarlyCardStaking.getRemainingResource(
			collectionID: collectionID,
			starlyID: starlyID
		)
		?? initialResource
	}
	
	access(all)
	resource interface IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setRemainingResource(
			collectionID: String,
			starlyID: String,
			remainingResource: UFix64
		): Void
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setRemainingResource(collectionID: String, starlyID: String, remainingResource: UFix64){ 
			if let collection = StarlyCardStaking.collections[collectionID]{ 
				(StarlyCardStaking.collections[collectionID]!).setRemainingResource(starlyID: starlyID, remainingResource: remainingResource)
			} else{ 
				StarlyCardStaking.collections.insert(key: collectionID, CollectionData(editions:{ starlyID: remainingResource}))
			}
		}
	}
	
	access(all)
	resource interface EditorProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setEditorCapability(cap: Capability<&StarlyCardStaking.Editor>): Void
	}
	
	access(all)
	resource EditorProxy: IEditor, EditorProxyPublic{ 
		access(self)
		var editorCapability: Capability<&Editor>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setEditorCapability(cap: Capability<&Editor>){ 
			self.editorCapability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRemainingResource(collectionID: String, starlyID: String, remainingResource: UFix64){ 
			((self.editorCapability!).borrow()!).setRemainingResource(collectionID: collectionID, starlyID: starlyID, remainingResource: remainingResource)
		}
		
		init(){ 
			self.editorCapability = nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEditorProxy(): @EditorProxy{ 
		return <-create EditorProxy()
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewEditor(): @Editor{ 
			return <-create Editor()
		}
	}
	
	init(){ 
		self.collections ={} 
		self.AdminStoragePath = /storage/starlyCardStakingAdmin
		self.EditorStoragePath = /storage/starlyCardStakingEditor
		self.EditorProxyPublicPath = /public/starlyCardStakingEditorProxy
		self.EditorProxyStoragePath = /storage/starlyCardStakingEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
	}
}
