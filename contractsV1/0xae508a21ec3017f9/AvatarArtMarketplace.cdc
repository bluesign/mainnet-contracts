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

import AvatarArtNFT from "../0xae508a21ec3017f9;/AvatarArtNFT.cdc"

import AvatarArtTransactionInfo from "../0xae508a21ec3017f9;/AvatarArtTransactionInfo.cdc"

access(all)
contract AvatarArtMarketplace{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let SaleCollectionStoragePath: StoragePath
	
	access(all)
	let SaleCollectionPublicPath: PublicPath
	
	access(self)
	var feeReference: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>?
	
	access(self)
	var feeRecepientReference: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>?
	
	// emitted NFT is listed for sale
	access(all)
	event TokenListed(nftID: UInt64, price: UFix64, seller: Address?, paymentType: Type)
	
	// emitted when the price of a listed NFT has changed
	access(all)
	event TokenPriceChanged(nftID: UInt64, newPrice: UFix64, seller: Address?)
	
	// emitted when a token is purchased from the market
	access(all)
	event TokenPurchased(nftID: UInt64, price: UFix64, seller: Address?, buyer: Address)
	
	// emitted when NFT has been withdrawn from the sale
	access(all)
	event TokenWithdrawn(nftID: UInt64, owner: Address?)
	
	// emitted when a token purchased from market and a small fee are charged
	access(all)
	event CuttedFee(nftID: UInt64, seller: Address?, fee: CutFee, paymentType: Type)
	
	// ListingDetails
	// A struct containing a Listing's data.
	//
	access(all)
	struct ListingDetails{ 
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		var salePrice: UFix64
		
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		init(
			salePaymentVaultType: Type,
			salePrice: UFix64,
			receiver: Capability<&{FungibleToken.Receiver}>
		){ 
			self.salePaymentVaultType = salePaymentVaultType
			self.salePrice = salePrice
			self.receiver = receiver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSalePrice(_ newPrice: UFix64){ 
			self.salePrice = newPrice
		}
	}
	
	access(all)
	struct CutFee{ 
		access(all)
		var affiliate: UFix64
		
		access(all)
		var storing: UFix64
		
		access(all)
		var insurance: UFix64
		
		access(all)
		var contractor: UFix64
		
		access(all)
		var platform: UFix64
		
		access(all)
		var author: UFix64
		
		init(){ 
			self.affiliate = 0.0
			self.storing = 0.0
			self.insurance = 0.0
			self.contractor = 0.0
			self.platform = 0.0
			self.author = 0.0
		}
	}
	
	// SalePublic
	// Interface that users will publish for their SaleCollection
	// that only exposes the methods that are supposed to be public
	//
	// The public can purchase a NFT from this SaleCollection, get the
	// price of a NFT, or get all the ids of all the NFT up for sale
	//
	access(all)
	resource interface SalePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(
			tokenID: UInt64,
			buyTokens: @{FungibleToken.Vault},
			receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>,
			affiliateVaultCap: Capability<&{FungibleToken.Receiver}>?
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(tokenID: UInt64): ListingDetails?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(tokenID: UInt64): &{NonFungibleToken.NFT}?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == tokenID:
					"Cannot borrow Art reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// SaleCollection
	//
	// A Collection that acts as a marketplace for NFTs. The owner
	// can list NFTs for sale and take sales down by unlisting it.
	//
	// Other users can also purchase NFTs that are for sale
	// in this SaleCollection, check the price of a sale, or check
	// all the NFTs that are for sale by their ids.
	//
	access(all)
	resource SaleCollection: SalePublic{ 
		// Dictionary of the low low prices for each NFT by ID
		access(self)
		var listing:{ UInt64: ListingDetails}
		
		access(self)
		var nfts: @{UInt64:{ NonFungibleToken.NFT}}
		
		// The fungible token vault of the owner of this sale.
		// When someone buys a token, this will be used to deposit
		// tokens into the owner's account.
		init(){ 
			self.listing ={} 
			self.nfts <-{} 
		}
		
		// listForSale
		// listForSale lists NFT(s) for sale
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(nft: @AvatarArtNFT.NFT, price: UFix64, paymentType: Type, receiver: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				price > 0.0:
					"Cannot list a NFT for 0.0"
				AvatarArtTransactionInfo.isCurrencyAccepted(type: paymentType):
					"Payment type is not allow"
			}
			
			// Validate the receiver
			receiver.borrow() ?? panic("can not borrow receiver")
			let tokenID = nft.id
			let old <- self.nfts[tokenID] <- nft
			assert(old == nil, message: "Should never panic this")
			destroy old
			
			// Set sale price
			self.listing[tokenID] = ListingDetails(salePaymentVaultType: paymentType, salePrice: price, receiver: receiver)
			emit TokenListed(nftID: tokenID, price: price, seller: self.owner?.address, paymentType: paymentType)
		}
		
		// unlistSale
		// simply unlists the NFT from the SaleCollection
		// so it is no longer for sale
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun unlistSale(tokenID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.listing.containsKey(tokenID):
					"No token matching this ID for sale!"
				self.nfts.containsKey(tokenID):
					"No token matching this ID for sale!"
			}
			self.listing.remove(key: tokenID)
			emit TokenWithdrawn(nftID: tokenID, owner: self.owner?.address)
			return <-self.nfts.remove(key: tokenID)!
		}
		
		access(self)
		fun cutFee(vault: &{FungibleToken.Vault}, salePrice: UFix64, artId: UInt64, paymentType: Type, affiliateVaultCap: Capability<&{FungibleToken.Receiver}>?){ 
			if AvatarArtMarketplace.feeReference == nil || AvatarArtMarketplace.feeRecepientReference == nil{ 
				return
			}
			let feeOp = ((AvatarArtMarketplace.feeReference!).borrow()!).getFee(tokenId: artId)
			let feeRecepientOp = ((AvatarArtMarketplace.feeRecepientReference!).borrow()!).getAddress(tokenId: artId, payType: paymentType)
			if feeOp == nil || feeRecepientOp == nil{ 
				return
			}
			let fee = feeOp!
			let feeRecepient = feeRecepientOp!
			let cutFee = CutFee()
			
			// Affiliate
			if fee.affiliate != nil && fee.affiliate > 0.0 && affiliateVaultCap != nil && (affiliateVaultCap!).check(){ 
				let fee = salePrice * fee.affiliate / 100.0
				let feeVault <- vault.withdraw(amount: fee)
				((affiliateVaultCap!).borrow()!).deposit(from: <-feeVault)
				cutFee.affiliate = fee
			}
			
			// Storage fee
			if fee.storing != nil && fee.storing > 0.0 && feeRecepient.storing != nil && (feeRecepient.storing!).check(){ 
				let fee = salePrice * fee.storing / 100.0
				let feeVault <- vault.withdraw(amount: fee)
				((feeRecepient.storing!).borrow()!).deposit(from: <-feeVault)
				cutFee.storing = fee
			}
			
			// Insurrance Fee
			if fee.insurance != nil && fee.insurance > 0.0 && feeRecepient.insurance != nil && (feeRecepient.insurance!).check(){ 
				let fee = salePrice * fee.insurance / 100.0
				let feeVault <- vault.withdraw(amount: fee)
				((feeRecepient.insurance!).borrow()!).deposit(from: <-feeVault)
				cutFee.insurance = fee
			}
			
			// Dev
			if fee.contractor != nil && fee.contractor > 0.0 && feeRecepient.contractor != nil && (feeRecepient.contractor!).check(){ 
				let fee = salePrice * fee.contractor / 100.0
				let feeVault <- vault.withdraw(amount: fee)
				((feeRecepient.contractor!).borrow()!).deposit(from: <-feeVault)
				cutFee.contractor = fee
			}
			
			// The Platform
			if fee.platform != nil && fee.platform > 0.0 && feeRecepient.platform != nil && (feeRecepient.platform!).check(){ 
				let fee = salePrice * fee.platform / 100.0
				let feeVault <- vault.withdraw(amount: fee)
				((feeRecepient.platform!).borrow()!).deposit(from: <-feeVault)
				cutFee.platform = fee
			}
			
			// Author
			if let info = AvatarArtTransactionInfo.getNFTInfo(tokenID: artId){ 
				let cap = info.author[vault.getType().identifier]
				if info.authorFee != nil && info.authorFee! > 0.0 && cap != nil && (cap!).check(){ 
					let fee = salePrice * info.authorFee! / 100.0
					let feeVault <- vault.withdraw(amount: fee)
					((cap!).borrow()!).deposit(from: <-feeVault)
					cutFee.author = fee
				}
			}
			emit CuttedFee(nftID: artId, seller: self.owner?.address, fee: cutFee, paymentType: paymentType)
		}
		
		// purchase
		// purchase lets a user send tokens to purchase a NFT that is for sale
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(tokenID: UInt64, buyTokens: @{FungibleToken.Vault}, receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>, affiliateVaultCap: Capability<&{FungibleToken.Receiver}>?){ 
			pre{ 
				self.listing[tokenID] != nil:
					"No token matching this ID for sale!"
				self.nfts[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance == (self.listing[tokenID]!).salePrice:
					"Not enough tokens to buy the NFT!"
			}
			let price = buyTokens.balance
			
			// get the value out of the optional
			let details = self.listing[tokenID]!
			self.listing.remove(key: tokenID)
			assert(buyTokens.isInstance(details.salePaymentVaultType), message: "payment vault is not allow")
			let vaultRef = details.receiver.borrow() ?? panic("Could not borrow reference to owner token vault")
			self.cutFee(vault: &buyTokens as &{FungibleToken.Vault}, salePrice: price, artId: tokenID, paymentType: details.salePaymentVaultType, affiliateVaultCap: affiliateVaultCap)
			
			// deposit the user's tokens into the owners vault
			vaultRef.deposit(from: <-buyTokens)
			
			// remove the NFT dictionary 
			let nft <- self.nfts.remove(key: tokenID)!
			let receiver = receiverCap.borrow() ?? panic("Can not borrow a reference to receiver collection")
			receiver.deposit(token: <-nft)
			
			// Set first owner nft is false
			AvatarArtTransactionInfo.setFirstOwner(tokenID: tokenID, false)
			emit TokenPurchased(nftID: tokenID, price: price, seller: self.owner?.address, buyer: receiverCap.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(id: UInt64, newPrice: UFix64){ 
			pre{ 
				self.listing[id] != nil:
					"No token matching this ID for sale!"
			}
			let details = self.listing[id]!
			details.setSalePrice(newPrice)
			self.listing[id] = details
			emit TokenPriceChanged(nftID: id, newPrice: newPrice, seller: self.owner?.address)
		}
		
		// getDetails
		// getDetails returns the details of a specific NFT in the sale
		// if it exists, otherwise nil
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(tokenID: UInt64): ListingDetails?{ 
			return self.listing[tokenID]
		}
		
		// getIDs
		// getIDs returns an array of all the NFT IDs that are up for sale
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.listing.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(tokenID: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.nfts[tokenID] as &{NonFungibleToken.NFT}?
		}
	}
	
	// createSaleCollection
	// createCollection returns a new SaleCollection resource to the caller
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleCollection(): @SaleCollection{ 
		return <-create SaleCollection()
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setFeePreference(
			feeReference: Capability<&AvatarArtTransactionInfo.FeeInfo>,
			feeRecepientReference: Capability<&AvatarArtTransactionInfo.TransactionAddress>
		){ 
			AvatarArtMarketplace.feeRecepientReference = feeRecepientReference
			AvatarArtMarketplace.feeReference = feeReference
		}
	}
	
	init(){ 
		self.feeReference = nil
		self.feeRecepientReference = nil
		self.AdminStoragePath = /storage/avatarArtMarketplaceAdmin
		self.SaleCollectionStoragePath = /storage/avatarArtMarketplaceSaleCollection
		self.SaleCollectionPublicPath = /public/avatarArtMarketplaceSaleCollection
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
