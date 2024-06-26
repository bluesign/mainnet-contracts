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

	// Popsycl NFT Marketplace
// Pack Marketplace Smart Contract
// Version		 : 0.0.1
// Blockchain	  : Flow www.onFlow.org
// Owner		   : Popsycl.com
// Developer	   : RubiconFinTech.com
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import PopsyclMarketplace from "./PopsyclMarketplace.cdc"

import PopsyclPack from "./PopsyclPack.cdc"

import Popsycl from "./Popsycl.cdc"

access(all)
contract PopsyclPackMarketplace{ 
	
	// Event that is emitted when a new Popnow NFT is put up for sale
	access(all)
	event ForSale(packTokenId: UInt64, price: UFix64)
	
	// Event that is emitted when the NFT price changes
	access(all)
	event PriceChanged(packTokenId: UInt64, newPrice: UFix64)
	
	access(all)
	event TokenWithdrawPopsycl(token: UInt64)
	
	access(all)
	event PosyclTokenDeposit(token: UInt64)
	
	// Event that is emitted when a NFT token is purchased
	access(all)
	event TokenPurchased(packTokenId: UInt64, price: UFix64)
	
	// Event that is emitted when a seller withdraws their NFT from the sale
	access(all)
	event SaleWithdrawn(packTokenId: UInt64)
	
	/// Path where the `SaleCollection` is stored
	access(all)
	let marketPackStoragePath: StoragePath
	
	/// Path where the public capability for the `SaleCollection` is
	access(all)
	let marketPackPublicPath: PublicPath
	
	// Interface public methods that are used for NFT sales actions
	// recipientPack: &{PopsyclPack.PopsyclPackCollectionPublic},
	access(all)
	resource interface SalePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun packPurchase(
			packId: UInt64,
			tokens: [
				UInt64
			],
			recipient: &{Popsycl.PopsyclCollectionPublic},
			payment: @{FungibleToken.Vault}
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packIdPrice(id: UInt64): UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packTokenCreator(id: UInt64): Address??
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packCurrentTokenOwner(id: UInt64): Address??
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packIsResale(id: UInt64): Bool?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packGetIDs(): [UInt64]
	}
	
	// pack SaleCollection
	//
	// NFT Collection object that allows a user to list their NFT for sale
	// where others can send fungible tokens to purchase it
	//
	access(all)
	resource PackSaleCollection: SalePublic{ 
		
		// Dictionary of the PopsyclPack NFTs that the user is putting up for sale
		access(self)
		let packForSale: @{UInt64: PopsyclPack.NFT}
		
		// Dictionary of the NFTs that the user is putting up for sale  
		access(self)
		let forSale: @{UInt64: Popsycl.NFT}
		
		// Dictionary of the pack prices for each NFT by ID
		access(self)
		let packPrices:{ UInt64: UFix64}
		
		// Dictionary of the pack prices for each NFT by ID
		access(self)
		let packCreators:{ UInt64: Address?}
		
		// Dictionary of the pack prices for each NFT by ID
		access(self)
		let packInfluencer:{ UInt64: Address?}
		
		// Dictionary of pack sale type (either sale/resale)
		access(self)
		let packResale:{ UInt64: Bool}
		
		// Dictionary of pack royalty for each NFT by ID
		access(self)
		let packRoylty:{ UInt64: UFix64}
		
		// Dictionary of pack token owner
		access(self)
		let packSeller:{ UInt64: Address?}
		
		// The fungible token vault of the owner of this sale.
		// When someone buys a token, this resource can deposit
		// tokens into their account.
		access(account)
		let ownerVault: Capability<&{FungibleToken.Receiver}>
		
		init(vault: Capability<&{FungibleToken.Receiver}>){ 
			self.packForSale <-{} 
			self.forSale <-{} 
			self.ownerVault = vault
			self.packPrices ={} 
			self.packCreators ={} 
			self.packInfluencer ={} 
			self.packResale ={} 
			self.packRoylty ={} 
			self.packSeller ={} 
		}
		
		// Withdraw gives the owner the opportunity to remove a NFT from sale
		access(TMP_ENTITLEMENT_OWNER)
		fun nftwithdraw(id: UInt64): @Popsycl.NFT{ 
			let token <- self.forSale.remove(key: id) ?? panic("missing NFT")
			emit TokenWithdrawPopsycl(token: id)
			return <-token
		}
		
		// Withdraw gives the owner the opportunity to remove a NFT from sale
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: UInt64): @PopsyclPack.NFT{ 
			// remove the price
			self.packPrices.remove(key: id)
			self.packCreators.remove(key: id)
			self.packRoylty.remove(key: id)
			self.packInfluencer.remove(key: id)
			self.packResale.remove(key: id)
			self.packSeller.remove(key: id)
			// remove and return the token
			let token <- self.packForSale.remove(key: id) ?? panic("missing NFT")
			return <-token
		}
		
		// lists an NFT for sale in this collection
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(token: @Popsycl.NFT){ 
			let id = token.id
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
		}
		
		// lists an pack NFT for sale in this collection
		access(TMP_ENTITLEMENT_OWNER)
		fun packListForSale(token: @PopsyclPack.NFT, price: UFix64){ 
			let id = token.id
			
			// Store the pack price in the price array
			self.packPrices[id] = price
			
			// Store the pack creator in the creator array
			self.packCreators[id] = token.creator
			
			// Store the pack influencer in the influencer array
			self.packInfluencer[id] = token.influencer
			
			// Store the pack royalty in the prroyaltyice array
			self.packRoylty[id] = token.royalty
			
			// Store the pack seller in the seller array
			self.packSeller[id] = self.owner?.address
			
			// Store the pack resale in the resale array
			self.packResale[id] = token.creator == self.owner?.address ? false : true
			
			// Put pack NFT into the forSale dictionary
			let oldToken <- self.packForSale[id] <- token
			destroy oldToken
			emit ForSale(packTokenId: id, price: price)
		}
		
		// Change price of a pack of tokens
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(packId: UInt64, newPrice: UFix64){ 
			pre{ 
				self.tokensExist(tokens: packId, ids: self.packForSale.keys):
					"Tokens not available"
			}
			self.packPrices[packId] = newPrice
			emit PriceChanged(packTokenId: packId, newPrice: newPrice)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun tokensExist(tokens: UInt64, ids: [UInt64]): Bool{ 
			if ids.contains(tokens){ 
				return true
			} else{ 
				return false
			}
		}
		
		// Pack Purchase: Allows an user to send Flow to purchase a pack NFT that is for sale
		access(TMP_ENTITLEMENT_OWNER)
		fun packPurchase(packId: UInt64, tokens: [UInt64], recipient: &{Popsycl.PopsyclCollectionPublic}, payment: @{FungibleToken.Vault}){ 
			pre{ 
				self.packForSale[packId] != nil && self.packPrices[packId] != nil:
					"No token matching this ID for sale!"
				payment.balance >= self.packPrices[packId]!:
					"Not enough Folw to purchase NFT"
			}
			let totalamount = payment.balance
			let owner = self.packInfluencer[packId]!!
			
			// Popvalut reference
			let PopsyclvaultRef = getAccount(PopsyclMarketplace.marketAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("failed to borrow reference to PopsyclPackMarketplace vault")
			// influencer vault reference
			let influencerVaultRef = getAccount(owner).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("failed to borrow reference to owner vault")
			let marketShare = self.flowshare(price: self.packPrices[packId]!, commission: PopsyclMarketplace.marketFee)
			let royalityShare = self.flowshare(price: self.packPrices[packId]!, commission: self.packRoylty[packId]!)
			let marketCut <- payment.withdraw(amount: marketShare)
			let royalityCut <- payment.withdraw(amount: royalityShare)
			PopsyclvaultRef.deposit(from: <-marketCut)
			// Royalty to the original creator / minted user if this is a resale.
			influencerVaultRef.deposit(from: <-royalityCut)
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			if self.packResale[packId]!{ 
				vaultRef.deposit(from: <-payment)
			} else{ 
				influencerVaultRef.deposit(from: <-payment)
			}
			self.packPrices[packId] = nil
			self.packCreators[packId] = nil
			self.packInfluencer[packId] = nil
			self.packRoylty[packId] = nil
			self.packResale[packId] = nil
			self.packSeller[packId] = nil
			for id in tokens{ 
				recipient.deposit(token: <-self.nftwithdraw(id: id))
			}
			emit TokenPurchased(packTokenId: packId, price: totalamount)
			// destroy to the pack nfts
			destroy self.withdraw(id: packId)
		}
		
		// pack flow share
		access(TMP_ENTITLEMENT_OWNER)
		fun flowshare(price: UFix64, commission: UFix64): UFix64{ 
			return price / 100.0 * commission
		}
		
		// Return the FLOW  pack price of a specific token that is listed for sale.
		access(TMP_ENTITLEMENT_OWNER)
		fun packIdPrice(id: UInt64): UFix64?{ 
			return self.packPrices[id]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packIsResale(id: UInt64): Bool?{ 
			return self.packResale[id]
		}
		
		// Returns the owner / original minter of a specific NFT token in the sale
		access(TMP_ENTITLEMENT_OWNER)
		fun packTokenCreator(id: UInt64): Address??{ 
			return self.packCreators[id]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packTokenInfluencer(id: UInt64): Address??{ 
			return self.packInfluencer[id]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun packCurrentTokenOwner(id: UInt64): Address??{ 
			return self.packSeller[id]
		}
		
		// getIDs returns an array of token IDs that are for sale
		access(TMP_ENTITLEMENT_OWNER)
		fun packGetIDs(): [UInt64]{ 
			return self.packForSale.keys
		}
		
		// Withdraw pack NFTs from PopsyclPackMarketplace
		access(TMP_ENTITLEMENT_OWNER)
		fun saleWithdrawn(packId: UInt64){ 
			let owner = self.packSeller[packId]!!
			let receiver = getAccount(owner).capabilities.get<&{PopsyclPack.PopsyclPackCollectionPublic}>(PopsyclPack.PopsyclPackPublicPath).borrow<&{PopsyclPack.PopsyclPackCollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			receiver.deposit(token: <-self.withdraw(id: packId))
			emit SaleWithdrawn(packTokenId: packId)
		}
	}
	
	// createCollection returns a new pack collection resource to the caller
	access(TMP_ENTITLEMENT_OWNER)
	fun createPackSaleCollection(
		ownerVault: Capability<&{FungibleToken.Receiver}>
	): @PackSaleCollection{ 
		return <-create PackSaleCollection(vault: ownerVault)
	}
	
	init(){ 
		self.marketPackPublicPath = /public/PopsyclPackNFTSale
		self.marketPackStoragePath = /storage/PopsyclPackNFTSale
	}
}
