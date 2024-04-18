import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

import Flowmap from "../0x483f0fe77f0d59fb/Flowmap.cdc"

import FlowBlocksTradingScore from "./FlowBlocksTradingScore.cdc"

pub contract FlowmapMarketSub100k{ 
    pub        
        // -----------------------------------------------------------------------
        // Contract Events
        // -----------------------------------------------------------------------
        event ContractInitialized()
    
    pub event FlowmapListed(id: UInt64, price: UFix64, listingFee: UFix64)
    
    pub event FlowmapListingCancelled(id: UInt64)
    
    pub event FlowmapPurchased(id: UInt64, price: UFix64, purchaseFee: UFix64)
    
    pub event FlowmapListingPurged(id: UInt64, price: UFix64)
    
    // -----------------------------------------------------------------------
    // Named Paths
    // -----------------------------------------------------------------------
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub let AdminStoragePath: StoragePath
    
    pub let AdminPrivatePath: PrivatePath
    
    // -----------------------------------------------------------------------
    // Contract Fields
    // -----------------------------------------------------------------------
    pub var listingFee: UFix64
    
    pub var purchaseFee: UFix64
    
    pub var listingDuration: UFix64
    
    pub var marketPaused: Bool
    
    pub var totalVolume: UFix64
    
    pub var totalSales: UInt64
    
    priv var sellers: [Address]
    
    priv var sales:{ UInt64: Sale}
    
    pub struct Sale{ 
        pub let id: UInt64
        
        pub let flowmapID: UInt64
        
        pub let seller: Address
        
        pub let buyer: Address
        
        pub let purchaseDate: UFix64
        
        pub let price: UFix64
        
        pub let expirationDate: UFix64
        
        init(
            id: UInt64,
            flowmapID: UInt64,
            seller: Address,
            buyer: Address,
            purchaseDate: UFix64,
            price: UFix64,
            expirationDate: UFix64
        ){ 
            self.id = id
            self.flowmapID = flowmapID
            self.seller = seller
            self.buyer = buyer
            self.purchaseDate = purchaseDate
            self.price = price
            self.expirationDate = expirationDate
        }
    }
    
    pub resource interface SalePublic{ 
        pub fun purchase(
            tokenID: UInt64,
            buyTokens: @FlowToken.Vault,
            buyer: Address
        ): @Flowmap.NFT{} 
        
        pub fun getPrice(tokenID: UInt64): UFix64?{} 
        
        pub fun getExpirationDate(tokenID: UInt64): UFix64?{} 
        
        pub fun getPrices():{ UInt64: UFix64}{} 
        
        pub fun getExpirationDates():{ UInt64: UFix64}{} 
        
        pub fun getIDs(): [UInt64]{} 
        
        pub fun checkCapability(): Bool{} 
        
        pub fun purgeExpiredListings(){} 
        
        pub fun purgeGhostListings(){} 
    }
    
    pub resource SaleCollection: SalePublic{ 
        priv var prices:{ UInt64: UFix64}
        
        priv var expirationDates:{ UInt64: UFix64}
        
        priv var ownerCollection: Capability<&Flowmap.Collection>
        
        init(ownerCollection: Capability<&Flowmap.Collection>){ 
            pre{ 
                ownerCollection.check():
                    "Owner's Flowmap Collection Capability is invalid!"
            }
            self.expirationDates ={} 
            self.prices ={} 
            self.ownerCollection = ownerCollection
        }
        
        pub fun listForSale(tokenID: UInt64, price: UFix64, listingFee: @FlowToken.Vault){ 
            pre{ 
                tokenID <= 99999:
                    "Can't list for sale: ID must be less than 100,000"
                listingFee.balance == FlowmapMarketSub100k.listingFee:
                    "Can't list for sale: listingFee payment doesn't match contract listingFee"
                price >= FlowmapMarketSub100k.purchaseFee:
                    "Can't list for sale: price must be greater than purchaseFee"
                (self.ownerCollection.borrow()!).borrowFlowmap(id: tokenID) != nil:
                    "Can't list for sale: ID doesn't exist in owner's Flowmap Collection"
                FlowmapMarketSub100k.marketPaused == false:
                    "Can't list for sale: Market is paused"
            }
            self.prices[tokenID] = price
            self.expirationDates[tokenID] = getCurrentBlock().timestamp + FlowmapMarketSub100k.listingDuration
            
            // Add seller to list of sellers
            FlowmapMarketSub100k.addSeller(seller: (self.owner!).address)
            (             
             // Contract address receives listing fee
             FlowmapMarketSub100k.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!).deposit(from: <-listingFee)
            emit FlowmapListed(id: tokenID, price: price, listingFee: FlowmapMarketSub100k.listingFee)
        }
        
        pub fun cancelSale(tokenID: UInt64){ 
            pre{ 
                self.prices[tokenID] != nil:
                    "Can't cancel Sale: ID doesn't exist in this SaleCollection"
            }
            self.prices.remove(key: tokenID)
            self.expirationDates.remove(key: tokenID)
            emit FlowmapListingCancelled(id: tokenID)
        }
        
        pub fun purchase(tokenID: UInt64, buyTokens: @FlowToken.Vault, buyer: Address): @Flowmap.NFT{ 
            pre{ 
                self.prices[tokenID] != nil:
                    "Can't purchase: ID doesn't exist in this SaleCollection"
                self.expirationDates[tokenID]! > getCurrentBlock().timestamp:
                    "Can't purchase: Sale has expired"
                buyTokens.balance == self.prices[tokenID]!:
                    "Can't purchase: buyTokens balance must match the price"
                FlowmapMarketSub100k.marketPaused == false:
                    "Can't purchase: Market is paused"
            }
            let price = self.prices[tokenID]!
            (             
             // Contract address receives purchase fee
             FlowmapMarketSub100k.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!).deposit(from: <-buyTokens.withdraw(amount: FlowmapMarketSub100k.purchaseFee))
            (             
             // Seller receives the rest
             getAccount((self.owner!).address).getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!).deposit(from: <-buyTokens)
            let boughtFlowmap <- (self.ownerCollection.borrow()!).withdraw(withdrawID: tokenID) as! @Flowmap.NFT
            
            // Save sales data onchain
            let sale = Sale(id: FlowmapMarketSub100k.totalSales, flowmapID: tokenID, seller: (self.owner!).address, buyer: buyer, purchaseDate: getCurrentBlock().timestamp, price: price, expirationDate: self.expirationDates[tokenID]!)
            FlowmapMarketSub100k.sales[FlowmapMarketSub100k.totalSales] = sale
            FlowmapMarketSub100k.totalVolume = FlowmapMarketSub100k.totalVolume + price
            FlowmapMarketSub100k.totalSales = FlowmapMarketSub100k.totalSales + 1
            
            // Add trading points
            FlowBlocksTradingScore.increaseTradingScore(wallet: (self.owner!).address, points: 100)
            FlowBlocksTradingScore.increaseTradingScore(wallet: buyer, points: 100)
            
            // Clear listing
            self.prices.remove(key: tokenID)
            self.expirationDates.remove(key: tokenID)
            emit FlowmapPurchased(id: tokenID, price: price, purchaseFee: FlowmapMarketSub100k.purchaseFee)
            return <-boughtFlowmap
        }
        
        pub fun getPrice(tokenID: UInt64): UFix64?{ 
            return self.prices[tokenID]
        }
        
        pub fun getExpirationDate(tokenID: UInt64): UFix64?{ 
            return self.expirationDates[tokenID]
        }
        
        pub fun getPrices():{ UInt64: UFix64}{ 
            return self.prices
        }
        
        pub fun getExpirationDates():{ UInt64: UFix64}{ 
            return self.expirationDates
        }
        
        pub fun getIDs(): [UInt64]{ 
            return self.prices.keys
        }
        
        pub fun checkCapability(): Bool{ 
            return self.ownerCollection.check()
        }
        
        pub fun purgeExpiredListings(){ 
            let currentTimestamp = getCurrentBlock().timestamp
            for id in self.expirationDates.keys{ 
                if self.expirationDates[id]! < currentTimestamp{ 
                    emit FlowmapListingPurged(id: id, price: self.prices[id]!)
                    self.prices.remove(key: id)
                    self.expirationDates.remove(key: id)
                }
            }
        }
        
        pub fun purgeGhostListings(){ 
            let IDs = (self.ownerCollection.borrow()!).getIDs()
            for id in self.prices.keys{ 
                if !IDs.contains(id){ 
                    emit FlowmapListingPurged(id: id, price: self.prices[id]!)
                    self.prices.remove(key: id)
                    self.expirationDates.remove(key: id)
                }
            }
        }
    }
    
    pub resource Admin{ 
        pub fun setListingFee(fee: UFix64){ 
            FlowmapMarketSub100k.listingFee = fee
        }
        
        pub fun setPurchaseFee(fee: UFix64){ 
            FlowmapMarketSub100k.purchaseFee = fee
        }
        
        pub fun setListingDuration(duration: UFix64){ 
            FlowmapMarketSub100k.listingDuration = duration
        }
        
        pub fun pauseMarket(){ 
            FlowmapMarketSub100k.marketPaused = true
        }
        
        pub fun unpauseMarket(){ 
            FlowmapMarketSub100k.marketPaused = false
        }
        
        pub fun createNewAdmin(): @Admin{ 
            return <-create Admin()
        }
    }
    
    pub fun createSaleCollection(
        ownerCollection: Capability<&Flowmap.Collection>
    ): @SaleCollection{ 
        return <-create SaleCollection(ownerCollection: ownerCollection)
    }
    
    access(contract) fun addSeller(seller: Address){ 
        if !self.sellers.contains(seller){ 
            self.sellers.append(seller)
        }
    }
    
    pub fun getSellers(): [Address]{ 
        return self.sellers
    }
    
    pub fun getSales():{ UInt64: Sale}{ 
        return self.sales
    }
    
    pub fun getSale(id: UInt64): Sale?{ 
        return self.sales[id]
    }
    
    pub fun getSaleIDs(): [UInt64]{ 
        return self.sales.keys
    }
    
    init(){ 
        // Set named paths
        self
            .CollectionStoragePath = /storage/FlowmapMarketSub100kSaleCollection_3
        self.CollectionPublicPath = /public/FlowmapMarketSub100kSaleCollection_3
        self.AdminStoragePath = /storage/FlowmapMarketSub100kAdmin_3
        self.AdminPrivatePath = /private/FlowmapMarketSub100kAdminUpgrade_3
        
        // Initialize fields
        self.listingFee = 0.85
        self.purchaseFee = 0.85
        self.listingDuration = 1814400.0
        self.marketPaused = false
        self.totalVolume = 0.0
        self.totalSales = 0
        self.sellers = []
        self.sales ={} 
        
        // Put Admin in storage
        self.account.save(<-create Admin(), to: self.AdminStoragePath)
        self.account.link<&FlowmapMarketSub100k.Admin>(
            self.AdminPrivatePath,
            target: self.AdminStoragePath
        )
        ?? panic("Could not get a capability to the admin")
        emit ContractInitialized()
    }
}
