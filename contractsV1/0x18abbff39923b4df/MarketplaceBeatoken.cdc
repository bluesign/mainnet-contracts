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

	// SPDX-License-Identifier: UNLICENSED
import FungibleBeatoken from "./FungibleBeatoken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NonFungibleBeatoken from "./NonFungibleBeatoken.cdc"

access(all)
contract MarketplaceBeatoken{ 
	access(all)
	let publicSale: PublicPath
	
	access(all)
	let storageSale: StoragePath
	
	access(all)
	event ForSale(id: UInt64, price: UFix64)
	
	access(all)
	event PriceChanged(id: UInt64, newPrice: UFix64)
	
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64)
	
	access(all)
	event SaleWithdrawn(id: UInt64)
	
	access(all)
	resource interface SalePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(
			tokenID: UInt64,
			recipient: &NonFungibleBeatoken.Collection,
			buyTokens: @FungibleBeatoken.Vault
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idPrice(tokenID: UInt64): UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
	}
	
	access(all)
	resource SaleCollection: SalePublic{ 
		access(self)
		let ownerCollection: Capability<&NonFungibleBeatoken.Collection>
		
		access(self)
		let ownerVault: Capability<&FungibleBeatoken.Vault>
		
		access(self)
		let prices:{ UInt64: UFix64}
		
		access(all)
		var forSale: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(collection: Capability<&NonFungibleBeatoken.Collection>, vault: Capability<&FungibleBeatoken.Vault>){ 
			pre{ 
				collection.check():
					"Owner's Moment Collection Capability is invalid!"
				vault.check():
					"Owner's Receiver Capability is invalid!"
			}
			self.forSale <-{} 
			self.prices ={} 
			self.ownerCollection = collection
			self.ownerVault = vault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(tokenID: UInt64): @{NonFungibleToken.NFT}{ 
			self.prices.remove(key: tokenID)
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			emit SaleWithdrawn(id: tokenID)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(token: @{NonFungibleToken.NFT}, price: UFix64){ 
			let id = token.id
			self.prices[id] = price
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
			emit ForSale(id: id, price: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(tokenID: UInt64, newPrice: UFix64){ 
			self.prices[tokenID] = newPrice
			emit PriceChanged(id: tokenID, newPrice: newPrice)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(tokenID: UInt64, recipient: &NonFungibleBeatoken.Collection, buyTokens: @FungibleBeatoken.Vault){ 
			pre{ 
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance >= self.prices[tokenID] ?? 0.0:
					"Not enough tokens to by the NFT!"
			}
			let price = self.prices[tokenID]!
			self.prices[tokenID] = nil
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			vaultRef.deposit(from: <-buyTokens)
			recipient.deposit(token: <-self.withdraw(tokenID: tokenID))
			emit TokenPurchased(id: tokenID, price: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			return &self.forSale[id] as &{NonFungibleToken.NFT}?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelSale(tokenID: UInt64, recipient: &NonFungibleBeatoken.Collection){ 
			pre{ 
				self.prices[tokenID] != nil:
					"Token with the specified ID is not already for sale"
			}
			self.prices.remove(key: tokenID)
			self.prices[tokenID] = nil
			recipient.deposit(token: <-self.withdraw(tokenID: tokenID))
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleCollection(
		ownerCollection: Capability<&NonFungibleBeatoken.Collection>,
		ownerVault: Capability<&FungibleBeatoken.Vault>
	): @SaleCollection{ 
		return <-create SaleCollection(collection: ownerCollection, vault: ownerVault)
	}
	
	init(){ 
		self.publicSale = /public/beatokenNFTSale
		self.storageSale = /storage/beatokenNFTSale
	}
}
