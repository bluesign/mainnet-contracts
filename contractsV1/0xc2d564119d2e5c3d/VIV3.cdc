import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract VIV3{ 
	
	// -----------------------------------------------------------------------
	// VIV3 contract Event definitions
	// -----------------------------------------------------------------------
	
	// emitted when a token is listed for sale
	access(all)
	event TokenListed(id: UInt64, type: Type, price: UFix64, seller: Address?)
	
	// emitted when the price of a listed token has changed
	access(all)
	event TokenPriceChanged(id: UInt64, type: Type, price: UFix64, seller: Address?)
	
	// emitted when a token is purchased
	access(all)
	event TokenPurchased(id: UInt64, type: Type, price: UFix64, seller: Address?)
	
	// emitted when a token has been withdrawn from the sale
	access(all)
	event TokenWithdrawn(id: UInt64, type: Type, owner: Address?)
	
	// emitted when the fee  of the sale has been changed by the owner
	access(all)
	event FeeChanged(fee: UFix64, seller: Address?)
	
	// emitted when the royalty fee has been changed by the owner
	access(all)
	event RoyaltyChanged(royalty: UFix64, seller: Address?)
	
	access(all)
	resource interface TokenSale{ 
		access(all)
		var fee: UFix64
		
		access(all)
		var royalty: UFix64
		
		access(all)
		fun purchase(tokenId: UInt64, kind: Type, vault: @{FungibleToken.Vault}): @{
			NonFungibleToken.NFT
		}{ 
			post{ 
				result.id == tokenId:
					"The Id of the withdrawn token must be the same as the requested Id"
				result.isInstance(kind):
					"The Type of the withdrawn token must be the same as the requested Type"
			}
		}
		
		access(all)
		fun getPrice(tokenId: UInt64): UFix64?
	}
	
	access(all)
	resource TokenSaleCollection: TokenSale{ 
		access(self)
		var collection: Capability<&{NonFungibleToken.Collection}>
		
		access(self)
		var prices:{ UInt64: UFix64}
		
		access(self)
		var ownerCapability: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		var beneficiaryCapability: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		var royaltyCapability: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		var fee: UFix64
		
		access(all)
		var royalty: UFix64
		
		access(all)
		let currency: Type
		
		init(collection: Capability<&{NonFungibleToken.Collection}>, ownerCapability: Capability<&{FungibleToken.Receiver}>, beneficiaryCapability: Capability<&{FungibleToken.Receiver}>, royaltyCapability: Capability<&{FungibleToken.Receiver}>, fee: UFix64, royalty: UFix64, currency: Type){ 
			pre{ 
				collection.borrow() != nil:
					"Owner's Token Collection Capability is invalid!"
				ownerCapability.borrow() != nil:
					"Owner's Receiver Capability is invalid!"
				beneficiaryCapability.borrow() != nil:
					"Beneficiary's Receiver Capability is invalid!"
				royaltyCapability.borrow() != nil:
					"Royalties Receiver Capability is invalid!"
			}
			self.collection = collection
			self.ownerCapability = ownerCapability
			self.beneficiaryCapability = beneficiaryCapability
			self.royaltyCapability = royaltyCapability
			self.prices ={} 
			self.fee = fee
			self.royalty = royalty
			self.currency = currency
		}
		
		access(all)
		view fun tokenSaleEnabled(): Bool{ 
			return false
		}
		
		access(all)
		fun listForSale(tokenId: UInt64, price: UFix64){ 
			pre{ 
				self.tokenSaleEnabled() == true:
					"Token listing has been disabled"
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			let token = (self.collection.borrow()!).borrowNFT(tokenId)
			let uuid = token.uuid
			self.prices[uuid] = price
			emit TokenListed(id: token.id, type: token.getType(), price: price, seller: self.owner?.address)
		}
		
		access(all)
		fun cancelSale(tokenId: UInt64){ 
			pre{ 
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			let token = (self.collection.borrow()!).borrowNFT(tokenId)
			let uuid = token.uuid
			assert(self.prices[uuid] != nil, message: "No token with this Id on sale!")
			self.prices.remove(key: uuid)
			self.prices[uuid] = nil
			emit TokenWithdrawn(id: token.id, type: token.getType(), owner: self.owner?.address)
		}
		
		access(all)
		fun purchase(tokenId: UInt64, kind: Type, vault: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.tokenSaleEnabled() == true:
					"Token sale has been disabled"
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"No token matching this Id in collection!"
				vault.isInstance(self.currency):
					"Vault does not hold the required currency type"
			}
			let token = (self.collection.borrow()!).borrowNFT(tokenId)
			let uuid = token.uuid
			assert(self.prices[uuid] != nil, message: "No token with this Id on sale!")
			assert(vault.balance == self.prices[uuid] ?? UFix64(0), message: "Amount does not match the token price")
			let price = self.prices[uuid]!
			self.prices[uuid] = nil
			var amount = price * self.fee
			if amount > vault.balance{ 
				amount = vault.balance
			}
			let beneficiaryFee <- vault.withdraw(amount: amount)
			(self.beneficiaryCapability.borrow()!).deposit(from: <-beneficiaryFee)
			var royaltyAmount = price * self.royalty
			if royaltyAmount > vault.balance{ 
				royaltyAmount = vault.balance
			}
			let royaltyFee <- vault.withdraw(amount: royaltyAmount)
			(self.royaltyCapability.borrow()!).deposit(from: <-royaltyFee)
			(self.ownerCapability.borrow()!).deposit(from: <-vault)
			emit TokenPurchased(id: token.id, type: token.getType(), price: price, seller: self.owner?.address)
			return <-(self.collection.borrow()!).withdraw(withdrawID: token.id)
		}
		
		access(all)
		fun changePrice(tokenId: UInt64, price: UFix64){ 
			pre{ 
				self.tokenSaleEnabled() == true:
					"Token listing has been disabled"
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			let token = (self.collection.borrow()!).borrowNFT(tokenId)
			let uuid = token.uuid
			assert(self.prices[uuid] != nil, message: "No token with this Id on sale!")
			self.prices[uuid] = price
			emit TokenPriceChanged(id: token.id, type: token.getType(), price: price, seller: self.owner?.address)
		}
		
		access(all)
		fun changeFee(_ fee: UFix64){ 
			self.fee = fee
			emit FeeChanged(fee: self.fee, seller: self.owner?.address)
		}
		
		access(all)
		fun changeRoyalty(_ royalty: UFix64){ 
			self.royalty = royalty
			emit RoyaltyChanged(royalty: self.royalty, seller: self.owner?.address)
		}
		
		access(all)
		fun changeOwnerReceiver(_ newOwnerCapability: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				newOwnerCapability.borrow() != nil:
					"Owner's Receiver Capability is invalid!"
			}
			self.ownerCapability = newOwnerCapability
		}
		
		access(all)
		fun changeBeneficiaryReceiver(_ newBeneficiaryCapability: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				newBeneficiaryCapability.borrow() != nil:
					"Beneficiary's Receiver Capability is invalid!"
			}
			self.beneficiaryCapability = newBeneficiaryCapability
		}
		
		access(all)
		fun changeRoyaltyReceiver(_ newRoyaltyCapability: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				newRoyaltyCapability.borrow() != nil:
					"Royalties's Receiver Capability is invalid!"
			}
			self.royaltyCapability = newRoyaltyCapability
		}
		
		access(all)
		fun getPrice(tokenId: UInt64): UFix64?{ 
			if let cap = self.collection.borrow(){ 
				if (cap!).getIDs().contains(tokenId){ 
					let token = (cap!).borrowNFT(tokenId)
					return self.prices[token.uuid]
				}
			}
			return nil
		}
	}
	
	access(all)
	fun createTokenSaleCollection(
		collection: Capability<&{NonFungibleToken.Collection}>,
		ownerCapability: Capability<&{FungibleToken.Receiver}>,
		beneficiaryCapability: Capability<&{FungibleToken.Receiver}>,
		royaltyCapability: Capability<&{FungibleToken.Receiver}>,
		fee: UFix64,
		royalty: UFix64,
		currency: Type
	): @TokenSaleCollection{ 
		return <-create TokenSaleCollection(
			collection: collection,
			ownerCapability: ownerCapability,
			beneficiaryCapability: beneficiaryCapability,
			royaltyCapability: royaltyCapability,
			fee: fee,
			royalty: royalty,
			currency: currency
		)
	}
}
