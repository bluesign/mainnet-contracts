import FantastecSwapDataProperties from ./FantastecSwapDataProperties.cdc

pub contract StoreManagerV3 {
    pub event SectionAdded(id: UInt64)
    pub event SectionRemoved(id: UInt64)

    pub event ProductAdded(id: UInt64)
    pub event ProductRemoved(id: UInt64)
    pub event ProductUpdated(id: UInt64)
    pub event ProductVolumeForSaleDecremented(id: UInt64, newVolumeForSale: UInt64)

    pub event SectionItemAdded(id: UInt64, sectionId: UInt64, productId: UInt64)
    pub event SectionItemRemoved(id: UInt64, sectionId: UInt64)

    pub let StoreManagerDataPath: StoragePath

    access(contract) var nextSectionItemId: UInt64
    access(contract) var nextSectionId: UInt64

    pub struct Product {
        pub let id: UInt64
        pub let description: String
        pub let level: FantastecSwapDataProperties.Level?
        pub let numberOfOptionalNfts: UInt64
        pub let numberOfPacks: UInt64
        pub let numberOfRegularNfts: UInt64
        pub let partner: FantastecSwapDataProperties.Partner?
        pub let season: FantastecSwapDataProperties.Season?
        pub let shortTitle: String
        pub let sku: FantastecSwapDataProperties.Sku?
        pub let sport: FantastecSwapDataProperties.Sport?
        pub let team: FantastecSwapDataProperties.Team?
        pub let themeType: String
        pub let title: String
        pub let releaseDate: UFix64
        pub var volumeForSale: UInt64
        pub let productImageUrl: String
        pub let productVideoUrl: String
        pub let backgroundImageSmallUrl: String
        pub let backgroundImageLargeUrl: String
        pub let featuredImageUrl: String
        pub let featuredVideoUrl: String

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
        ) {
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

        access(contract) fun decrementProductVolumeForSale(): UInt64 {
            if self.volumeForSale == 0 {
                panic("cannot decrement product for sale as volume for sale is zero - product ID: ".concat(self.id.toString()))
            }
            self.volumeForSale = self.volumeForSale - 1
            return self.volumeForSale
        }
    }

    pub struct SectionItem {
        pub let id: UInt64
        pub let position: UInt64
        pub var product: Product?
        pub let productId: UInt64

        init(id: UInt64, position: UInt64, productId: UInt64) {
            self.id = id
            self.position = position
            self.product = nil
            self.productId = productId
        }

        pub fun addProduct(product: Product) {
            self.product = product
        }
    }

    pub struct Section {
        pub let id: UInt64
        pub let sectionItems: {UInt64: SectionItem}
        pub let position: UInt64
        pub let title: String
        pub let type: String

        init(id: UInt64, position: UInt64, title: String, type: String) {
            self.id = id
            self.sectionItems = {}
            self.position = position
            self.title = title
            self.type = type
        }

        pub fun addSectionItem(position: UInt64, productId: UInt64): SectionItem {
            let id = StoreManagerV3.nextSectionItemId

            let sectionItem = SectionItem(id: id, position: position, productId: productId)
            self.sectionItems.insert(key: id, sectionItem)

            StoreManagerV3.nextSectionItemId = StoreManagerV3.nextSectionItemId + 1

            return sectionItem
        }

        pub fun addProductToSectionItem(sectionItemId: UInt64, product: Product): SectionItem? {
            if let sectionItem = self.sectionItems[sectionItemId] {
                sectionItem.addProduct(product: product)
                self.sectionItems[sectionItemId] = sectionItem
                return sectionItem
            }
            return nil
        }

        pub fun removeSectionItem(id: UInt64): SectionItem? {
            return self.sectionItems.remove(key: id)
        }
    }
    
    //-------------------------
    // Contract level functions
    //-------------------------
    pub fun getStore(): {UInt64: Section} {
        return self.getDataManager().getStore()
    }

    pub fun getProduct(productId: UInt64): Product? {
        return self.getDataManager().getProduct(productId: productId)
    }

    pub fun getProducts(productIds: [UInt64]): [Product] {
        return self.getDataManager().getProducts(productIds: productIds)
    }

    pub fun getAllProducts(): {UInt64: Product} {
        return self.getDataManager().getAllProducts()
    }

    pub resource DataManager {
        access(contract) let products: {UInt64: Product}
        access(contract) let store: {UInt64: Section}

        pub fun getStore(): {UInt64: Section} {
            let products = self.products
            let store = self.store
            let currentBlock = getCurrentBlock()

            store.forEachKey(fun (sectionId: UInt64): Bool {
                if let section = store[sectionId] {
                    section.sectionItems.forEachKey(fun (sectionItemId: UInt64): Bool {
                        if let sectionItem = section.sectionItems[sectionItemId] {
                            if let product = products[sectionItem.productId] {
                                if product.releaseDate <= currentBlock.timestamp {
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

        pub fun addProduct(
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
        ) {
            let product = Product(
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

        pub fun decrementProductVolumeForSale(productId: UInt64) {
            let newVolumeForSale = self.products[productId]?.decrementProductVolumeForSale()
            if (newVolumeForSale != nil) {
                emit ProductVolumeForSaleDecremented(id: productId, newVolumeForSale: newVolumeForSale!)
            }
        }

        pub fun getProduct(productId: UInt64): Product? {
            return self.products[productId]
        }

        pub fun getProducts(productIds: [UInt64]): [Product] {
            let products: [Product] = []
            for productId in productIds {
                let product = self.getProduct(productId: productId)
                if (product != nil) {
                    products.append(product!)
                }
            }
            return products
        }

        pub fun getAllProducts(): {UInt64: Product} {
            return self.products
        }

        pub fun removeProduct(productId: UInt64) {
            let store = self.store
            let sectionItemsToRemove: {UInt64: UInt64} = {}
            store.forEachKey(fun (sectionId: UInt64): Bool {
                if let section = store[sectionId] {
                    section.sectionItems.forEachKey(fun (sectionItemId: UInt64): Bool {
                        if let sectionItem = section.sectionItems[sectionItemId] {
                            if sectionItem.productId == productId {
                                sectionItemsToRemove[section.id] = sectionItem.id
                            }
                        }

                        return true
                    })
                }

                return true
            })

            // Remove all section items that are associated with a removed product
            for sectionId in sectionItemsToRemove.keys {
                let sectionItemId = sectionItemsToRemove[sectionId]
                self.removeSectionItemFromSection(sectionId: sectionId, sectionItemId: sectionItemId!)
                // if the section is now empty, remove it
                let updatedSection = store[sectionId]
                if (updatedSection!.sectionItems.length == 0) {
                    self.removeSection(sectionId: sectionId)
                }
            }

            self.products.remove(key: productId)
            emit ProductUpdated(id: productId)
        }

        pub fun addSection(position: UInt64, title: String, type: String): UInt64 {
            let id = StoreManagerV3.nextSectionId
            let section = Section(id: id, position: position, title: title, type: type)

            self.store[section.id] = section

            emit SectionAdded(id: id)
            StoreManagerV3.nextSectionId = StoreManagerV3.nextSectionId + 1

            return id
        }

        pub fun getSection(sectionId: UInt64): Section? {
            return self.store[sectionId]
        }

        pub fun removeSection(sectionId: UInt64) {
            self.store.remove(key: sectionId)
            emit SectionRemoved(id: sectionId)
        }

        pub fun addSectionItemToSection(sectionId: UInt64, position: UInt64, productId: UInt64): UInt64 {
            let sectionItem = self.store[sectionId]?.addSectionItem(position: position, productId: productId)
            sectionItem ?? panic("no section found with ID ".concat(sectionId.toString()))
            emit SectionItemAdded(id: sectionItem!.id, sectionId: sectionId, productId: productId)

            return sectionItem!.id
        }

        pub fun removeSectionItemFromSection(sectionId: UInt64, sectionItemId: UInt64) {
            let sectionItem = self.store[sectionId]?.removeSectionItem(id: sectionItemId)
            sectionItem ?? panic("no section found with ID ".concat(sectionId.toString()))
            emit SectionItemRemoved(id: sectionItemId, sectionId: sectionId)
        }

        init(_ products: {UInt64: Product}, _ sections: {UInt64: Section}) {
            self.products = products
            self.store = sections
        }
    }

    access(contract) fun setDataManager() {
        let oldDataManager <- self.account.load<@DataManager>(from: self.StoreManagerDataPath)
        var oldProducts = oldDataManager?.products ?? {}
        var oldStore = oldDataManager?.store ?? {}
        self.account.save<@DataManager>(<- create DataManager(oldProducts, oldStore), to: self.StoreManagerDataPath)
        destroy oldDataManager
    }

    access(contract) fun getDataManager(): &DataManager {
        return self.account.borrow<&DataManager>(from: self.StoreManagerDataPath)!
    }

    init() {
        self.nextSectionItemId = 1
        self.nextSectionId = 1

        self.StoreManagerDataPath = /storage/StoreManagerV3Data

        self.setDataManager()
    }
}
