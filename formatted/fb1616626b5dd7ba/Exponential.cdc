/*

    Exponential Auction Contract

    ** Feature Multiple Winners...... Top N winners all receive an NFT ... n = total NFTs in collection

    Auctions are ephemeral and once settled destroyed. 
    All historical informations currently can only be obtained through events.

    An Admin resource is currently required to create an Auction.

    Auction resources live in the contracts Auctions dictionary and are destroyed when settled.

    Auction resource acts as escrow for nfts to be sold and stores current highest bid vault and all related capabilities

    During auction anyone can call placeBid function to place a bid in an auction
    
    Auctions dictionary contains all the live auctions .... when an auction is settled the resource is destroyed 

 */

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract Exponential{ 
    pub event ContractInitialized()
    
    pub event AuctionCreated(
        id: UInt64,
        title: String,
        details: String,
        nftType: String,
        nftIDs: [
            UInt64
        ],
        singleBidMode: Bool,
        minStartingBid: UFix64,
        startTime: UFix64,
        endTime: UFix64,
        duration: UFix64
    )
    
    pub event BidPlaced(
        auctionID: UInt64,
        bidDetails: BidMeta,
        premiumPaid: UFix64
    )
    
    pub event AuctionSettled(
        id: UInt64,
        bidsMeta: [
            BidMeta
        ],
        totalPremiumsPaidByAddresses:{ 
            Address: UFix64
        },
        premiumVaultBalance: UFix64
    )
    
    pub event WinnerPremiumReturned(address: Address, amount: UFix64)
    
    pub event WinnerPremiumPaid(address: Address, amount: UFix64)
    
    pub event SellerPremiumPaid(address: Address, amount: UFix64)
    
    pub event PlatformPaid(address: Address, amount: UFix64)
    
    pub event SellerPaid(address: Address, amount: UFix64)
    
    pub event BatchProcessed(id: UInt64, total: UInt64)
    
    access(contract) var auctions: @{UInt64: Auction} // Dictionary of live Auctions
    
    access(contract) var nextID: UInt64 // internal ticker for auctionIDs
    
    // Dictionary of Vaults for holding platforms premiums collected from all auctions.
    // Access account so the account owner can withdraw these funds.
    access(account) var premiumVaults: @{String: FungibleToken.Vault}
    
    // dictionary of NFT collections by type identifier string 
    // used for holding any prizes that are unable to be sent to the winner or returned to seller 
    // (if they both unlink their supplied nftReceiver capabilities for example)
    access(account) var nfts: @{String: NonFungibleToken.Collection}
    
    pub var adminStoragePath: StoragePath
    
    pub var adminPrivatePath: PrivatePath
    
    access(contract) var BATCH_SIZE: Int // used for batch sending NFTs 
    
    access(contract) var POWER: Int // Exponential Power for premium curve (set to 12 but can be updated if needed)
    
    pub resource Auction{ 
        access(contract) let id: UInt64 // unique ID for auction set in creation function
        
        access(contract) var isSettled: Bool // set to true once the auction has been paid out
        
        access(contract) let singleBidMode: Bool // if true each address can have 1 bid they can add to otherwise they have multiple bids they can't add to 
        
        access(contract) var bids: @[Bid] // 
        
        access(contract) var bidValues: [UFix64] // Sorted bids values 
        
        access(contract) var totalBidByAddress:{ Address: UFix64} // used to lookup bid amount from array
        
        access(contract) var totalPremiumsPaidByAddresses:{ Address: UFix64} // total premium paid by user....  one version return the winner their premium 
        
        access(contract) var sellerFTReceiverCap: Capability<
            &{FungibleToken.Receiver}
        >
        
        access(contract) var nftCollection: @NonFungibleToken.Collection
        
        access(contract) var minStartingBid: UFix64 // minStartingBid can be set at start of auction and doesn't include any premium....  
        
        access(contract) var startTime: UFix64 // when the auction opens for bidding
        
        access(contract) var endTime: UFix64 // end time of the auction unixtime
        
        access(contract) var duration: UFix64 // length of the auction .... 
        
        access(contract) var sellerNftReceiverCap: Capability<
            &{NonFungibleToken.Receiver}
        >
        
        access(contract) var premiumVault: @FungibleToken.Vault // vault for collecting any premiums paid    
        
        access(contract) var bidReturnsProcessed: UInt64 // used for batching bid returns
        
        pub let createdAtBlockHeight: UInt64
        
        pub let title: String
        
        pub let details: String
        
        init(
            id: UInt64,
            singleBidMode: Bool,
            ftCapability: Capability<&{FungibleToken.Receiver}>,
            nftCollection: @NonFungibleToken.Collection,
            nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>,
            premiumVault: @FungibleToken.Vault,
            duration: UFix64,
            minStartingBid: UFix64,
            startTime: UFix64,
            title: String,
            details: String
        ){ 
            self.id = id
            self.singleBidMode = singleBidMode
            self.isSettled = false
            self.sellerFTReceiverCap = ftCapability
            self.nftCollection <- nftCollection
            self.sellerNftReceiverCap = nftReceiverCap
            self.bids <- []
            self.bidValues = []
            self.totalBidByAddress ={} 
            self.totalPremiumsPaidByAddresses ={} 
            self.minStartingBid = minStartingBid
            self.startTime = startTime
            self.duration = duration
            self.endTime = UFix64(self.startTime + self.duration)
            self.premiumVault <- premiumVault
            self.bidReturnsProcessed = 0
            self.createdAtBlockHeight = getCurrentBlock().height
            self.title = title
            self.details = details
        }
        
        pub fun addNFTsToAuction(nftCollection: @NonFungibleToken.Collection){ 
            pre{ 
                self.isSettled == false:
                    "Auction is already settled!"
                Exponential.now() < self.startTime:
                    "Can't add prizes once auction has started!"
            }
            let incomingCollection =
                &nftCollection as &NonFungibleToken.Collection
            let auctionPrizes =
                &self.nftCollection as &NonFungibleToken.Collection
            let ids = incomingCollection.getIDs()
            let BATCH_SIZE = Exponential.BATCH_SIZE
            let batchTotal = ids.length < BATCH_SIZE ? ids.length : BATCH_SIZE
            var i = 0
            while i < batchTotal{ 
                let token <- incomingCollection.withdraw(withdrawID: ids[i])
                auctionPrizes.deposit(token: <-token)
                i = i + 1
            }
            destroy nftCollection
        }
        
        // Settle Auction
        // 
        access(contract) fun settleAuction(){ 
            pre{ 
                Exponential.now() >= self.endTime:
                    "Can't settle auction till after end time."
                self.isSettled == false:
                    "Auction is already settled!"
            }
            let finalBidsMeta = self.getBidsMeta()! // save to variable to send in event
            
            // both of these are batched.... repeatedly calling settleAuction will process the remaining items nfts+bids
            self.sendNFTsToWinners() // fallsback to sending to contract 
            self.sendWinningBidsToSeller() // always 
            let totalPremiumCollected = self.premiumVault.balance
            if totalPremiumCollected > 0.0{ // if there is any premium to divvy 
                self.withdrawRemainingPremium()
            }
            
            // only settled once all nfts and bids are distributed
            if self.nftCollection.getIDs().length == 0
            && self.bidReturnsProcessed == UInt64(self.bids.length){ 
                self.isSettled = true // auction is settled safe to destroy
                emit AuctionSettled(
                    id: self.id,
                    bidsMeta: finalBidsMeta,
                    totalPremiumsPaidByAddresses: self
                        .totalPremiumsPaidByAddresses,
                    premiumVaultBalance: totalPremiumCollected
                )
            }
        }
        
        pub fun getLowestBid(): UFix64{ 
            return self.bidValues.length < self.nftCollection.getIDs().length
                ? self.minStartingBid
                : self.bidValues[self.bidValues.length - 1]
        }
        
        pub fun getMeta(): AuctionMeta{ 
            return AuctionMeta(
                id: self.id,
                title: self.title,
                details: self.details,
                bidsMeta: self.getBidsMeta(),
                currentPremium: self.getCurrentPremium(),
                singleBidMode: self.singleBidMode,
                minStartingBid: self.minStartingBid,
                createdAtBlockHeight: self.createdAtBlockHeight,
                startTime: self.startTime,
                endTime: self.endTime,
                duration: self.duration,
                totalPremiumsPaidByAddresses: self.totalPremiumsPaidByAddresses,
                premiumVaultBalance: self.premiumVault.balance
            )
        }
        
        pub fun getBidsMeta(): [BidMeta]?{ 
            let bidsMeta: [BidMeta] = []
            let total = self.bids.length
            if total == 0{ 
                return nil
            }
            var i = 0
            while i < total{ 
                let b = &self.bids[i] as 
// getPrizeDetails
//
// would like to add support for metadata standard here once finalized

// getCurrentPremium
// 
// returns the current premium % applied to any incoming bids
// this can be start of premium time if whole auction doesn't have premium applied // end time of the auction // current time // explicit  // progress = timeElapsed/duration goes from 0 -> 1 // if premium is above 99%  // cap at 99% 10x !                                            
                                         // The following functions transfer the assets when settling the auction
                                         // Send NFT Prizes to Winning Bidders
                                         &Bid
                let bm = BidMeta(address: b.bidder.address 
// if there are less bids than prizes return prize to seller
// if receiver is still correct type  // early return if all bids are processed // fallback to using auctions premiumVault // if capability has been replaced with another mismatching type // batch is within limit // normal batch // final batch, amount: b                                                                     
                                                                     // the following functions are only ever called by settleAuction if and only if bids[0] exists
                                                                     
                                                                     
                                                                     // returnWinnerPremium 
                                                                     //
                                                                     // returns the winner the total amount they paid in premiums - funds remain in premium vault if unable to pay winner
                                                                     .vault.balance 
// check capability has not been replaced
// early return without withdrawing any premium, id: b                                                                                          
                                                                                          // returnWinnerFractionOfPremium  
                                                                                          //
                                                                                          // borrow Winner vault or return to premium vault if capabiltiy is unlinked
                                                                                          .uuid)
                bidsMeta.append(bm)
                i                  
                  // if winnersVaultCapability has been replaced with non matching type use  the premium vault 
                  = i 
// pay sellers cut
//
// send the seller a fraction of the remaining premium collected
// if sellers Vault capability was replaced with mismatching type use premium vault 
// withdraws any remaining premium to the Premium master vault
// if FungibleToken.Vault exists     // remove vault from dictionary // deposit into vault // insert vault back into dictionary // we have new fungible token vault // insert into dictionary 
// cleanup

// Move metadata from Auction resource here and make easy for frontend UI to consume.
/****************************************************/// Bid Resource
//
// The current in an auction is contained within a Bid Resource. 
// Also stores bidders address and ft and nft receiver capabilities

// this is probably all not needed I don't think this can ever occur but better safe than sorry?!

// Auction Admin Resource
//
// Seller uses this resource to create auctions.

// create an auction
// 
// this is the only way an auction can be created.
// capability to receive payment for auction // vault for storing premiums collected // nfts being sold // required as backup storage in case of return capabilities failure  // for returning unsold nfts                      // minPremium: UFix64
                      
                      // duration > 3600.0 : "Auciton must be at least 5 minutes long"
                      
                      // fee to create auction.... minPremium can be forced to say 1.5-3% (as split 3 ways = 0.5-1% to platform)
                      // let minPremium=0.0
                      // assert( premiumVault.balance == minPremium*minBid, message: "Vault Balance must equal minBid*minPremium")
                      
                      
                      // add the empty collection to contracts nfts array and destroy if already exists
                      //numberOfWinners: nftCollection.getIDs().length,
                      // minPremium: minPremium,
                      + 1
            }
            return bidsMeta
        }
        
        pub fun getPrizeDetails(): [UInt64]{ 
            return self                       
                       // Main public facing function for placing a bid in any active auction
                       // if this fails no funds move
                       .nftCollection.getIDs()
        }
        
        pub fun getCurrentPremium(): UFix64{ 
            let minPremium = // used to index dictionary 
// add minimum 1% premium can make this customizable per auction?
// let minPremium= 0.01


// get current premium and min required bid (including premium)   
// returns premium to be paid as a fraction from 0 to 0.99 = 99%             0.0
            let st                   
                   // create the Bid resource with all necessary capabilities for paying out later
                   = self.startTime
            let et = self.endTime
            let // calculate the Premium ct = Exponential.now()
            if ct // create new entry for users premium paid // increment total premium paid for user  // deposit premium in auction premium vault 
// store just so event is last thing in function!

// check if user has placed a bid
// they've placed a bid already // insertion position is where this bid will be inserted @
// from there we traverse through higher bids 
// aka to the 'left'   until we find the bid with matching address
// remove that bid from bids array // remove from optimized projection 
// Do binary insertion here to find correct insert location..........
// store projection  // store bid and update totalBid for user 
// If we now have more bids than prizes return the lowest bid
// if the capability is unlinked funds are sent to the premium vault                  
                  // Anyone can settle an auction once it's finished by calling this function, 
                  
                  // consider removing but currently used in frontend
                  
                  // borrowAuction
                  //
                  // convenience function to borrow access to an auction by ID
                  
                  // return all auctions meta data....
                  // currently this gives all *live* auctions only.... historic data only available from events 
                  
                  // Global helper functions.
                  //
                  // now
                  // helper function to get current time (as per current block)
                  // https://docs.onflow.org/cadence/measuring-time/
                  
                  // Math.power implementation with floor value
                  < // hard limit of UFix64  et 
// Binary Lookup helper
// returns sorted insertion point of value in bids array
// too small  // use right side of array // use left side of array                       
                       // Contract initialization 
                       && ct > st{ 
                let progress = (ct - st) / (et - st)
                let premium = Exponential.power(value: progress, power: UInt64(Exponential.POWER))
                if premium > 0.99{ 
                    return 0.99
                } else if premium < minPremium{ 
                    return minPremium
                } else{ 
                    return premium
                }
            }
            return 0.0
        }
        
        pub fun auctionIsOpen(): Bool{ 
            let now = Exponential.now()
            return now < self.endTime && now > self.startTime
            && self.isSettled == false
        }
        
        access(contract) fun sendNFTsToWinners(){ 
            pre{ 
                Exponential.now() >= self.endTime:
                    "Auction must have finished to send the winner their NFTs"
            }
            let collection = &self.nftCollection as &NonFungibleToken.Collection
            let IDs = collection.getIDs()
            let BATCH_SIZE = Exponential.BATCH_SIZE
            let batchTotal = IDs.length < BATCH_SIZE ? IDs.length : BATCH_SIZE
            var i = 0
            while i < batchTotal{ 
                let nft <- self.nftCollection.withdraw(withdrawID: IDs[i])
                let nftReceiverCap = i < self.bids.length ? self.bids[i].bidder.nftReceiverCap : self.sellerNftReceiverCap
                let nftReceiverRef = nftReceiverCap.borrow()
                if nftReceiverRef != nil && (nftReceiverRef!).getType() == collection.getType(){ 
                    (nftReceiverRef!).deposit(token: <-nft)
                } else{ 
                    let nftCollectionIdentifier = collection.getType().identifier
                    let temp <- Exponential.nfts.remove(key: nftCollectionIdentifier)!
                    temp.deposit(token: <-nft)
                    Exponential.nfts[nftCollectionIdentifier] <-! temp
                }
                i = i + 1
            }
        }
        
        access(contract) fun sendWinningBidsToSeller(){ 
            if self.bidReturnsProcessed == UInt64(self.bids.length){ 
                return
            }
            var ownersVaultRef =
                self.sellerFTReceiverCap.borrow()
                ?? &self.premiumVault as &FungibleToken.Vault
            if ownersVaultRef.getType() != self.premiumVault.getType(){ 
                ownersVaultRef = &self.premiumVault as &FungibleToken.Vault
            }
            let BATCH_SIZE = UInt64(Exponential.BATCH_SIZE)
            let batchStart = self.bidReturnsProcessed
            let batchEnd =
                self.bidReturnsProcessed + BATCH_SIZE < UInt64(self.bids.length)
                    ? self.bidReturnsProcessed + BATCH_SIZE
                    : UInt64(self.bids.length)
            var total = 0.0
            while self.bidReturnsProcessed < batchEnd{ 
                let vaultBalance = self.bids[self.bidReturnsProcessed].vault.balance
                total = total + vaultBalance
                let funds <- self.bids[self.bidReturnsProcessed].vault.withdraw(amount: vaultBalance)
                ownersVaultRef.deposit(from: <-funds)
                self.bidReturnsProcessed = self.bidReturnsProcessed + 1 as UInt64
            }
            emit SellerPaid(
                address: (ownersVaultRef.owner!).address,
                amount: total
            )
        }
        
        access(contract) fun returnWinnerPremium(){ 
            let totalPremiumPaidByWinner =
                self.totalPremiumsPaidByAddresses[self.bids[0].bidder.address]
            let ownersVaultCap = self.bids[0].bidder.depositCap
            if ownersVaultCap.check() && totalPremiumPaidByWinner != nil{ 
                let ownersVaultRef = ownersVaultCap.borrow()
                if ownersVaultRef.getType() != self.premiumVault.getType(){ 
                    return
                }
                let WinnerTokens <- self.premiumVault.withdraw(amount: totalPremiumPaidByWinner!)
                (ownersVaultRef!).deposit(from: <-WinnerTokens)
                emit WinnerPremiumReturned(address: self.bids[0].bidder.address, amount: totalPremiumPaidByWinner!)
            }
        }
        
        access(contract) fun returnWinnerCutOfPremium(fraction: UFix64){ 
            var winnerVaultRef =
                self.bids[0].bidder.depositCap.borrow()
                ?? &self.premiumVault as &FungibleToken.Vault
            if winnerVaultRef.getType() != self.premiumVault.getType(){ 
                winnerVaultRef = &self.premiumVault as &FungibleToken.Vault
            }
            let winnerAddress = (winnerVaultRef.owner!).address
            let totalPremiumCollected = self.premiumVault.balance
            let amountToPay = fraction * totalPremiumCollected
            let winnerTokens <- self.premiumVault.withdraw(amount: amountToPay)
            winnerVaultRef.deposit(from: <-winnerTokens)
            emit WinnerPremiumPaid(address: winnerAddress, amount: amountToPay)
        }
        
        access(contract) fun paySellerCut(fraction: UFix64){ 
            let sellersCut = self.premiumVault.balance * fraction
            let sellersCutTokens <-
                self.premiumVault.withdraw(amount: sellersCut)
            var sellersVaultRef =
                self.sellerFTReceiverCap.borrow()
                ?? &self.premiumVault as &FungibleToken.Vault
            if sellersVaultRef.getType() != self.premiumVault.getType(){ 
                sellersVaultRef = &self.premiumVault as &FungibleToken.Vault
            }
            sellersVaultRef.deposit(from: <-sellersCutTokens)
            emit SellerPremiumPaid(
                address: (sellersVaultRef.owner!).address,
                amount: sellersCut
            )
        }
        
        access(contract) fun withdrawRemainingPremium(){ 
            let remainingBalance = self.premiumVault.balance
            let platformCut <-
                self.premiumVault.withdraw(amount: remainingBalance)
            let vaultIdentifier = self.premiumVault.getType().identifier
            if Exponential.premiumVaults.containsKey(vaultIdentifier){ 
                let temp <- Exponential.premiumVaults.remove(key: vaultIdentifier)!
                temp.deposit(from: <-platformCut)
                Exponential.premiumVaults[vaultIdentifier] <-! temp
            } else{ 
                Exponential.premiumVaults[vaultIdentifier] <-! platformCut
            }
            emit PlatformPaid(
                address: Exponential.account.address,
                amount: remainingBalance
            )
        }
        
        destroy(){ 
            destroy self.nftCollection
            destroy self.bids
            if self.premiumVault.balance > 0.0{ 
                self.withdrawRemainingPremium()
            }
            destroy self.premiumVault
        }
    }
    
    pub struct AuctionMeta{ 
        pub let id: UInt64
        
        pub let title: String
        
        pub let details: String
        
        pub let bidsMeta: [BidMeta]?
        
        pub var currentPremium: UFix64
        
        pub var singleBidMode: Bool
        
        pub var minStartingBid: UFix64
        
        pub var createdAtBlockHeight: UInt64
        
        pub var startTime: UFix64
        
        pub var endTime: UFix64
        
        pub var duration: UFix64
        
        pub var totalPremiumsPaidByAddresses:{ Address: UFix64}
        
        pub var premiumVaultBalance: UFix64
        
        init(
            id: UInt64,
            title: String,
            details: String,
            bidsMeta: [
                BidMeta
            ]?,
            currentPremium: UFix64,
            singleBidMode: Bool,
            minStartingBid: UFix64,
            createdAtBlockHeight: UInt64,
            startTime: UFix64,
            endTime: UFix64,
            duration: UFix64,
            totalPremiumsPaidByAddresses:{ 
                Address: UFix64
            },
            premiumVaultBalance: UFix64
        ){ 
            self.id = id
            self.title = title
            self.details = details
            self.bidsMeta = bidsMeta
            self.currentPremium = currentPremium
            self.singleBidMode = singleBidMode
            self.minStartingBid = minStartingBid
            self.createdAtBlockHeight = createdAtBlockHeight
            self.startTime = startTime
            self.endTime = endTime
            self.duration = duration
            self.totalPremiumsPaidByAddresses = totalPremiumsPaidByAddresses
            self.premiumVaultBalance = premiumVaultBalance
        }
    }
    
    pub resource Bid{ 
        pub var vault: @FungibleToken.Vault
        
        pub var bidder: @Bidder
        
        init(
            funds: @FungibleToken.Vault,
            ownersAddress: Address,
            depositCap: Capability<&{FungibleToken.Receiver}>,
            nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>
        ){ 
            self.vault <- funds
            self.bidder <- create Bidder(
                    address: ownersAddress,
                    depositCap: depositCap,
                    nftReceiverCap: nftReceiverCap
                )
        }
        
        destroy(){ 
            destroy self.bidder
            if self.vault.balance > 0.0{ 
                let tokens <- self.vault.withdraw(amount: self.vault.balance)
                let tokenType = self.vault.getType()
                let tokenIdentifier = tokenType.identifier
                let contractPremiumVault = &Exponential.premiumVaults[tokenIdentifier] as &FungibleToken.Vault
                if Exponential.premiumVaults.containsKey(tokenIdentifier){ 
                    contractPremiumVault.deposit(from: <-tokens)
                } else{ 
                    Exponential.premiumVaults[tokenIdentifier] <-! tokens
                }
            }
            destroy self.vault
        }
    }
    
    pub struct BidMeta{ 
        pub let address: Address
        
        pub let amount: UFix64
        
        pub let id: UInt64
        
        init(address: Address, amount: UFix64, id: UInt64){ 
            self.address = address
            self.amount = amount
            self.id = id
        }
    }
    
    pub resource Bidder{ 
        access(contract) var address: Address
        
        access(contract) var depositCap: Capability<&{FungibleToken.Receiver}>
        
        access(contract) var nftReceiverCap: Capability<
            &{NonFungibleToken.Receiver}
        >
        
        init(
            address: Address,
            depositCap: Capability<&{FungibleToken.Receiver}>,
            nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>
        ){ 
            self.address = address
            self.depositCap = depositCap
            self.nftReceiverCap = nftReceiverCap
        }
    }
    
    pub resource Admin{ 
        pub fun createAuction(
            ftCapability: Capability<&{FungibleToken.Receiver}>,
            premiumVault: @FungibleToken.Vault,
            nftCollection: @NonFungibleToken.Collection,
            emptyCollection: @NonFungibleToken.Collection,
            nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>,
            singleBidMode: Bool,
            duration: UFix64,
            minBid: UFix64,
            startTime: UFix64,
            title: String,
            details: String
        ){ 
            pre{ 
                ftCapability.check() != nil:
                    "Need a valid FungibleToken Receiver Capability"
                (ftCapability.borrow()!).getType() == premiumVault.getType():
                    "ftCapability and Premium Vault must be of matching types"
                nftReceiverCap.check() != nil:
                    "Need an NFT receiver to return unsold nfts to"
                (nftReceiverCap.borrow()!).getType() == nftCollection.getType():
                    "NFT Receiver capability must match supplied NFT collection"
                emptyCollection.getType() == nftCollection.getType():
                    "Empty collection type must match nft collection type"
                nftCollection.getIDs().length > 0:
                    "Need some NFTs to be sold in the collection."
                duration > 0.0:
                    "Auction must have a duation!"
                startTime >= Exponential.now():
                    "Start time cannot be in the past!"
                minBid > 0.00000001:
                    "Min bid must be at least 0.00000001"
            }
            let nftCollectionIdentifier = emptyCollection.getType().identifier
            if Exponential.nfts[nftCollectionIdentifier] == nil{ 
                Exponential.nfts[nftCollectionIdentifier] <-! emptyCollection
            } else{ 
                destroy emptyCollection
            }
            let newAuction <-
                create Auction(
                    id: Exponential.nextID,
                    singleBidMode: singleBidMode,
                    ftCapability: ftCapability,
                    nftCollection: <-nftCollection,
                    nftReceiverCap: nftReceiverCap,
                    premiumVault: <-premiumVault,
                    duration: duration,
                    minStartingBid: minBid,
                    startTime: startTime,
                    title: title,
                    details: details
                )
            emit AuctionCreated(
                id: Exponential.nextID,
                title: newAuction.title,
                details: newAuction.details,
                nftType: newAuction.nftCollection.getType().identifier,
                nftIDs: newAuction.nftCollection.getIDs(),
                singleBidMode: newAuction.singleBidMode,
                minStartingBid: newAuction.minStartingBid,
                startTime: newAuction.startTime,
                endTime: newAuction.endTime,
                duration: newAuction.duration
            )
            Exponential.auctions[Exponential.nextID] <-! newAuction
            Exponential.nextID = Exponential.nextID + 1
        }
        
        pub fun updateBatchSize(newSize: Int){ 
            Exponential.BATCH_SIZE = newSize
        }
        
        pub fun updatePower(newPower: Int){ 
            Exponential.POWER = newPower
        }
    }
    
    pub fun placeBid(
        auctionID: UInt64,
        funds: @FungibleToken.Vault,
        ftTokenReceiverCap: Capability<&{FungibleToken.Receiver}>,
        nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>
    ){ 
        pre{ 
            Exponential.now() < (Exponential.borrowAuction(id: auctionID)!).endTime:
                "IT'S OVER!"
        }
        let usersAddress = ftTokenReceiverCap.address
        let auctionRef = Exponential.borrowAuction(id: auctionID)!
        let lowestBid = auctionRef.getLowestBid()
        assert(
            funds.getType() == auctionRef.premiumVault.getType(),
            message: "Incorrect fungible token type for this auction"
        )
        assert(
            funds.balance > lowestBid,
            message: "Must bid greater than current minimum bid"
        )
        assert(auctionRef.auctionIsOpen(), message: "Auction is not open!")
        let premium = auctionRef.getCurrentPremium()
        let minBid = lowestBid / (1.0 - premium)
        assert(
            funds.balance > minBid,
            message: "bid is not enough to cover premium "
        )
        var bid <-
            create Bid(
                funds: <-funds,
                ownersAddress: usersAddress,
                depositCap: ftTokenReceiverCap,
                nftReceiverCap: nftReceiverCap
            )
        let bidVault = &bid.vault as &FungibleToken.Vault
        let premiumAmount = bidVault.balance * premium
        let premiumFunds <- bidVault.withdraw(amount: premiumAmount)
        let premiumPaid = premiumFunds.balance
        let totalPremiumPaidByUser =
            auctionRef.totalPremiumsPaidByAddresses[usersAddress]
        if totalPremiumPaidByUser == nil{ 
            auctionRef.totalPremiumsPaidByAddresses.insert(key: usersAddress, premiumPaid)
        } else{ 
            let totalPremiumPaid = totalPremiumPaidByUser! + premiumPaid
            auctionRef.totalPremiumsPaidByAddresses[usersAddress] = totalPremiumPaid
        }
        auctionRef.premiumVault.deposit(from: <-premiumFunds)
        let balance = bid.vault.balance
        let address = bid.bidder.address
        let bidUID = bid.uuid
        let bids = &auctionRef.bids as &[Bid]
        let usersExistingBidValue = auctionRef.totalBidByAddress[address]
        if usersExistingBidValue != nil && auctionRef.singleBidMode == true{ 
            let insertionPosition = self.find(value: usersExistingBidValue!, bids: auctionRef.bidValues)
            var i = insertionPosition > 0 ? insertionPosition - 1 : 0
            while i >= 0{ 
                if bids[i].bidder.address == address{ 
                    let existingBid <- auctionRef.bids.remove(at: i)
                    auctionRef.bidValues.remove(at: i)
                    let existingBidFunds <- existingBid.vault.withdraw(amount: existingBid.vault.balance)
                    bid.vault.deposit(from: <-existingBidFunds)
                    destroy existingBid
                    break
                }
                i = i - 1
            }
        }
        let cursor =
            self.find(value: bid.vault.balance, bids: auctionRef.bidValues)
        auctionRef.bidValues.insert(at: cursor, bid.vault.balance)
        bids.insert(at: cursor, <-bid)
        auctionRef.totalBidByAddress[address] = auctionRef.totalBidByAddress[
                address
            ]
            == nil
                ? balance
                : auctionRef.totalBidByAddress[address]! + balance
        if auctionRef.bids.length > auctionRef.nftCollection.getIDs().length
        && auctionRef.bids.length > 0{ 
            let lowestBid <- auctionRef.bids.removeLast()
            auctionRef.bidValues.removeLast()
            var ownersVaultRef =
                lowestBid.bidder.depositCap.borrow()
                ?? &auctionRef.premiumVault as &FungibleToken.Vault
            let lowestBidFunds <-
                lowestBid.vault.withdraw(amount: lowestBid.vault.balance)
            ownersVaultRef.deposit(from: <-lowestBidFunds)
            destroy lowestBid
        }
        emit BidPlaced(
            auctionID: auctionID,
            bidDetails: BidMeta(address: address, amount: balance, id: bidUID),
            premiumPaid: premiumPaid
        )
    }
    
    pub fun settleAuction(id: UInt64){ 
        let auctionRef = Exponential.borrowAuction(id: id)
        assert(auctionRef != nil, message: "Auction not found.")
        (auctionRef!).settleAuction()
        if (auctionRef!).isSettled{ 
            let auction <- Exponential.auctions.remove(key: id)
            destroy auction
        }
    }
    
    pub fun getAuctions(): [UInt64]{ 
        return self.auctions.keys
    }
    
    pub fun borrowAuction(id: UInt64): &Auction?{ 
        if Exponential.auctions[id] != nil{ 
            return &Exponential.auctions[id] as &Auction
        } else{ 
            return nil
        }
    }
    
    pub fun getAllAuctionsMeta(): [AuctionMeta]{ 
        let allMetadata: [AuctionMeta] = []
        let auctionIDs = self.auctions.keys
        for id in auctionIDs{ 
            let a = &Exponential.auctions[id] as &Auction
            allMetadata.append(a.getMeta())
        }
        return allMetadata
    }
    
    pub fun now(): UFix64{ 
        let now = getCurrentBlock().timestamp
        let quantizedNow = now - now % 10.0
        return UFix64(quantizedNow)
    }
    
    access(contract) fun power(value: UFix64, power: UInt64): UFix64{ 
        var v = value
        var n = power
        while n != 1{ 
            v = v * value
            n = n - 1
            if v < 0.00000001{ 
                break
            }
        }
        return v
    }
    
    pub fun find(value: UFix64, bids: [UFix64]): Int{ 
        var lo = 0
        var hi = bids.length
        while hi > lo{ 
            var mid = Int((lo + hi) / 2)
            if value <= bids[mid]{ 
                lo = mid + 1
            } else{ 
                hi = mid
            }
        }
        return hi
    }
    
    init(){ 
        self.nextID = 0
        self.auctions <-{} 
        self.BATCH_SIZE = 250
        self.POWER = 12
        self.nfts <-{} 
        self.adminStoragePath = /storage/ExponentialAuctionAdmin
        self.adminPrivatePath = /private/ExponentialAuctionAdmin
        let defaultPremiumVault <- FlowToken.createEmptyVault()
        let vaultType = defaultPremiumVault.getType().identifier
        self.premiumVaults <-{ vaultType: <-defaultPremiumVault}
        let adminResource <- create Admin()
        let adminCapability =
            Exponential.account.link<&Admin>(
                self.adminPrivatePath,
                target: self.adminStoragePath
            )
        Exponential.account.save(<-adminResource, to: self.adminStoragePath)
        emit ContractInitialized()
    }
}
