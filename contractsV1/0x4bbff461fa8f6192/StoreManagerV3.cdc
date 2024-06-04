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

	import FantastecSwapDataProperties from "./FantastecSwapDataProperties.cdc"

access(all)
contract StoreManagerV3{ 
	access(all)
	event SectionAdded(id: UInt64)
	
	access(all)
	event SectionRemoved(id: UInt64)
	
	access(all)
	event ProductAdded(id: UInt64)
	
	access(all)
	event ProductRemoved(id: UInt64)
	
	access(all)
	event ProductUpdated(id: UInt64)
	
	access(all)
	event ProductVolumeForSaleDecremented(id: UInt64, newVolumeForSale: UInt64)
	
	access(all)
	event SectionItemAdded(id: UInt64, sectionId: UInt64, productId: UInt64)
	
	access(all)
	event SectionItemRemoved(id: UInt64, sectionId: UInt64)
	
	access(all)
	let StoreManagerDataPath: StoragePath
	
	access(contract)
	var nextSectionItemId: UInt64
	
	access(contract)
	var nextSectionId: UInt64
	
	access(all)
	struct Product{ 
		access(all)
		let id: UInt64
		
		access(all)
		let description: String
		
		access(all)
		let level: FantastecSwapDataProperties.Level?
		
		access(all)
		let numberOfOptionalNfts: UInt64
		
		access(all)
		let numberOfPacks: UInt64
		
		access(all)
		let numberOfRegularNfts: UInt64
		
		access(all)
		let partner: FantastecSwapDataProperties.Partner?
		
		access(all)
		let season: FantastecSwapDataProperties.Season?
		
		access(all)
		let shortTitle: String
		
		access(all)
		let sku: FantastecSwapDataProperties.Sku?
		
		access(all)
		let sport: FantastecSwapDataProperties.Sport?
		
		access(all)
		let team: FantastecSwapDataProperties.Team?
		
		access(all)
		let themeType: String
		
		access(all)
		let title: String
		
		access(all)
		let releaseDate: UFix64
		
		access(all)
		var volumeForSale: UInt64
		
		access(all)
		let productImageUrl: String
		
		access(all)
		let productVideoUrl: String
		
		access(all)
		let backgroundImageSmallUrl: String
		
		access(all)
		let backgroundImageLargeUrl: String
		
		access(all)
		let featuredImageUrl: String
		
		access(all)
		let featuredVideoUrl: String
		
		init(
			id: UInt64,
			description: String,
			level: FantastecSwapDataProperties.Level?,
			numberOfOptionalNfts: UInt64,
			numberOfPacks: UInt64,
			numberOfRegularNfts: UInt64,
			partner: FantastecSwapDataProperties.Partner?,
			season: FantastecSwapDataProperties.Season?,
			shortTitle: String,
			sku: FantastecSwapDataProperties.Sku?,
			sport: FantastecSwapDataProperties.Sport?,
			team: FantastecSwapDataProperties.Team?,
			themeType: String,
			title: String,
			releaseDate: UFix64,
			volumeForSale: UInt64,
			productImageUrl: String,
			productVideoUrl: String,
			backgroundImageSmallUrl: String,
			backgroundImageLargeUrl: String,
			featuredImageUrl: String,
			featuredVideoUrl: String
		){ 
			self.id = id
			self.description = description
			self.level = level
			self.numberOfOptionalNfts = numberOfOptionalNfts
			self.numberOfPacks = numberOfPacks
			self.numberOfRegularNfts = numberOfRegularNfts
			self.partner = partner
			self.season = season
			self.shortTitle = shortTitle
			self.sku = sku
			self.sport = sport
			self.team = team
			self.themeType = themeType
			self.title = title
			self.releaseDate = releaseDate
			self.volumeForSale = volumeForSale
			self.productImageUrl = productImageUrl
			self.productVideoUrl = productVideoUrl
			self.backgroundImageSmallUrl = backgroundImageSmallUrl
			self.backgroundImageLargeUrl = backgroundImageLargeUrl
			self.featuredImageUrl = featuredImageUrl
			self.featuredVideoUrl = featuredVideoUrl
		}
		
		access(contract)
		fun decrementProductVolumeForSale(): UInt64{ 
			if self.volumeForSale == 0{ 
				panic("cannot decrement product for sale as volume for sale is zero - product ID: ".concat(self.id.toString()))
			}
			self.volumeForSale = self.volumeForSale - 1
			return self.volumeForSale
		}
	}
	
	access(all)
	struct SectionItem{ 
		access(all)
		let id: UInt64
		
		access(all)
		let position: UInt64
		
		access(all)
		var product: Product?
		
		access(all)
		let productId: UInt64
		
		init(id: UInt64, position: UInt64, productId: UInt64){ 
			self.id = id
			self.position = position
			self.product = nil
			self.productId = productId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addProduct(product: Product){ 
			self.product = product
		}
	}
	
	access(all)
	struct Section{ 
		access(all)
		let id: UInt64
		
		access(all)
		let sectionItems:{ UInt64: SectionItem}
		
		access(all)
		let position: UInt64
		
		access(all)
		let title: String
		
		access(all)
		let type: String
		
		init(id: UInt64, position: UInt64, title: String, type: String){ 
			self.id = id
			self.sectionItems ={} 
			self.position = position
			self.title = title
			self.type = type
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSectionItem(position: UInt64, productId: UInt64): SectionItem{ 
			let id = StoreManagerV3.nextSectionItemId
			let sectionItem = SectionItem(id: id, position: position, productId: productId)
			self.sectionItems.insert(key: id, sectionItem)
			StoreManagerV3.nextSectionItemId = StoreManagerV3.nextSectionItemId + 1
			return sectionItem
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addProductToSectionItem(sectionItemId: UInt64, product: Product): SectionItem?{ 
			if let sectionItem = self.sectionItems[sectionItemId]{ 
				sectionItem.addProduct(product: product)
				self.sectionItems[sectionItemId] = sectionItem
				return sectionItem
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSectionItem(id: UInt64): SectionItem?{ 
			return self.sectionItems.remove(key: id)
		}
	}
	
	//-------------------------
	// Contract level functions
	//-------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun getStore():{ UInt64: Section}{ 
		return self.getDataManager().getStore()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProduct(productId: UInt64): Product?{ 
		return self.getDataManager().getProduct(productId: productId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProducts(productIds: [UInt64]): [Product]{ 
		return self.getDataManager().getProducts(productIds: productIds)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllProducts():{ UInt64: Product}{ 
		return self.getDataManager().getAllProducts()
	}
	
	access(all)
	resource DataManager{ 
		access(contract)
		let products:{ UInt64: Product}
		
		access(contract)
		let store:{ UInt64: Section}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStore():{ UInt64: Section}{ 
			let products = self.products
			let store = self.store
			let currentBlock = getCurrentBlock()
			store.forEachKey(fun (sectionId: UInt64): Bool{ 
					if let section = store[sectionId]{ 
						section.sectionItems.forEachKey(fun (sectionItemId: UInt64): Bool{ 
								if let sectionItem = section.sectionItems[sectionItemId]{ 
									if let product = products[sectionItem.productId]{ 
										if product.releaseDate <= currentBlock.timestamp{ 
											section.addProductToSectionItem(sectionItemId: sectionItem.id, product: product)
										}
									}
								}
								return true
							})
						store[sectionId] = section
					}
					return true
				})
			return store
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addProduct(
			id: UInt64,
			description: String,
			level: FantastecSwapDataProperties.Level?,
			numberOfOptionalNfts: UInt64,
			numberOfPacks: UInt64,
			numberOfRegularNfts: UInt64,
			partner: FantastecSwapDataProperties.Partner?,
			season: FantastecSwapDataProperties.Season?,
			shortTitle: String,
			sku: FantastecSwapDataProperties.Sku?,
			sport: FantastecSwapDataProperties.Sport?,
			team: FantastecSwapDataProperties.Team?,
			themeType: String,
			title: String,
			releaseDate: UFix64,
			volumeForSale: UInt64,
			productImageUrl: String,
			productVideoUrl: String,
			backgroundImageSmallUrl: String,
			backgroundImageLargeUrl: String,
			featuredImageUrl: String,
			featuredVideoUrl: String
		){ 
			let product =
				Product(
					id: id,
					description: description,
					level: level,
					numberOfOptionalNfts: numberOfOptionalNfts,
					numberOfPacks: numberOfPacks,
					numberOfRegularNfts: numberOfRegularNfts,
					partner: partner,
					season: season,
					shortTitle: shortTitle,
					sku: sku,
					sport: sport,
					team: team,
					themeType: themeType,
					title: title,
					releaseDate: releaseDate,
					volumeForSale: volumeForSale,
					productImageUrl: productImageUrl,
					productVideoUrl: productVideoUrl,
					backgroundImageSmallUrl: backgroundImageSmallUrl,
					backgroundImageLargeUrl: backgroundImageLargeUrl,
					featuredImageUrl: featuredImageUrl,
					featuredVideoUrl: featuredVideoUrl
				)
			self.products[product.id] = product
			emit ProductAdded(id: product.id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun decrementProductVolumeForSale(productId: UInt64){ 
			let newVolumeForSale = self.products[productId]?.decrementProductVolumeForSale()
			if newVolumeForSale != nil{ 
				emit ProductVolumeForSaleDecremented(id: productId, newVolumeForSale: newVolumeForSale!)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProduct(productId: UInt64): Product?{ 
			return self.products[productId]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProducts(productIds: [UInt64]): [Product]{ 
			let products: [Product] = []
			for productId in productIds{ 
				let product = self.getProduct(productId: productId)
				if product != nil{ 
					products.append(product!)
				}
			}
			return products
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllProducts():{ UInt64: Product}{ 
			return self.products
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeProduct(productId: UInt64){ 
			let store = self.store
			let sectionItemsToRemove:{ UInt64: UInt64} ={} 
			store.forEachKey(fun (sectionId: UInt64): Bool{ 
					if let section = store[sectionId]{ 
						section.sectionItems.forEachKey(fun (sectionItemId: UInt64): Bool{ 
								if let sectionItem = section.sectionItems[sectionItemId]{ 
									if sectionItem.productId == productId{ 
										sectionItemsToRemove[section.id] = sectionItem.id
									}
								}
								return true
							})
					}
					return true
				})
			
			// Remove all section items that are associated with a removed product
			for sectionId in sectionItemsToRemove.keys{ 
				let sectionItemId = sectionItemsToRemove[sectionId]
				self.removeSectionItemFromSection(sectionId: sectionId, sectionItemId: sectionItemId!)
				// if the section is now empty, remove it
				let updatedSection = store[sectionId]
				if (updatedSection!).sectionItems.length == 0{ 
					self.removeSection(sectionId: sectionId)
				}
			}
			self.products.remove(key: productId)
			emit ProductUpdated(id: productId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSection(position: UInt64, title: String, type: String): UInt64{ 
			let id = StoreManagerV3.nextSectionId
			let section = Section(id: id, position: position, title: title, type: type)
			self.store[section.id] = section
			emit SectionAdded(id: id)
			StoreManagerV3.nextSectionId = StoreManagerV3.nextSectionId + 1
			return id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSection(sectionId: UInt64): Section?{ 
			return self.store[sectionId]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSection(sectionId: UInt64){ 
			self.store.remove(key: sectionId)
			emit SectionRemoved(id: sectionId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSectionItemToSection(
			sectionId: UInt64,
			position: UInt64,
			productId: UInt64
		): UInt64{ 
			let sectionItem =
				self.store[sectionId]?.addSectionItem(position: position, productId: productId)
			sectionItem ?? panic("no section found with ID ".concat(sectionId.toString()))
			emit SectionItemAdded(id: (sectionItem!).id, sectionId: sectionId, productId: productId)
			return (sectionItem!).id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSectionItemFromSection(sectionId: UInt64, sectionItemId: UInt64){ 
			let sectionItem = self.store[sectionId]?.removeSectionItem(id: sectionItemId)
			sectionItem ?? panic("no section found with ID ".concat(sectionId.toString()))
			emit SectionItemRemoved(id: sectionItemId, sectionId: sectionId)
		}
		
		init(_ products:{ UInt64: Product}, _ sections:{ UInt64: Section}){ 
			self.products = products
			self.store = sections
		}
	}
	
	access(contract)
	fun setDataManager(){ 
		let oldDataManager <-
			self.account.storage.load<@DataManager>(from: self.StoreManagerDataPath)
		var oldProducts = oldDataManager?.products ??{} 
		var oldStore = oldDataManager?.store ??{} 
		self.account.storage.save<@DataManager>(
			<-create DataManager(oldProducts, oldStore),
			to: self.StoreManagerDataPath
		)
		destroy oldDataManager
	}
	
	access(contract)
	fun getDataManager(): &DataManager{ 
		return self.account.storage.borrow<&DataManager>(from: self.StoreManagerDataPath)!
	}
	
	init(){ 
		self.nextSectionItemId = 1
		self.nextSectionId = 1
		self.StoreManagerDataPath = /storage/StoreManagerV3Data
		self.setDataManager()
	}
}
