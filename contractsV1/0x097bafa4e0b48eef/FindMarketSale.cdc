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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FindViews from "./FindViews.cdc"

import Clock from "./Clock.cdc"

import FIND from "./FIND.cdc"

import Profile from "./Profile.cdc"

import FindMarket from "./FindMarket.cdc"

/*

A Find Market for direct sales
*/

access(all)
contract FindMarketSale{ 
	access(all)
	event Sale(
		tenant: String,
		id: UInt64,
		saleID: UInt64,
		seller: Address,
		sellerName: String?,
		amount: UFix64,
		status: String,
		vaultType: String,
		nft: FindMarket.NFTInfo?,
		buyer: Address?,
		buyerName: String?,
		buyerAvatar: String?,
		endsAt: UFix64?
	)
	
	//A sale item for a direct sale
	access(all)
	resource SaleItem: FindMarket.SaleItem{ 
		
		//this is set when bought so that pay will work
		access(self)
		var buyer: Address?
		
		access(contract)
		let vaultType: Type //The type of vault to use for this sale Item
		
		
		access(contract)
		var pointer: FindViews.AuthNFTPointer
		
		//this field is set if this is a saleItem
		access(contract)
		var salePrice: UFix64
		
		access(contract)
		var validUntil: UFix64?
		
		access(contract)
		let saleItemExtraField:{ String: AnyStruct}
		
		access(contract)
		let totalRoyalties: UFix64
		
		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, price: UFix64, validUntil: UFix64?, saleItemExtraField:{ String: AnyStruct}){ 
			self.vaultType = vaultType
			self.pointer = pointer
			self.salePrice = price
			self.buyer = nil
			self.validUntil = validUntil
			self.saleItemExtraField = saleItemExtraField
			var royalties: UFix64 = 0.0
			self.totalRoyalties = self.pointer.getTotalRoyaltiesCut()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleType(): String{ 
			return "active_listed"
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getListingType(): Type{ 
			return Type<@SaleItem>()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getListingTypeIdentifier(): String{ 
			return Type<@SaleItem>().identifier
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setBuyer(_ address: Address){ 
			self.buyer = address
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBuyer(): Address?{ 
			return self.buyer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBuyerName(): String?{ 
			if let address = self.buyer{ 
				return FIND.reverseLookup(address)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): UInt64{ 
			return self.pointer.getUUID()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getItemID(): UInt64{ 
			return self.pointer.id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getItemType(): Type{ 
			return self.pointer.getItemType()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalty(): MetadataViews.Royalties{ 
			return self.pointer.getRoyalty()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeller(): Address{ 
			return self.pointer.owner()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSellerName(): String?{ 
			return FIND.reverseLookup(self.pointer.owner())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): UFix64{ 
			return self.salePrice
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuction(): FindMarket.AuctionItem?{ 
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFtType(): Type{ 
			return self.vaultType
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setValidUntil(_ time: UFix64?){ 
			self.validUntil = time
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getValidUntil(): UFix64?{ 
			return self.validUntil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toNFTInfo(_ detail: Bool): FindMarket.NFTInfo{ 
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id, detail: detail)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkPointer(): Bool{ 
			return self.pointer.valid()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkSoulBound(): Bool{ 
			return self.pointer.checkSoulBound()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleItemExtraField():{ String: AnyStruct}{ 
			return self.saleItemExtraField
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTotalRoyalties(): UFix64{ 
			return self.totalRoyalties
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun validateRoyalties(): Bool{ 
			return self.totalRoyalties == self.pointer.getTotalRoyaltiesCut()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplay(): MetadataViews.Display{ 
			return self.pointer.getDisplay()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return self.pointer.getNFTCollectionData()
		}
	}
	
	access(all)
	resource interface SaleItemCollectionPublic{ 
		//fetch all the tokens in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleItem(_ id: UInt64): &{FindMarket.SaleItem} //TODO: look if this is safe
		
		
		access(TMP_ENTITLEMENT_OWNER)
		fun containsId(_ id: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buy(
			id: UInt64,
			vault: @{FungibleToken.Vault},
			nftCap: Capability<&{NonFungibleToken.Receiver}>
		)
	}
	
	access(all)
	resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic{ 
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract)
		var items: @{UInt64: SaleItem}
		
		access(contract)
		let tenantCapability: Capability<&FindMarket.Tenant>
		
		init(_ tenantCapability: Capability<&FindMarket.Tenant>){ 
			self.items <-{} 
			self.tenantCapability = tenantCapability
		}
		
		access(self)
		fun getTenant(): &FindMarket.Tenant{ 
			if !self.tenantCapability.check(){ 
				panic("Tenant client is not linked anymore")
			}
			return self.tenantCapability.borrow()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getListingType(): Type{ 
			return Type<@SaleItem>()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buy(id: UInt64, vault: @{FungibleToken.Vault}, nftCap: Capability<&{NonFungibleToken.Receiver}>){ 
			if !self.items.containsKey(id){ 
				panic("Invalid id=".concat(id.toString()))
			}
			if (self.owner!).address == nftCap.address{ 
				panic("You cannot buy your own listing")
			}
			let saleItem = self.borrow(id)
			if saleItem.salePrice != vault.balance{ 
				panic("Incorrect balance sent in vault. Expected ".concat(saleItem.salePrice.toString()).concat(" got ").concat(vault.balance.toString()))
			}
			if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time(){ 
				panic("This sale item listing is already expired")
			}
			if saleItem.vaultType != vault.getType(){ 
				panic("This item can be bought using ".concat(saleItem.vaultType.identifier).concat(" you have sent in ").concat(vault.getType().identifier))
			}
			let tenant = self.getTenant()
			let ftType = saleItem.vaultType
			let nftType = saleItem.getItemType()
			
			//TOOD: method on saleItems that returns a cacheKey listingType-nftType-ftType
			let actionResult = tenant.allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing: false, name: "buy item for sale"), seller: (self.owner!).address, buyer: nftCap.address)
			if !actionResult.allowed{ 
				panic(actionResult.message)
			}
			let cuts = tenant.getCuts(name: actionResult.name, listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType)
			let nftInfo = saleItem.toNFTInfo(true)
			saleItem.setBuyer(nftCap.address)
			let buyer = nftCap.address
			let buyerName = FIND.reverseLookup(buyer)
			let sellerName = FIND.reverseLookup((self.owner!).address)
			emit Sale(tenant: tenant.name, id: id, saleID: saleItem.uuid, seller: (self.owner!).address, sellerName: FIND.reverseLookup((self.owner!).address), amount: saleItem.getBalance(), status: "sold", vaultType: ftType.identifier, nft: nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: Profile.find(nftCap.address).getAvatar(), endsAt: saleItem.validUntil)
			let resolved:{ Address: String} ={} 
			resolved[buyer] = buyerName ?? ""
			resolved[(self.owner!).address] = sellerName ?? ""
			resolved[FindMarketSale.account.address] = "find"
			// Have to make sure the tenant always have the valid find name
			resolved[FindMarket.tenantNameAddress[tenant.name]!] = tenant.name
			FindMarket.pay(tenant: tenant.name, id: id, saleItem: saleItem, vault: <-vault, royalty: saleItem.getRoyalty(), nftInfo: nftInfo, cuts: cuts, resolver: fun (address: Address): String?{ 
					return FIND.reverseLookup(address)
				}, resolvedAddress: resolved)
			if !nftCap.check(){ 
				let cpCap = getAccount(nftCap.address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(saleItem.getNFTCollectionData().publicPath)
				if !cpCap.check(){ 
					panic("The nft receiver capability passed in is invalid.")
				} else{ 
					(cpCap.borrow()!).deposit(token: <-saleItem.pointer.withdraw())
				}
			} else{ 
				(nftCap.borrow()!).deposit(token: <-saleItem.pointer.withdraw())
			}
			destroy <-self.items.remove(key: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice: UFix64, validUntil: UFix64?, extraField:{ String: AnyStruct}){ 
			
			// ensure it is not a 0 dollar listing
			if directSellPrice <= 0.0{ 
				panic("Listing price should be greater than 0")
			}
			if validUntil != nil && validUntil! < Clock.time(){ 
				panic("Valid until is before current time")
			}
			
			// check soul bound
			if pointer.checkSoulBound(){ 
				panic("This item is soul bounded and cannot be traded")
			}
			
			// What happends if we relist
			let saleItem <- create SaleItem(pointer: pointer, vaultType: vaultType, price: directSellPrice, validUntil: validUntil, saleItemExtraField: extraField)
			let tenant = self.getTenant()
			
			// Check if it is onefootball. If so, listing has to be at least $0.65 (DUC)
			if tenant.name == "onefootball"{ 
				// ensure it is not a 0 dollar listing
				if directSellPrice <= 0.65{ 
					panic("Listing price should be greater than 0.65")
				}
			}
			let nftType = saleItem.getItemType()
			let ftType = saleItem.getFtType()
			let actionResult = tenant.allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing: true, name: "list item for sale"), seller: (self.owner!).address, buyer: nil)
			if !actionResult.allowed{ 
				panic(actionResult.message)
			// let message = "vault : ".concat(vaultType.identifier).concat(" . NFT Type : ".concat(saleItem.getItemType().identifier))
			// panic(message)
			}
			let owner = (self.owner!).address
			emit Sale(tenant: tenant.name, id: pointer.getUUID(), saleID: saleItem.uuid, seller: owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "active_listed", vaultType: vaultType.identifier, nft: saleItem.toNFTInfo(true), buyer: nil, buyerName: nil, buyerAvatar: nil, endsAt: saleItem.validUntil)
			let old <- self.items[pointer.getUUID()] <- saleItem
			destroy old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun delist(_ id: UInt64){ 
			if !self.items.containsKey(id){ 
				panic("Unknown item with id=".concat(id.toString()))
			}
			let saleItem <- self.items.remove(key: id)!
			let tenant = self.getTenant()
			var status = "cancel"
			var nftInfo: FindMarket.NFTInfo? = nil
			if saleItem.checkPointer(){ 
				nftInfo = saleItem.toNFTInfo(false)
			}
			let owner = (self.owner!).address
			emit Sale(tenant: tenant.name, id: id, saleID: saleItem.uuid, seller: owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: status, vaultType: saleItem.vaultType.identifier, nft: nftInfo, buyer: nil, buyerName: nil, buyerAvatar: nil, endsAt: saleItem.validUntil)
			destroy saleItem
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun relist(_ id: UInt64){ 
			let saleItem = self.borrow(id)
			let pointer = saleItem.pointer
			let vaultType = saleItem.vaultType
			let directSellPrice = saleItem.salePrice
			var validUntil = saleItem.validUntil
			if validUntil != nil && saleItem.validUntil! <= Clock.time(){ 
				validUntil = nil
			}
			let extraField = saleItem.saleItemExtraField
			self.delist(id)
			self.listForSale(pointer: *pointer, vaultType: vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: *extraField)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt64]{ 
			return self.items.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyChangedIds(): [UInt64]{ 
			let ids: [UInt64] = []
			for id in self.getIds(){ 
				let item = self.borrow(id)
				if !item.validateRoyalties(){ 
					ids.append(id)
				}
			}
			return ids
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun containsId(_ id: UInt64): Bool{ 
			return self.items.containsKey(id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(_ id: UInt64): &SaleItem{ 
			return (&self.items[id] as &SaleItem?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleItem(_ id: UInt64): &{FindMarket.SaleItem}{ 
			if !self.items.containsKey(id){ 
				panic("This id does not exist : ".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem?)!
		}
	}
	
	//Create an empty lease collection that store your leases to a name
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptySaleItemCollection(
		_ tenantCapability: Capability<&FindMarket.Tenant>
	): @SaleItemCollection{ 
		return <-create SaleItemCollection(tenantCapability)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSaleItemCapability(marketplace: Address, user: Address): Capability<
		&FindMarketSale.SaleItemCollection
	>?{ 
		if let tenantCap = FindMarket.getTenantCapability(marketplace){ 
			let tenant = tenantCap.borrow() ?? panic("Invalid tenant")
			return getAccount(user).capabilities.get<&FindMarketSale.SaleItemCollection>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}
	
	init(){ 
		FindMarket.addSaleItemType(Type<@SaleItem>())
		FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
	}
}
