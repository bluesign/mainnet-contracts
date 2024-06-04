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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ProjectR from "./ProjectR.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Rumble from "../0x078f3716ca07719a/Rumble.cdc"

access(all)
contract BloxmithMarketplace{ 
	access(all)
	event NFTListing(id: UInt64, amount: UFix64)
	
	access(all)
	event NFTPurchase(id: UInt64, new_owner: Address?)
	
	access(all)
	let SaleCollectionStoragePath: StoragePath
	
	access(all)
	let SaleCollectionPublicPath: PublicPath
	
	access(all)
	struct SaleItem{ 
		access(all)
		let price: UFix64
		
		access(all)
		let nftRef: &ProjectR.NFT
		
		init(_price: UFix64, _nftRef: &ProjectR.NFT){ 
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
		fun purchase(
			id: UInt64,
			newOwner: Address,
			recipientCollection: &ProjectR.Collection,
			payment: @Rumble.Vault
		)
	}
	
	access(all)
	resource SaleCollection: SaleCollectionPublic{ 
		// maps the id of the NFT --> the price of that NFT
		access(all)
		var forSale:{ UInt64: UFix64}
		
		access(all)
		let ProjectRCollection: Capability<&ProjectR.Collection>
		
		access(all)
		let TokenVault: Capability<&Rumble.Vault>
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(id: UInt64, price: UFix64){ 
			pre{ 
				price >= 0.0:
					"Price must be more that 0.0"
				(self.ProjectRCollection.borrow()!).getIDs().contains(id):
					"This SaleCollection owner does not contain this NFT"
			}
			self.forSale[id] = price
			emit NFTListing(id: id, amount: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unlistFromSale(id: UInt64){ 
			self.forSale.remove(key: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(id: UInt64, newOwner: Address, recipientCollection: &ProjectR.Collection, payment: @Rumble.Vault){ 
			pre{ 
				payment.balance == self.forSale[id]:
					"The payment balance is not equal to the NFT price"
			}
			recipientCollection.deposit(token: <-(self.ProjectRCollection.borrow()!).withdraw(withdrawID: id))
			(self.TokenVault.borrow()!).deposit(from: <-payment)
			self.unlistFromSale(id: id)
			emit NFTPurchase(id: id, new_owner: newOwner)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice(id: UInt64): UFix64{ 
			return self.forSale[id]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		init(_ProjectRCollection: Capability<&ProjectR.Collection>, _TokenVault: Capability<&Rumble.Vault>){ 
			self.forSale ={} 
			self.ProjectRCollection = _ProjectRCollection
			self.TokenVault = _TokenVault
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleCollection(
		ProjectRCollection: Capability<&ProjectR.Collection>,
		TokenVault: Capability<&Rumble.Vault>
	): @SaleCollection{ 
		return <-create SaleCollection(
			_ProjectRCollection: ProjectRCollection,
			_TokenVault: TokenVault
		)
	}
	
	init(){ 
		self.SaleCollectionStoragePath = /storage/SaleCollection
		self.SaleCollectionPublicPath = /public/SaleCollection
	}
}
