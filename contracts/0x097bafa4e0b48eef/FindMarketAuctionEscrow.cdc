import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FindViews from "./FindViews.cdc"
import Clock from "./Clock.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import Profile from "./Profile.cdc"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
pub contract FindMarketAuctionEscrow {

	pub event EnglishAuction(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar:String?, startsAt: UFix64?, endsAt: UFix64?, previousBuyer:Address?, previousBuyerName:String?)

	pub resource SaleItem : FindMarket.SaleItem {
		access(contract) var pointer: FindViews.AuthNFTPointer

		access(contract) var vaultType: Type
		access(contract) var auctionStartPrice: UFix64
		access(contract) var auctionReservePrice: UFix64
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var auctionStartedAt: UFix64?
		access(contract) var auctionValidUntil: UFix64?
		access(contract) var auctionEndsAt: UFix64?
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?
		access(contract) let totalRoyalties: UFix64
		access(contract) let saleItemExtraField: {String : AnyStruct}

		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64, auctionDuration: UFix64, extentionOnLateBid:UFix64, minimumBidIncrement:UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.auctionStartPrice=auctionStartPrice
			self.auctionReservePrice=auctionReservePrice
			self.auctionDuration=auctionDuration
			self.auctionExtensionOnLateBid=extentionOnLateBid
			self.auctionMinBidIncrement=minimumBidIncrement
			self.offerCallback=nil
			self.auctionStartedAt=nil
			self.auctionEndsAt=nil
			self.auctionValidUntil=auctionValidUntil
			self.saleItemExtraField=saleItemExtraField
			self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
		}

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun acceptEscrowedBid() : @FungibleToken.Vault {
			if !self.offerCallback!.check()  {
				panic("bidder unlinked the bid collection capability. bidder address : ".concat(self.offerCallback!.address.toString()))
			}
			let path = self.pointer.getNFTCollectionData().publicPath
			let vault <- self.offerCallback!.borrow()!.accept(<- self.pointer.withdraw(), path: path)
			return <- vault
		}

		pub fun getRoyalty() : MetadataViews.Royalties {
			return self.pointer.getRoyalty()
		}

		pub fun getBalance() : UFix64 {
			if let cb= self.offerCallback {
				if !cb.check() {
					panic("Bidder unlinked the bid collection capability. bidder address : ".concat(cb.address.toString()))
				}
				return cb.borrow()!.getBalance(self.getId())
			}
			return self.auctionStartPrice
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun getSellerName() : String? {
			let address = self.pointer.owner()
			return FIND.reverseLookup(address)
		}

		pub fun getBuyer() : Address? {
			if let cb= self.offerCallback {
				return cb.address
			}
			return nil
		}

		pub fun getBuyerName() : String? {
			if let cb= self.offerCallback {
				return FIND.reverseLookup(cb.address)
			}
			return nil
		}

		pub fun toNFTInfo(_ detail: Bool) : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id, detail:detail)
		}

		pub fun setAuctionStarted(_ startedAt: UFix64) {
			self.auctionStartedAt=startedAt
		}

		pub fun setAuctionEnds(_ endsAt: UFix64){
			self.auctionEndsAt=endsAt
		}

		pub fun hasAuctionStarted() : Bool {
			if let starts = self.auctionStartedAt {
				return starts <= Clock.time()
			}
			return false
		}

		pub fun hasAuctionEnded() : Bool {
			if let ends = self.auctionEndsAt {
				return ends < Clock.time()
			}
			panic("Not a live auction")
		}

		pub fun hasAuctionMetReservePrice() : Bool {

			let balance=self.getBalance()

			if self.auctionReservePrice== nil {
				return false
			}

			return balance >= self.auctionReservePrice
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setAuctionDuration(_ duration: UFix64) {
			self.auctionDuration=duration
		}

		pub fun setReservePrice(_ price: UFix64) {
			self.auctionReservePrice=price
		}

		pub fun setMinBidIncrement(_ price: UFix64) {
			self.auctionMinBidIncrement=price
		}

		pub fun setStartAuctionPrice(_ price: UFix64) {
			self.auctionStartPrice=price
		}

		pub fun setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?) {
			self.offerCallback=callback
		}


		pub fun getSaleType(): String {
			if self.auctionStartedAt != nil {
				if self.hasAuctionEnded() {
					if self.hasAuctionMetReservePrice() {
						return "finished_completed"
					}
					return "finished_failed"
				}
				return "active_ongoing"
			}
			return "active_listed"
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier(): String {
			return Type<@SaleItem>().identifier
		}


		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return FindMarket.AuctionItem(startPrice: self.auctionStartPrice,
			currentPrice: self.getBalance(),
			minimumBidIncrement: self.auctionMinBidIncrement ,
			reservePrice: self.auctionReservePrice,
			extentionOnLateBid: self.auctionExtensionOnLateBid ,
			auctionEndsAt: self.auctionEndsAt ,
			timestamp: Clock.time())
		}

		pub fun getFtType() : Type {
			return self.vaultType
		}

		pub fun setValidUntil(_ time: UFix64?) {
			self.auctionValidUntil=time
		}

		pub fun getValidUntil() : UFix64? {
			if self.hasAuctionStarted() {
				return self.auctionEndsAt
			}
			return self.auctionValidUntil
		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}

		pub fun checkSoulBound() : Bool {
			return self.pointer.checkSoulBound()
		}

		pub fun getSaleItemExtraField() : {String : AnyStruct} {
			return self.saleItemExtraField
		}

		pub fun getTotalRoyalties() : UFix64 {
			return self.totalRoyalties
		}

		pub fun validateRoyalties() : Bool {
			return self.totalRoyalties == self.pointer.getTotalRoyaltiesCut()
		}

		pub fun getDisplay() : MetadataViews.Display {
			return self.pointer.getDisplay()
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			return self.pointer.getNFTCollectionData()
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		pub fun containsId(_ id: UInt64): Bool
		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64)

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64)
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}


		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			if !self.tenantCapability.check()  {
				panic("Tenant client is not linked anymore")
			}
			return self.tenantCapability.borrow()!
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, oldBalance:UFix64) {
			let saleItem=self.borrow(id)


			let tenant=self.getTenant()
			let nftType=saleItem.getItemType()
			let ftType=saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name:"add bid in auction"), seller: self.owner!.address, buyer: newOffer.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let timestamp=Clock.time()
			let newOfferBalance=newOffer.borrow()?.getBalance(id) ?? panic("The new offer bid capability is invalid.")

			let previousOffer = saleItem.offerCallback

			var minBid=oldBalance + saleItem.auctionMinBidIncrement
			if previousOffer != nil && newOffer.address != previousOffer!.address {
				minBid = previousOffer!.borrow()!.getBalance(id) + saleItem.auctionMinBidIncrement
			}

			if newOfferBalance < minBid {
				panic("bid ".concat(newOfferBalance.toString()).concat(" must be larger then previous bid+bidIncrement ").concat(minBid.toString()))
			}

			var previousBuyer:Address?=nil
			if previousOffer != nil && newOffer.address != previousOffer!.address {
				if !previousOffer!.check() {
					panic("Previous bidder unlinked the bid collection capability. bidder address : ".concat(previousOffer!.address.toString()))
				}
				previousOffer!.borrow()!.cancelBidFromSaleItem(id)
				previousBuyer=previousOffer!.address
			}

			saleItem.setCallback(newOffer)

			let suggestedEndTime=timestamp+saleItem.auctionExtensionOnLateBid

			if suggestedEndTime > saleItem.auctionEndsAt! {
				saleItem.setAuctionEnds(suggestedEndTime)
			}

			let status="active_ongoing"

			let seller=self.owner!.address

			let nftInfo=saleItem.toNFTInfo(true)

			var previousBuyerName : String?=nil
			if let pb= previousBuyer {
				previousBuyerName = FIND.reverseLookup(pb)
			}

			let buyer=newOffer.address

			let buyerName=FIND.reverseLookup(buyer!)
			let profile = Profile.find(buyer!)
			emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: newOfferBalance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(),startsAt: saleItem.auctionStartedAt, endsAt: saleItem.auctionEndsAt, previousBuyer: previousBuyer, previousBuyerName:previousBuyerName)


		}

		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64) {

			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}

			let saleItem=self.borrow(id)

			if !saleItem.hasAuctionStarted() {
				panic("Auction is not started")
			}

			if saleItem.hasAuctionEnded() {
				panic("Auction has ended")
			}

			self.addBid(id: id, newOffer: saleItem.offerCallback!, oldBalance:oldBalance)
		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			let saleItem=self.borrow(id)

			if saleItem.hasAuctionStarted() {
				if saleItem.hasAuctionEnded() {
					panic("Auction has ended")
				}

				if let cb = saleItem.offerCallback {
					if cb.address == callback.address {
						panic("You already have the latest bid on this item, use the incraseBid transaction")
					}
				}

				self.addBid(id: id, newOffer: callback, oldBalance: saleItem.auctionStartPrice)
				return
			}

			// If the auction is not started but the start time is set, it falls in here
			if let startTime = saleItem.auctionStartedAt {
				panic("Auction is not yet started, please place your bid after ".concat(startTime.toString()))
			}

			let tenant=self.getTenant()
			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "bid in auction"), seller: self.owner!.address, buyer: callback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()?.getBalance(id) ?? panic("Bidder unlinked bid collection capability. bidder address : ".concat(callback.address.toString()))

			if saleItem.auctionStartPrice >  balance {
				panic("You need to bid more then the starting price of ".concat(saleItem.auctionStartPrice.toString()))
			}

			if let valid = saleItem.getValidUntil() {
				if valid < Clock.time() {
					panic("This auction listing is already expired")
				}
			}
			saleItem.setCallback(callback)
			let duration=saleItem.auctionDuration
			let endsAt=timestamp + duration
			saleItem.setAuctionStarted(timestamp)
			saleItem.setAuctionEnds(endsAt)

			let status="active_ongoing"
			let seller=self.owner!.address
			let buyer=callback.address

			let nftInfo=saleItem.toNFTInfo(true)

			let buyerName=FIND.reverseLookup(buyer)
			let profile = Profile.find(buyer)
			emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(),startsAt: saleItem.auctionStartedAt, endsAt: saleItem.auctionEndsAt, previousBuyer: nil, previousBuyerName:nil)

		}

		pub fun cancel(_ id: UInt64) {

			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}

			let saleItem=self.borrow(id)

			var status = "cancel_listing"
			if saleItem.checkPointer() {
				if !saleItem.validateRoyalties() {
					// this has to be here otherwise people cannot delist
					status="cancel_royalties_changed"
				} else if saleItem.hasAuctionStarted() && saleItem.hasAuctionEnded() {
					if saleItem.hasAuctionMetReservePrice() {
						panic("Cannot cancel finished auction, fulfill it instead")
					}
					status="cancel_reserved_not_met"
				}
			} else {
				status = "cancel_ghostlisting"
			}

			self.internalCancelAuction(saleItem: saleItem, status: status)

		}

		pub fun relist(_ id: UInt64) {
			let saleItem = self.borrow(id)
			let pointer= saleItem.pointer
			let vaultType= saleItem.vaultType
			let auctionStartPrice= saleItem.auctionStartPrice
			let auctionReservePrice= saleItem.auctionReservePrice
			let auctionDuration = saleItem.auctionDuration
			let auctionExtensionOnLateBid = saleItem.auctionExtensionOnLateBid
			let minimumBidIncrement = saleItem.auctionMinBidIncrement
			var auctionValidUntil= saleItem.auctionValidUntil
			let currentTime = Clock.time()
			if auctionValidUntil != nil && auctionValidUntil! <= currentTime {
				auctionValidUntil = nil
			}
			var auctionStartedAt = saleItem.auctionStartedAt
			if auctionStartedAt != nil && auctionStartedAt! <= currentTime {
				auctionStartedAt = nil
			}
			let saleItemExtraField= saleItem.saleItemExtraField

			self.cancel(id)
			self.listForAuction(pointer: pointer, vaultType: vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionStartTime: auctionStartedAt,  auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)

		}

		access(self) fun internalCancelAuction(saleItem: &SaleItem, status:String) {

			let status=status
			let ftType=saleItem.getFtType()
			let balance=saleItem.getBalance()
			let seller=saleItem.getSeller()
			let id=saleItem.getId()

			let tenant=self.getTenant()

			var nftInfo:FindMarket.NFTInfo?=nil
			if saleItem.checkPointer() {
				nftInfo=saleItem.toNFTInfo(false)
			}

			let buyer=saleItem.getBuyer()
			if buyer != nil {
				let buyerName=FIND.reverseLookup(buyer!)
				let profile = Profile.find(buyer!)
				emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(),startsAt: saleItem.auctionStartedAt, endsAt: saleItem.auctionEndsAt, previousBuyer: nil, previousBuyerName:nil)
			} else {
				emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: nil, buyerName: nil, buyerAvatar:nil,startsAt: saleItem.auctionStartedAt, endsAt: saleItem.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)
			}

			if saleItem.offerCallback != nil && saleItem.offerCallback!.check() {
				saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(id)
			}
			destroy <- self.items.remove(key: id)
		}


		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {

			if !self.items.containsKey(id) {
				panic("Invalid id=".concat(id.toString()))
			}
			if self.borrow(id).auctionStartPrice == nil {
				panic("Cannot fulfill sale that is not an auction=".concat(id.toString()))
			}

			let saleItem = self.borrow(id)

			if saleItem.hasAuctionStarted() {
				if !saleItem.hasAuctionEnded() {
					panic("Auction has not ended yet")
				}

				let tenant=self.getTenant()
				let nftType= saleItem.getItemType()
				let ftType= saleItem.getFtType()

				let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "fulfill auction"), seller: self.owner!.address, buyer: saleItem.offerCallback!.address)

				if !actionResult.allowed {
					panic(actionResult.message)
				}

				let cuts= tenant.getCuts(name: actionResult.name, listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: nftType, ftType: ftType)

				if !saleItem.hasAuctionMetReservePrice() {
					self.internalCancelAuction(saleItem: saleItem, status: "cancel_reserved_not_met")
					return
				}

				let nftInfo= saleItem.toNFTInfo(true)
				let royalty=saleItem.getRoyalty()

				let status="sold"
				let balance=saleItem.getBalance()
				let seller=self.owner!.address

				let buyer=saleItem.getBuyer()!

				let buyerName=FIND.reverseLookup(buyer)
				let sellerName = FIND.reverseLookup(seller)
				let profile = Profile.find(buyer)
				emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: sellerName, amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:ftType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), startsAt: saleItem.auctionStartedAt, endsAt: saleItem.auctionEndsAt, previousBuyer: nil, previousBuyerName:nil)

				let vault <- saleItem.acceptEscrowedBid()

				let resolved : {Address : String} = {}
				resolved[buyer] = buyerName ?? ""
				resolved[seller] = sellerName ?? ""
				resolved[FindMarketAuctionEscrow.account.address] =  "find"
				// Have to make sure the tenant always have the valid find name
				resolved[FindMarket.tenantNameAddress[tenant.name]!] =  tenant.name

				FindMarket.pay(tenant:tenant.name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) }, resolvedAddress: resolved)

				destroy <- self.items.remove(key: id)
				return
			}
			panic("This auction is not live")

		}

		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionStartTime: UFix64?, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {

			// ensure it is not a 0 dollar listing
			if auctionStartPrice <= 0.0 {
				panic("Auction start price should be greater than 0")
			}

			// ensure it is not a 0 dollar listing
			if auctionReservePrice < auctionStartPrice {
				panic("Auction reserve price should be greater than Auction start price")
			}

			let currentTime = Clock.time()
			// ensure validUntil is valid
			if auctionValidUntil != nil && auctionValidUntil! < currentTime {
				panic("Valid until is before current time")
			}

			// if we do this, the auctionStartTime variable from arg is gone
			var auctionStartTime = auctionStartTime
			// ensure startTime is valid, if auctionStartTime is < currentTime, make it currentTIme (might not be easy to pass in exact time)
			if auctionStartTime != nil && auctionStartTime! < currentTime {
				auctionStartTime = currentTime
			}

			// check soul bound
			if pointer.checkSoulBound() {
				panic("This item is soul bounded and cannot be traded")
			}

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice, auctionDuration: auctionDuration, extentionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement:minimumBidIncrement, auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)

			// if startTime is set, start the auction at the specified time with intended auction duration
			if auctionStartTime != nil {
				saleItem.setAuctionStarted(auctionStartTime!)
				let endTime = auctionStartTime! + auctionDuration
				saleItem.setAuctionEnds(endTime)
			}

			let tenant=self.getTenant()

			// Check if it is onefootball. If so, listing has to be at least $0.65 (DUC)
			if tenant.name == "onefootball" {
				// ensure it is not a 0 dollar listing
				if auctionStartPrice <= 0.65 {
					panic("Auction start price should be greater than 0.65")
				}
			}

			let nftType= saleItem.getItemType()
			let ftType= saleItem.getFtType()

			let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "list item for auction"), seller: self.owner!.address, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
			}
			let id=pointer.getUUID()

			if self.items[id] != nil {
				panic("Auction listing for this item is already created.")
			}

			self.items[id] <-! saleItem
			let saleItemRef = self.borrow(id)

			var status = "active_listed"
			let balance=auctionStartPrice
			let seller=self.owner!.address
			if auctionStartTime != nil {
				if auctionStartTime == currentTime {
					status = "active_ongoing"
				} else {
					status = "inactive_listed"
				}
			}

			let nftInfo=saleItemRef.toNFTInfo(true)

			emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItemRef.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItemRef.auctionReservePrice,  status: status, vaultType:ftType.identifier, nft: nftInfo,  buyer: nil, buyerName: nil, buyerAvatar:nil, startsAt: saleItemRef.auctionStartedAt, endsAt: saleItemRef.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)

		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun getRoyaltyChangedIds(): [UInt64] {
			let ids : [UInt64] = []
			for id in self.getIds() {
				let item = self.borrow(id)
				if !item.validateRoyalties() {
					ids.append(id)
				}
			}
			return ids
		}

		pub fun containsId(_ id: UInt64): Bool {
			return self.items.containsKey(id)
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			if !self.items.containsKey(id)  {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem?)!
		}

		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			if !self.items.containsKey(id)  {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.items[id] as &SaleItem{FindMarket.SaleItem}?)!
		}

		destroy() {
			destroy self.items
		}
	}

	pub resource Bid : FindMarket.Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) let vault: @FungibleToken.Vault
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64
		access(contract) let bidExtraField: {String : AnyStruct}

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}> , bidExtraField: {String : AnyStruct}) {
			self.vaultType= vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
			self.bidExtraField=bidExtraField
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		pub fun getBalance() : UFix64 {
			return self.vault.balance
		}

		pub fun getSellerAddress() : Address {
			return self.from.address
		}

		pub fun getBidExtraField() : {String : AnyStruct} {
			return self.bidExtraField
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ id: UInt64) : UFix64
		pub fun containsId(_ id: UInt64): Bool
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT, path:PublicPath) : @FungibleToken.Vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			if !self.tenantCapability.check()  {
				panic("Tenant client is not linked anymore")
			}
			return self.tenantCapability.borrow()!
		}

		//called from lease when auction is ended
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT, path:PublicPath) : @FungibleToken.Vault {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			let nftCap = bid.nftCap
			if !nftCap.check() {
				 let cpCap =getAccount(nftCap.address).getCapability<&{NonFungibleToken.CollectionPublic}>(path)
				 if !cpCap.check() {
					panic("Bidder unlinked the nft receiver capability. bidder address : ".concat(bid.nftCap.address.toString()))
				} else {
					bid.nftCap.borrow()!.deposit(token: <- nft)
				}
			} else {
				bid.nftCap.borrow()!.deposit(token: <- nft)
			}
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun containsId(_ id: UInt64) : Bool {
			return self.bids.containsKey(id)
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}

		pub fun bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, bidExtraField: {String : AnyStruct}) {

			if self.owner!.address == item.owner() {
				panic("You cannot bid on your own resource")
			}

			let uuid=item.getUUID()

			if self.bids[uuid] != nil {
				panic("You already have an bid for this item, use increaseBid on that bid")
			}

			let tenant=self.getTenant()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
			let vaultType=vault.getType()

			let bid <- create Bid(from: from, itemUUID:uuid, vault: <- vault, nftCap: nftCap, bidExtraField: bidExtraField)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))

			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType)
			destroy oldToken
		}

		pub fun fulfillAuction(_ id:UInt64) {

			if self.bids[id] == nil {
				panic("You need to have a bid here already")
			}
			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!
			saleItem.fulfillAuction(id)
		}

		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			if self.bids[id] == nil {
				panic("You need to have a bid here already")
			}
			let bid =self.borrowBid(id)

			let oldBalance=bid.vault.balance

			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)
			if !bid.from.check() {
				panic("Seller unlinked SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
			}
			bid.from.borrow()!.registerIncreasedBid(id, oldBalance:oldBalance)
		}

		//called from saleItem when things are cancelled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			if !self.receiver.check() {
				panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(self.receiver.address.toString()))
			}
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			if !self.bids.containsKey(id)  {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid?)!
		}

		pub fun borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
			if !self.bids.containsKey(id)  {
				panic("This id does not exist.".concat(id.toString()))
			}
			return (&self.bids[id] as &Bid{FindMarket.Bid}?)!
		}

		pub fun getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		if FindMarket.getTenantCapability(marketplace) == nil {
			panic("Invalid tenant")
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		if FindMarket.getTenantCapability(marketplace) == nil {
			panic("Invalid tenant")
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
		}
		return nil
	}

	init() {
		FindMarket.addSaleItemType(Type<@SaleItem>())
		FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
		FindMarket.addMarketBidType(Type<@Bid>())
		FindMarket.addMarketBidCollectionType(Type<@MarketBidCollection>())
	}
}
