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
contract FlowviewAccountBookmark{ 
	access(all)
	let AccountBookmarkCollectionStoragePath: StoragePath
	
	access(all)
	let AccountBookmarkCollectionPublicPath: PublicPath
	
	access(all)
	let AccountBookmarkCollectionPrivatePath: PrivatePath
	
	access(all)
	event AccountBookmarkAdded(owner: Address, address: Address, note: String)
	
	access(all)
	event AccountBookmarkRemoved(owner: Address, address: Address)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	resource interface AccountBookmarkPublic{ 
		access(all)
		let address: Address
		
		access(all)
		var note: String
	}
	
	access(all)
	resource AccountBookmark: AccountBookmarkPublic{ 
		access(all)
		let address: Address
		
		access(all)
		var note: String
		
		init(address: Address, note: String){ 
			self.address = address
			self.note = note
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setNote(note: String){ 
			self.note = note
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicAccountBookmark(address: Address): &FlowviewAccountBookmark.AccountBookmark?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountBookmarks(): &{Address: AccountBookmark}
	}
	
	access(all)
	resource AccountBookmarkCollection: CollectionPublic{ 
		access(all)
		let bookmarks: @{Address: AccountBookmark}
		
		init(){ 
			self.bookmarks <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccountBookmark(address: Address, note: String){ 
			pre{ 
				self.bookmarks[address] == nil:
					"Account bookmark already exists"
			}
			self.bookmarks[address] <-! create AccountBookmark(address: address, note: note)
			emit AccountBookmarkAdded(owner: (self.owner!).address, address: address, note: note)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccountBookmark(address: Address){ 
			destroy self.bookmarks.remove(key: address)
			emit AccountBookmarkRemoved(owner: (self.owner!).address, address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicAccountBookmark(address: Address): &AccountBookmark?{ 
			return &self.bookmarks[address] as &AccountBookmark?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAccountBookmark(address: Address): &AccountBookmark?{ 
			return &self.bookmarks[address] as &AccountBookmark?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountBookmarks(): &{Address: AccountBookmark}{ 
			return &self.bookmarks as &{Address: AccountBookmark}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @AccountBookmarkCollection{ 
		return <-create AccountBookmarkCollection()
	}
	
	init(){ 
		self.AccountBookmarkCollectionStoragePath = /storage/flowviewAccountBookmarkCollection
		self.AccountBookmarkCollectionPublicPath = /public/flowviewAccountBookmarkCollection
		self.AccountBookmarkCollectionPrivatePath = /private/flowviewAccountBookmarkCollection
		emit ContractInitialized()
	}
}
