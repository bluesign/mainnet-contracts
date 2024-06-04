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

	access(all)
contract StarlyRoyalties{ 
	access(all)
	struct Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let cut: UFix64
		
		init(address: Address, cut: UFix64){ 
			self.address = address
			self.cut = cut
		}
	}
	
	access(all)
	var starlyRoyalty: Royalty
	
	access(contract)
	let collectionRoyalties:{ String: Royalty}
	
	access(contract)
	let minterRoyalties:{ String:{ String: Royalty}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRoyalties(collectionID: String, starlyID: String): [Royalty]{ 
		let royalties = [self.starlyRoyalty]
		if let collectionRoyalty = self.collectionRoyalties[collectionID]{ 
			royalties.append(collectionRoyalty)
		}
		if let minterRoyaltiesForCollection = self.minterRoyalties[collectionID]{ 
			if let minterRoyalty = minterRoyaltiesForCollection[starlyID]{ 
				royalties.append(minterRoyalty)
			}
		}
		return royalties
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStarlyRoyalty(): Royalty{ 
		return self.starlyRoyalty
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionRoyalty(collectionID: String): Royalty?{ 
		return self.collectionRoyalties[collectionID]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMinterRoyalty(collectionID: String, starlyID: String): Royalty?{ 
		if let minterRoyaltiesForCollection = self.minterRoyalties[collectionID]{ 
			return minterRoyaltiesForCollection[starlyID]
		}
		return nil
	}
	
	access(all)
	resource interface IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setStarlyRoyalty(address: Address, cut: UFix64): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteCollectionRoyalty(collectionID: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String)
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setStarlyRoyalty(address: Address, cut: UFix64){ 
			StarlyRoyalties.starlyRoyalty = Royalty(address: address, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64){ 
			StarlyRoyalties.collectionRoyalties.insert(key: collectionID, Royalty(address: address, cut: cut))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteCollectionRoyalty(collectionID: String){ 
			StarlyRoyalties.collectionRoyalties.remove(key: collectionID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64){ 
			if !StarlyRoyalties.minterRoyalties.containsKey(collectionID){ 
				StarlyRoyalties.minterRoyalties.insert(key: collectionID,{ starlyID: Royalty(address: address, cut: cut)})
			} else{ 
				(StarlyRoyalties.minterRoyalties[collectionID]!).insert(key: starlyID, Royalty(address: address, cut: cut))
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String){ 
			StarlyRoyalties.minterRoyalties[collectionID]?.remove(key: starlyID)
		}
	}
	
	access(all)
	resource interface EditorProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setEditorCapability(cap: Capability<&StarlyRoyalties.Editor>): Void
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
		fun setStarlyRoyalty(address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setStarlyRoyalty(address: address, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setCollectionRoyalty(collectionID: collectionID, address: address, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteCollectionRoyalty(collectionID: String){ 
			((self.editorCapability!).borrow()!).deleteCollectionRoyalty(collectionID: collectionID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setMinterRoyalty(collectionID: collectionID, starlyID: starlyID, address: address, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String){ 
			((self.editorCapability!).borrow()!).deleteMinterRoyalty(collectionID: collectionID, starlyID: starlyID)
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
		self.starlyRoyalty = Royalty(address: 0x12c122ca9266c278, cut: 0.05)
		self.collectionRoyalties ={} 
		self.minterRoyalties ={} 
		self.AdminStoragePath = /storage/starlyRoyaltiesAdmin
		self.EditorStoragePath = /storage/starlyRoyaltiesEditor
		self.EditorProxyPublicPath = /public/starlyRoyaltiesEditorProxy
		self.EditorProxyStoragePath = /storage/starlyRoyaltiesEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
	}
}
