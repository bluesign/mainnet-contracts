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

	// Black Hunter's Market
// Yosh! -swt
//
//
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFTDayTreasureChest from "./NFTDayTreasureChest.cdc"

access(all)
contract BlackMarketplace{ 
	
	// -----------------------------------------------------------------------
	// BlackMarketplace Events
	// -----------------------------------------------------------------------
	access(all)
	event ForSale(id: UInt64, price: UFix64)
	
	access(all)
	event PriceChanged(id: UInt64, newPrice: UFix64)
	
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64, from: Address, to: Address)
	
	access(all)
	event RoyaltyPaid(id: UInt64, amount: UFix64, to: Address, name: String)
	
	access(all)
	event SaleWithdrawn(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let marketplaceWallet: Capability<&FUSD.Vault>
	
	access(contract)
	var whitelistUsed: [Address]
	
	access(contract)
	var sellers: [Address]
	
	access(all)
	resource interface SalePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun purchaseWithWhitelist(
			tokenID: UInt64,
			recipientCap: Capability<&{NFTDayTreasureChest.NFTDayTreasureChestCollectionPublic}>,
			buyTokens: @{FungibleToken.Vault}
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchaseWithTreasureChest(
			tokenID: UInt64,
			recipientCap: Capability<&{NFTDayTreasureChest.NFTDayTreasureChestCollectionPublic}>,
			buyTokens: @{FungibleToken.Vault},
			chest: @NFTDayTreasureChest.NFT
		): @NFTDayTreasureChest.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idPrice(tokenID: UInt64): UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
	}
	
	access(all)
	resource SaleCollection: SalePublic{ 
		access(self)
		var forSale: @{UInt64: NFTDayTreasureChest.NFT}
		
		access(self)
		var prices:{ UInt64: UFix64}
		
		access(account)
		let ownerVault: Capability<&{FungibleToken.Receiver}>
		
		init(vault: Capability<&{FungibleToken.Receiver}>){ 
			self.forSale <-{} 
			self.ownerVault = vault
			self.prices ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(tokenID: UInt64): @NFTDayTreasureChest.NFT{ 
			self.prices.remove(key: tokenID)
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			emit SaleWithdrawn(id: tokenID)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(token: @NFTDayTreasureChest.NFT, price: UFix64){ 
			let id = token.id
			self.prices[id] = price
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
			if !BlackMarketplace.sellers.contains((self.owner!).address){ 
				BlackMarketplace.sellers.append((self.owner!).address)
			}
			emit ForSale(id: id, price: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(tokenID: UInt64, newPrice: UFix64){ 
			self.prices[tokenID] = newPrice
			emit PriceChanged(id: tokenID, newPrice: newPrice)
		}
		
		// Requires a whitelist to purchase
		access(TMP_ENTITLEMENT_OWNER)
		fun purchaseWithWhitelist(tokenID: UInt64, recipientCap: Capability<&{NFTDayTreasureChest.NFTDayTreasureChestCollectionPublic}>, buyTokens: @{FungibleToken.Vault}){ 
			pre{ 
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance >= self.prices[tokenID] ?? 0.0:
					"Not enough tokens to by the NFT!"
				!BlackMarketplace.whitelistUsed.contains(((recipientCap.borrow()!).owner!).address):
					"Cannot purchase: Whitelist used"
				NFTDayTreasureChest.getWhitelist().contains(((recipientCap.borrow()!).owner!).address):
					"Cannot purchase: Must be whitelisted"
			}
			let recipient = recipientCap.borrow()!
			let price = self.prices[tokenID]!
			self.prices[tokenID] = nil
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			let token <- self.withdraw(tokenID: tokenID)
			let marketplaceWallet = BlackMarketplace.marketplaceWallet.borrow()!
			let marketplaceFee = price * 0.05 // 5% marketplace cut
			
			marketplaceWallet.deposit(from: <-buyTokens.withdraw(amount: marketplaceFee))
			emit RoyaltyPaid(id: tokenID, amount: marketplaceFee, to: (marketplaceWallet.owner!).address, name: "Marketplace")
			vaultRef.deposit(from: <-buyTokens)
			recipient.deposit(token: <-token)
			BlackMarketplace.whitelistUsed.append((recipient.owner!).address)
			emit TokenPurchased(id: tokenID, price: price, from: (vaultRef.owner!).address, to: (recipient.owner!).address)
		}
		
		// Requires a chest to purchase
		access(TMP_ENTITLEMENT_OWNER)
		fun purchaseWithTreasureChest(tokenID: UInt64, recipientCap: Capability<&{NFTDayTreasureChest.NFTDayTreasureChestCollectionPublic}>, buyTokens: @{FungibleToken.Vault}, chest: @NFTDayTreasureChest.NFT): @NFTDayTreasureChest.NFT{ 
			pre{ 
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance >= self.prices[tokenID] ?? 0.0:
					"Not enough tokens to by the NFT!"
			}
			let recipient = recipientCap.borrow()!
			let price = self.prices[tokenID]!
			self.prices[tokenID] = nil
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			let token <- self.withdraw(tokenID: tokenID)
			let marketplaceWallet = BlackMarketplace.marketplaceWallet.borrow()!
			let marketplaceFee = price * 0.05 // 5% marketplace cut
			
			marketplaceWallet.deposit(from: <-buyTokens.withdraw(amount: marketplaceFee))
			emit RoyaltyPaid(id: tokenID, amount: marketplaceFee, to: (marketplaceWallet.owner!).address, name: "Marketplace")
			vaultRef.deposit(from: <-buyTokens)
			recipient.deposit(token: <-token)
			emit TokenPurchased(id: tokenID, price: price, from: (vaultRef.owner!).address, to: (recipient.owner!).address)
			return <-chest
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @SaleCollection{ 
		return <-create SaleCollection(vault: ownerVault)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhitelistUsed(): [Address]{ 
		return self.whitelistUsed
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSellers(): [Address]{ 
		return self.sellers
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/BasicBeastsBlackMarketplace
		self.CollectionPublicPath = /public/BasicBeastsBlackMarketplace
		if self.account.storage.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil{ 
			// Create a new FUSD Vault and put it in storage
			self.account.storage.save(<-FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>()), to: /storage/fusdVault)
			
			// Create a public capability to the Vault that only exposes
			// the deposit function through the Receiver interface
			var capability_1 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
			self.account.capabilities.publish(capability_1, at: /public/fusdReceiver)
			
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			var capability_2 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
			self.account.capabilities.publish(capability_2, at: /public/fusdBalance)
		}
		self.marketplaceWallet = self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
		self.whitelistUsed = []
		self.sellers = []
	}
}
