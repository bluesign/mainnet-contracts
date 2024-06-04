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
contract StarlyCollectorScore{ 
	access(all)
	struct Config{ 
		access(all)
		let editions: [[UInt32; 2]]
		
		access(all)
		let rest: UInt32
		
		access(all)
		let last: UInt32
		
		init(editions: [[UInt32; 2]], rest: UInt32, last: UInt32){ 
			self.editions = editions
			self.rest = rest
			self.last = last
		}
	}
	
	// configs by collection id (or 'default'), then by rarity
	access(contract)
	let configs:{ String:{ String: Config}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectorScore(
		collectionID: String,
		rarity: String,
		edition: UInt32,
		editions: UInt32,
		priceCoefficient: UFix64
	): UFix64?{ 
		let collectionConfig =
			self.configs[collectionID] ?? self.configs["default"] ?? panic("No score config found")
		let rarityConfig = collectionConfig[rarity] ?? panic("No rarity config")
		var editionScore: UInt32 = 0
		if edition == editions && edition != 1{ 
			editionScore = rarityConfig.last
		} else{ 
			for e in rarityConfig.editions{ 
				if edition <= e[0]{ 
					editionScore = e[1]
					break
				}
			}
		}
		if editionScore == 0{ 
			editionScore = rarityConfig.rest
		}
		return UFix64(editionScore) * priceCoefficient
	}
	
	access(all)
	resource interface IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCollectionConfig(
			collectionID: String,
			config:{ 
				String: StarlyCollectorScore.Config
			}
		): Void
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCollectionConfig(collectionID: String, config:{ String: Config}){ 
			StarlyCollectorScore.configs[collectionID] = config
		}
	}
	
	access(all)
	resource interface EditorProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setEditorCapability(cap: Capability<&StarlyCollectorScore.Editor>): Void
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
		fun addCollectionConfig(collectionID: String, config:{ String: Config}){ 
			((self.editorCapability!).borrow()!).addCollectionConfig(collectionID: collectionID, config: config)
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
		self.AdminStoragePath = /storage/starlyCollectorScoreAdmin
		self.EditorStoragePath = /storage/starlyCollectorScoreEditor
		self.EditorProxyPublicPath = /public/starlyCollectorScoreEditorProxy
		self.EditorProxyStoragePath = /storage/starlyCollectorScoreEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
		self.configs ={} 
	}
}
