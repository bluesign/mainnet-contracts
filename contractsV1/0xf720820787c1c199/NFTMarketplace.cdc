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

	// NOTE: I deployed this to 0x05 in the playground
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MyNFT from "./MyNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract NFTMarketplace{ 
	access(all)
	event ListForSale(id: UInt64, from: Address?, price: UFix64, publicId: String)
	
	access(all)
	struct SaleItem{ 
		access(all)
		let price: UFix64
		
		access(all)
		let nftRef: &MyNFT.NFT
		
		init(_price: UFix64, _nftRef: &MyNFT.NFT){ 
			self.price = _price
			self.nftRef = _nftRef
		}
	}
	
	access(all)
	resource interface SaleCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice(id: UInt64): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(id: UInt64, recipientCollection: &MyNFT.Collection, payment: @FlowToken.Vault)
	}
	
	access(all)
	resource SaleCollection: SaleCollectionPublic{ 
		// maps the id of the NFT --> the price of that NFT
		access(all)
		var forSale:{ UInt64: UFix64}
		
		access(all)
		let MyNFTCollection: Capability<&MyNFT.Collection>
		
		access(all)
		let FlowTokenVault: Capability<&FlowToken.Vault>
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(id: UInt64, price: UFix64, data: String){ 
			pre{ 
				price >= 0.0:
					"It doesn't make sense to list a token for less than 0.0"
				(self.MyNFTCollection.borrow()!).getIDs().contains(id):
					"This SaleCollection owner does not have this NFT"
			}
			self.forSale[id] = price
			emit ListForSale(id: id, from: self.owner?.address, price: price, publicId: data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unlistFromSale(id: UInt64){ 
			self.forSale.remove(key: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(id: UInt64, recipientCollection: &MyNFT.Collection, payment: @FlowToken.Vault){ 
			pre{ 
				payment.balance == self.forSale[id]:
					"The payment is not equal to the price of the NFT"
			}
			recipientCollection.deposit(token: <-(self.MyNFTCollection.borrow()!).withdraw(withdrawID: id))
			(self.FlowTokenVault.borrow()!).deposit(from: <-payment)
			self.unlistFromSale(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice(id: UInt64): UFix64{ 
			return self.forSale[id]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		init(_MyNFTCollection: Capability<&MyNFT.Collection>, _FlowTokenVault: Capability<&FlowToken.Vault>){ 
			self.forSale ={} 
			self.MyNFTCollection = _MyNFTCollection
			self.FlowTokenVault = _FlowTokenVault
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleCollection(
		MyNFTCollection: Capability<&MyNFT.Collection>,
		FlowTokenVault: Capability<&FlowToken.Vault>
	): @SaleCollection{ 
		return <-create SaleCollection(
			_MyNFTCollection: MyNFTCollection,
			_FlowTokenVault: FlowTokenVault
		)
	}
	
	init(){} 
}
