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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MatrixMarketOpenOffer{ 
	
	// initialize StoragePath and OpenOfferPublicPath
	access(all)
	event MatrixMarketOpenOfferInitialized()
	
	// MatrixMarketOpenOffer initialized
	access(all)
	event OpenOfferInitialized(OpenOfferResourceId: UInt64)
	
	access(all)
	event OpenOfferDestroyed(OpenOfferResourceId: UInt64)
	
	// event: create a bid
	access(all)
	event OfferAvailable(
		bidAddress: Address,
		bidId: UInt64,
		vaultType: Type,
		bidPrice: UFix64,
		nftType: Type,
		nftId: UInt64,
		brutto: UFix64,
		cuts:{ 
			Address: UFix64
		},
		expirationTime: UFix64
	)
	
	// event: close a bid (purchased or removed)
	access(all)
	event OfferCompleted(bidId: UInt64, purchased: Bool)
	
	// payment splitter
	access(all)
	struct Cut{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let amount: UFix64
		
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	access(all)
	struct OfferDetails{ 
		access(all)
		let bidId: UInt64
		
		access(all)
		let vaultType: Type
		
		access(all)
		let bidPrice: UFix64
		
		access(all)
		let nftType: Type
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let brutto: UFix64
		
		access(all)
		let cuts: [Cut]
		
		access(all)
		let expirationTime: UFix64
		
		access(all)
		var purchased: Bool
		
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
		}
		
		init(
			bidId: UInt64,
			vaultType: Type,
			bidPrice: UFix64,
			nftType: Type,
			nftId: UInt64,
			brutto: UFix64,
			cuts: [
				Cut
			],
			expirationTime: UFix64
		){ 
			self.bidId = bidId
			self.vaultType = vaultType
			self.bidPrice = bidPrice
			self.nftType = nftType
			self.nftId = nftId
			self.brutto = brutto
			self.cuts = cuts
			self.expirationTime = expirationTime
			self.purchased = false
		}
	}
	
	access(all)
	resource interface OfferPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(item: @{NonFungibleToken.NFT}): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): OfferDetails
	}
	
	access(all)
	resource Offer: OfferPublic{ 
		access(self)
		let details: OfferDetails
		
		access(contract)
		let vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>
		
		access(contract)
		let rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		init(vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>, offerPrice: UFix64, rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, cuts: [Cut], expirationTime: UFix64){ 
			pre{ 
				rewardCapability.check():
					"reward capability not valid"
				cuts.length <= 10:
					"length of cuts too long"
			}
			self.vaultRefCapability = vaultRefCapability
			self.rewardCapability = rewardCapability
			var price: UFix64 = offerPrice
			let cutsInfo:{ Address: UFix64} ={} 
			for cut in cuts{ 
				assert(cut.receiver.check(), message: "invalid cut receiver")
				assert(price > cut.amount, message: "price must be > 0")
				price = price - cut.amount
				cutsInfo[cut.receiver.address] = cut.amount
			}
			let vaultRef = self.vaultRefCapability.borrow() ?? panic("cannot borrow vaultRefCapability")
			self.details = OfferDetails(bidId: self.uuid, vaultType: vaultRef.getType(), bidPrice: price, nftType: nftType, nftId: nftId, brutto: offerPrice, cuts: cuts, expirationTime: expirationTime)
			emit OfferAvailable(bidAddress: rewardCapability.address, bidId: self.details.bidId, vaultType: self.details.vaultType, bidPrice: self.details.bidPrice, nftType: self.details.nftType, nftId: self.details.nftId, brutto: self.details.brutto, cuts: cutsInfo, expirationTime: self.details.expirationTime)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(item: @{NonFungibleToken.NFT}): @{FungibleToken.Vault}{ 
			pre{ 
				self.details.expirationTime > getCurrentBlock().timestamp:
					"Offer has expired"
				!self.details.purchased:
					"Offer has already been purchased"
				item.isInstance(self.details.nftType):
					"item NFT is not of specified type"
				item.id == self.details.nftId:
					"item NFT does not have specified ID"
			}
			self.details.setToPurchased()
			(self.rewardCapability.borrow()!).deposit(token: <-item)
			let payment <- (self.vaultRefCapability.borrow()!).withdraw(amount: self.details.brutto)
			for cut in self.details.cuts{ 
				if let receiver = cut.receiver.borrow(){ 
					let part <- payment.withdraw(amount: cut.amount)
					receiver.deposit(from: <-part)
				}
			}
			emit OfferCompleted(bidId: self.details.bidId, purchased: self.details.purchased)
			return <-payment
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): OfferDetails{ 
			return self.details
		}
	}
	
	access(all)
	resource interface OpenOfferManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createOffer(
			vaultRefCapability: Capability<
				&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}
			>,
			offerPrice: UFix64,
			rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			nftType: Type,
			nftId: UInt64,
			cuts: [
				MatrixMarketOpenOffer.Cut
			],
			expirationTime: UFix64
		): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeOffer(bidId: UInt64)
	}
	
	access(all)
	resource interface OpenOfferPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getOfferIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOffer(bidId: UInt64): &Offer?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanup(bidId: UInt64)
	}
	
	access(all)
	resource OpenOffer: OpenOfferManager, OpenOfferPublic{ 
		access(self)
		var bids: @{UInt64: Offer}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createOffer(vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>, offerPrice: UFix64, rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, cuts: [Cut], expirationTime: UFix64): UInt64{ 
			let bid <- create Offer(vaultRefCapability: vaultRefCapability, offerPrice: offerPrice, rewardCapability: rewardCapability, nftType: nftType, nftId: nftId, cuts: cuts, expirationTime: expirationTime)
			let bidId = bid.uuid
			let dummy <- self.bids[bidId] <- bid
			destroy dummy
			return bidId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeOffer(bidId: UInt64){ 
			destroy (self.bids.remove(key: bidId) ?? panic("missing bid"))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOfferIds(): [UInt64]{ 
			return self.bids.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOffer(bidId: UInt64): &Offer?{ 
			if self.bids[bidId] != nil{ 
				return &self.bids[bidId] as &Offer?
			} else{ 
				return nil
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanup(bidId: UInt64){ 
			pre{ 
				self.bids[bidId] != nil:
					"could not find Offer with given id"
			}
			let bid <- self.bids.remove(key: bidId)!
			assert(bid.getDetails().purchased == true, message: "Offer is not purchased, only admin can remove")
			destroy bid
		}
		
		init(){ 
			self.bids <-{} 
			emit OpenOfferInitialized(OpenOfferResourceId: self.uuid)
		}
	}
	
	// create openbid resource
	access(TMP_ENTITLEMENT_OWNER)
	fun createOpenOffer(): @OpenOffer{ 
		return <-create OpenOffer()
	}
	
	access(all)
	let OpenOfferStoragePath: StoragePath
	
	access(all)
	let OpenOfferPublicPath: PublicPath
	
	init(){ 
		self.OpenOfferStoragePath = /storage/MatrixMarketOpenOffer
		self.OpenOfferPublicPath = /public/MatrixMarketOpenOffer
		emit MatrixMarketOpenOfferInitialized()
	}
}
