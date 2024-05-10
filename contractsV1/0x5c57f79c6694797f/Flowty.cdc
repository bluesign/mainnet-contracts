import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LostAndFound from "../0x473d6a2c37eab5be/LostAndFound.cdc"

import FlowtyUtils from "../0x3cdbb3d569211ff3/FlowtyUtils.cdc"

import FlowtyListingCallback from "../0x3cdbb3d569211ff3/FlowtyListingCallback.cdc"

import DNAHandler from "../0x3cdbb3d569211ff3/DNAHandler.cdc"

// Flowty
//
// A smart contract responsible for the main lending flows. 
// It is facilitating the lending deal, allowing borrowers and lenders 
// to be sure that the deal would be executed on their agreed terms.
// 
// Each account that wants to list a loan installs a Storefront,
// and lists individual loan within that Storefront as Listings.
// There is one Storefront per account, it handles loans of all NFT types
// for that account.
//
// Each Listing can have one or more "cut"s of the requested loan amount that
// goes to one or more addresses. Cuts are used to pay listing fees
// or other considerations.
// Each NFT may be listed in one or more Listings, the validity of each
// Listing can easily be checked.
// 
// Lenders can watch for Listing events and check the NFT type and
// ID to see if they wish to fund the listed loan.
//
access(all)
contract Flowty{ 
	// FlowtyInitialized
	// This contract has been deployed.
	// Event consumers can now expect events from this contract.
	//
	access(all)
	event FlowtyInitialized()
	
	// FlowtyStorefrontInitialized
	// A FlowtyStorefront resource has been created.
	// Event consumers can now expect events from this FlowtyStorefront.
	// Note that we do not specify an address: we cannot and should not.
	// Created resources do not have an owner address, and may be moved
	// after creation in ways we cannot check.
	// ListingAvailable events can be used to determine the address
	// of the owner of the FlowtyStorefront (...its location) at the time of
	// the listing but only at that precise moment in that precise transaction.
	// If the seller moves the FlowtyStorefront while the listing is valid, 
	// that is on them.
	//
	access(all)
	event FlowtyStorefrontInitialized(flowtyStorefrontResourceID: UInt64)
	
	// FlowtyMarketplaceInitialized
	// A FlowtyMarketplace resource has been created.
	// Event consumers can now expect events from this FlowtyStorefront.
	// Note that we do not specify an address: we cannot and should not.
	// Created resources do not have an owner address, and may be moved
	// after creation in ways we cannot check.
	// ListingAvailable events can be used to determine the address
	// of the owner of the FlowtyStorefront (...its location) at the time of
	// the listing but only at that precise moment in that precise transaction.
	// If the seller moves the FlowtyStorefront while the listing is valid, 
	// that is on them.
	//
	access(all)
	event FlowtyMarketplaceInitialized(flowtyMarketplaceResourceID: UInt64)
	
	// FlowtyStorefrontDestroyed
	// A FlowtyStorefront has been destroyed.
	// Event consumers can now stop processing events from this FlowtyStorefront.
	// Note that we do not specify an address.
	//
	access(all)
	event FlowtyStorefrontDestroyed(flowtyStorefrontResourceID: UInt64)
	
	// FlowtyMarketplaceDestroyed
	// A FlowtyMarketplace has been destroyed.
	// Event consumers can now stop processing events from this FlowtyMarketplace.
	// Note that we do not specify an address.
	//
	access(all)
	event FlowtyMarketplaceDestroyed(flowtyStorefrontResourceID: UInt64)
	
	// ListingAvailable
	// A listing has been created and added to a FlowtyStorefront resource.
	// The Address values here are valid when the event is emitted, but
	// the state of the accounts they refer to may be changed outside of the
	// FlowtyMarketplace workflow, so be careful to check when using them.
	//
	access(all)
	event ListingAvailable(
		flowtyStorefrontAddress: Address,
		flowtyStorefrontID: UInt64,
		listingResourceID: UInt64,
		nftType: String,
		nftID: UInt64,
		amount: UFix64,
		interestRate: UFix64,
		term: UFix64,
		enabledAutoRepayment: Bool,
		royaltyRate: UFix64,
		expiresAfter: UFix64,
		paymentTokenType: String,
		repaymentAddress: Address?
	)
	
	// ListingCompleted
	// The listing has been resolved. It has either been funded, or removed and destroyed.
	//
	access(all)
	event ListingCompleted(
		listingResourceID: UInt64,
		flowtyStorefrontID: UInt64,
		funded: Bool,
		nftID: UInt64,
		nftType: String,
		flowtyStorefrontAddress: Address
	)
	
	// FundingAvailable
	// A funding has been created and added to a FlowtyStorefront resource.
	// The Address values here are valid when the event is emitted, but
	// the state of the accounts they refer to may be changed outside of the
	// FlowtyMarketplace workflow, so be careful to check when using them.
	//
	access(all)
	event FundingAvailable(
		fundingResourceID: UInt64,
		listingResourceID: UInt64,
		borrower: Address,
		lender: Address,
		nftID: UInt64,
		nftType: String,
		repaymentAmount: UFix64,
		enabledAutoRepayment: Bool,
		repaymentAddress: Address?
	)
	
	// FundingRepaid
	// A funding has been repaid.
	//
	access(all)
	event FundingRepaid(
		fundingResourceID: UInt64,
		listingResourceID: UInt64,
		borrower: Address,
		lender: Address,
		nftID: UInt64,
		nftType: String,
		repaymentAmount: UFix64,
		repaymentAddress: Address?
	)
	
	// FundingSettled
	// A funding has been settled.
	//
	access(all)
	event FundingSettled(
		fundingResourceID: UInt64,
		listingResourceID: UInt64,
		borrower: Address,
		lender: Address,
		nftID: UInt64,
		nftType: String,
		repaymentAmount: UFix64,
		repaymentAddress: Address?
	)
	
	access(all)
	event CollectionSupportChanged(collectionIdentifier: String, state: Bool)
	
	access(all)
	event RoyaltyAdded(collectionIdentifier: String, rate: UFix64)
	
	access(all)
	event RoyaltyEscrow(
		fundingResourceID: UInt64,
		listingResourceID: UInt64,
		lender: Address,
		amount: UFix64
	)
	
	// FlowtyStorefrontStoragePath
	// The location in storage that a FlowtyStorefront resource should be located.
	access(all)
	let FlowtyStorefrontStoragePath: StoragePath
	
	// FlowtyMarketplaceStoragePath
	// The location in storage that a FlowtyMarketplace resource should be located.
	access(all)
	let FlowtyMarketplaceStoragePath: StoragePath
	
	// FlowtyStorefrontPublicPath
	// The public location for a FlowtyStorefront link.
	access(all)
	let FlowtyStorefrontPublicPath: PublicPath
	
	// FlowtyMarketplacePublicPath
	// The public location for a FlowtyMarketplace link.
	access(all)
	let FlowtyMarketplacePublicPath: PublicPath
	
	// FlowtyAdminStoragePath
	// The location in storage that an FlowtyAdmin resource should be located.
	access(all)
	let FlowtyAdminStoragePath: StoragePath
	
	// FusdVaultStoragePath
	// The location in storage that an FUSD Vault resource should be located.
	access(all)
	let FusdVaultStoragePath: StoragePath
	
	// FusdReceiverPublicPath
	// The public location for a FUSD Receiver link.
	access(all)
	let FusdReceiverPublicPath: PublicPath
	
	// FusdBalancePublicPath
	// The public location for a FUSD Balance link.
	access(all)
	let FusdBalancePublicPath: PublicPath
	
	// ListingFee
	// The fixed fee in FUSD for a listing.
	access(all)
	var ListingFee: UFix64
	
	// FundingFee
	// The percentage fee on funding, a number between 0 and 1.
	access(all)
	var FundingFee: UFix64
	
	// SuspendedFundingPeriod
	// The suspended funding period in seconds(started on listing). 
	// So that the borrower has some time to delist it.
	access(all)
	var SuspendedFundingPeriod: UFix64
	
	// A dictionary for the Collection to royalty configuration.
	access(account)
	var Royalties:{ String: Royalty}
	
	access(account)
	var TokenPaths:{ String: PublicPath}
	
	// The collections which are allowed to be used as collateral
	access(account)
	var SupportedCollections:{ String: Bool}
	
	// PaymentCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a tx is executed.
	//
	access(all)
	struct PaymentCut{ 
		// The receiver for the payment.
		// Note that we do not store an address to find the Vault that this represents,
		// as the link or resource that we fetch in this way may be manipulated,
		// so to find the address that a cut goes to you must get this struct and then
		// call receiver.borrow().owner.address on it.
		// This can be done efficiently in a script.
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// The amount of the payment FungibleToken that will be paid to the receiver.
		access(all)
		let amount: UFix64
		
		// initializer
		//
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	access(all)
	struct Royalty{ 
		// The percentage points that should go to the collection owner
		// In the event of a loan default
		access(all)
		let Rate: UFix64
		
		access(all)
		let Address: Address
		
		init(rate: UFix64, address: Address){ 
			self.Rate = rate
			self.Address = address
		}
	}
	
	// ListingDetails
	// A struct containing a Listing's data.
	//
	access(all)
	struct ListingDetails{ 
		// The FlowtyStorefront that the Listing is stored in.
		// Note that this resource cannot be moved to a different FlowtyStorefront
		access(all)
		var flowtyStorefrontID: UInt64
		
		// Whether this listing has been funded or not.
		access(all)
		var funded: Bool
		
		// The Type of the NonFungibleToken.NFT that is being listed.
		access(all)
		let nftType: Type
		
		// The ID of the NFT within that type.
		access(all)
		let nftID: UInt64
		
		// The amount of the requested loan.
		access(all)
		let amount: UFix64
		
		// The interest rate in %, a number between 0 and 1.
		access(all)
		let interestRate: UFix64
		
		//The term in seconds for this listing.
		access(all)
		var term: UFix64
		
		// The Type of the FungibleToken that fundings must be made in.
		access(all)
		let paymentVaultType: Type
		
		// This specifies the division of payment between recipients.
		access(self)
		let paymentCuts: [PaymentCut]
		
		//The time the funding start at
		access(all)
		var listedTime: UFix64
		
		// The royalty rate needed as a deposit for this loan to be funded
		access(all)
		var royaltyRate: UFix64
		
		// The number of seconds this listing is valid for
		access(all)
		var expiresAfter: UFix64
		
		// getPaymentCuts
		// Returns payment cuts
		access(all)
		fun getPaymentCuts(): [PaymentCut]{ 
			return self.paymentCuts
		}
		
		access(all)
		view fun getTotalPayment(): UFix64{ 
			return self.amount * (1.0 + self.interestRate * Flowty.FundingFee + self.royaltyRate)
		}
		
		// setToFunded
		// Irreversibly set this listing as funded.
		//
		access(contract)
		fun setToFunded(){ 
			self.funded = true
		}
		
		// initializer
		//
		init(
			nftType: Type,
			nftID: UInt64,
			amount: UFix64,
			interestRate: UFix64,
			term: UFix64,
			paymentVaultType: Type,
			paymentCuts: [
				PaymentCut
			],
			flowtyStorefrontID: UInt64,
			expiresAfter: UFix64,
			royaltyRate: UFix64
		){ 
			self.flowtyStorefrontID = flowtyStorefrontID
			self.funded = false
			self.nftType = nftType
			self.nftID = nftID
			self.amount = amount
			self.interestRate = interestRate
			self.term = term
			self.paymentVaultType = paymentVaultType
			self.listedTime = getCurrentBlock().timestamp
			self.expiresAfter = expiresAfter
			self.royaltyRate = royaltyRate
			assert(
				paymentCuts.length > 0,
				message: "Listing must have at least one payment cut recipient"
			)
			self.paymentCuts = paymentCuts
			
			// Calculate the total price from the cuts
			var cutsAmount = 0.0
			// Perform initial check on capabilities, and calculate payment price from cut amounts.
			for cut in self.paymentCuts{ 
				// make sure we can borrow the receiver
				cut.receiver.borrow()!
				// Add the cut amount to the total price
				cutsAmount = cutsAmount + cut.amount
			}
			assert(cutsAmount > 0.0, message: "Listing must have non-zero requested amount")
		}
	}
	
	// ListingPublic
	// An interface providing a useful public interface to a Listing.
	//
	access(all)
	resource interface ListingPublic{ 
		// borrowNFT
		// This will assert in the same way as the NFT standard borrowNFT()
		// if the NFT is absent, for example if it has been sold via another listing.
		//
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}
		
		// fund
		// Fund the listing.
		// This pays the beneficiaries and returns the token to the buyer.
		//
		access(all)
		fun fund(
			payment: @{FungibleToken.Vault},
			lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
			lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>
		)
		
		// getDetails
		//
		access(all)
		fun getDetails(): ListingDetails
		
		// suspensionTimeRemaining
		// 
		access(all)
		view fun suspensionTimeRemaining(): Fix64
		
		// remainingTimeToFund
		//
		access(all)
		view fun remainingTimeToFund(): Fix64
		
		// isFundingEnabled
		//
		access(all)
		view fun isFundingEnabled(): Bool
	}
	
	// Listing
	// A resource that allows an NFT to be fund for an amount of a given FungibleToken,
	// and for the proceeds of that payment to be split between several recipients.
	// 
	access(all)
	resource Listing: ListingPublic, FlowtyListingCallback.Listing{ 
		// The simple (non-Capability, non-complex) details of the listing
		access(self)
		let details: ListingDetails
		
		// A capability allowing this resource to withdraw the NFT with the given ID from its collection.
		// This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
		// such a capability to a resource and always check its code to make sure it will use it in the
		// way that it claims.
		access(contract)
		let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// A capability allowing this resource to access the owner's NFT public collection 
		access(contract)
		let nftPublicCollectionCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		// A capability allowing this resource to withdraw `FungibleToken`s from borrower account.
		// This capability allows loan repayment if there is system downtime, which will prevent NFT losing.
		// NOTE: This variable cannot be renamed but it can allow any FungibleToken.
		access(contract)
		let fusdProviderCapability: Capability<&{FungibleToken.Provider}>?
		
		// borrowNFT
		// This will assert in the same way as the NFT standard borrowNFT()
		// if the NFT is absent, for example if it has been sold via another listing.
		//
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}{ 
			let ref = (self.nftProviderCapability.borrow()!).borrowNFT(self.getDetails().nftID)
			assert(ref.getType() == self.getDetails().nftType, message: "token has wrong type")
			assert(ref.id == self.getDetails().nftID, message: "token has wrong ID")
			return ref!
		}
		
		// getDetails
		// Get the details of the current state of the Listing as a struct.
		// This avoids having more public variables and getter methods for them, and plays
		// nicely with scripts (which cannot return resources).
		//
		access(all)
		fun getDetails(): ListingDetails{ 
			return self.details
		}
		
		// fund
		// Fund the listing.
		// This pays the beneficiaries and move the NFT to the funding resource stored in the marketplace account.
		//
		access(all)
		fun fund(payment: @{FungibleToken.Vault}, lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>, lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			pre{ 
				self.isFundingEnabled():
					"Funding is not enabled or this listing has expired"
				self.details.funded == false:
					"listing has already been funded"
				payment.isInstance(self.details.paymentVaultType):
					"payment vault is not requested fungible token"
				payment.balance == self.details.getTotalPayment():
					"payment vault does not contain requested amount"
				self.nftProviderCapability.check():
					"nftProviderCapability failed check"
			}
			
			// Make sure the listing cannot be funded again.
			self.details.setToFunded()
			
			// Fetch the token to return to the purchaser.
			let nft <- (self.nftProviderCapability.borrow()!).withdraw(withdrawID: self.details.nftID)
			let ref = &nft as &{NonFungibleToken.NFT}
			assert(FlowtyUtils.isSupported(ref), message: "nft type is not supported")
			
			// Neither receivers nor providers are trustworthy, they must implement the correct
			// interface but beyond complying with its pre/post conditions they are not gauranteed
			// to implement the functionality behind the interface in any given way.
			// Therefore we cannot trust the Collection resource behind the interface,
			// and we must check the NFT resource it gives us to make sure that it is the correct one.
			assert(nft.isInstance(self.details.nftType), message: "withdrawn NFT is not of specified type")
			assert(nft.id == self.details.nftID, message: "withdrawn NFT does not have specified ID")
			
			// Rather than aborting the transaction if any receiver is absent when we try to pay it,
			// we send the cut to the first valid receiver.
			// The first receiver should therefore either be the borrower, or an agreed recipient for
			// any unpaid cuts.
			var residualReceiver: &{FungibleToken.Receiver}? = nil
			
			// Pay each beneficiary their amount of the payment.
			for cut in self.details.getPaymentCuts(){ 
				if cut.receiver.check(){ 
					let receiver = cut.receiver.borrow()!
					let paymentCut <- payment.withdraw(amount: cut.amount)
					receiver.deposit(from: <-paymentCut)
					if residualReceiver == nil{ 
						residualReceiver = receiver
					}
				}
			}
			
			// Funding fee
			let fundingFeeAmount = self.details.amount * self.details.interestRate * Flowty.FundingFee
			let fundingFee <- payment.withdraw(amount: fundingFeeAmount)
			let feeTokenPath = Flowty.TokenPaths[self.details.paymentVaultType.identifier]!
			let flowtyFeeReceiver = Flowty.account.capabilities.get<&{FungibleToken.Receiver}>(feeTokenPath).borrow()!
			flowtyFeeReceiver.deposit(from: <-fundingFee)
			
			// Royalty
			// Deposit royalty amount 
			let royalty = self.details.royaltyRate
			var royaltyVault: @{FungibleToken.Vault}? <- nil
			if self.details.royaltyRate > 0.0{ 
				let tmp <- royaltyVault <- payment.withdraw(amount: self.details.amount * royalty)
				destroy tmp
			}
			assert(residualReceiver != nil, message: "No valid payment receivers")
			(			 
			 // At this point, if all recievers were active and availabile, then the payment Vault will have
			 // zero tokens left, and this will functionally be a no-op that consumes the empty vault
			 residualReceiver!).deposit(from: <-payment)
			let listingResourceID = self.uuid
			
			// If the listing is funded, we regard it as completed here.
			// Otherwise we regard it as completed in the destructor.
			emit ListingCompleted(listingResourceID: listingResourceID, flowtyStorefrontID: self.details.flowtyStorefrontID, funded: self.details.funded, nftID: self.details.nftID, nftType: self.details.nftType.identifier, flowtyStorefrontAddress: self.nftPublicCollectionCapability.address)
			let repaymentAmount = self.details.amount + self.details.amount * self.details.interestRate
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Filled, listing: &self as &{FlowtyListingCallback.Listing}, nft: ref)
			}
			let marketplace = Flowty.borrowMarketplace()
			marketplace.createFunding(flowtyStorefrontID: self.details.flowtyStorefrontID, listingResourceID: listingResourceID, ownerNFTCollection: self.nftPublicCollectionCapability, lenderNFTCollection: lenderNFTCollection, NFT: <-nft, paymentVaultType: self.details.paymentVaultType, lenderFungibleTokenReceiver: lenderFungibleTokenReceiver, repaymentAmount: repaymentAmount, term: self.details.term, fusdProviderCapability: self.fusdProviderCapability, royaltyVault: <-royaltyVault, listingDetails: self.getDetails())
		}
		
		// suspensionTimeRemaining
		// The remaining time. This can be negative if is expired
		access(all)
		view fun suspensionTimeRemaining(): Fix64{ 
			let listedTime = self.details.listedTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(listedTime + Flowty.SuspendedFundingPeriod) - Fix64(currentTime)
			return remaining
		}
		
		// remainingTimeToFund
		// The time in seconds left until this listing is no longer valid
		access(all)
		view fun remainingTimeToFund(): Fix64{ 
			let listedTime = self.details.listedTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(listedTime + self.details.expiresAfter) - Fix64(currentTime)
			return remaining
		}
		
		// isFundingEnabled
		access(all)
		view fun isFundingEnabled(): Bool{ 
			let timeRemaining = self.suspensionTimeRemaining()
			let listingTimeRemaining = self.remainingTimeToFund()
			return timeRemaining < Fix64(0.0) && listingTimeRemaining > Fix64(0.0)
		}
		
		// initializer
		//
		init(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftPublicCollectionCapability: Capability<&{NonFungibleToken.CollectionPublic}>, fusdProviderCapability: Capability<&{FungibleToken.Provider}>?, nftType: Type, nftID: UInt64, amount: UFix64, interestRate: UFix64, term: UFix64, paymentVaultType: Type, paymentCuts: [PaymentCut], flowtyStorefrontID: UInt64, expiresAfter: UFix64, royaltyRate: UFix64){ 
			// Store the sale information
			self.details = ListingDetails(nftType: nftType, nftID: nftID, amount: amount, interestRate: interestRate, term: term, paymentVaultType: paymentVaultType, paymentCuts: paymentCuts, flowtyStorefrontID: flowtyStorefrontID, expiresAfter: expiresAfter, royaltyRate: royaltyRate)
			
			// Store the NFT provider
			self.nftProviderCapability = nftProviderCapability
			self.fusdProviderCapability = fusdProviderCapability
			self.nftPublicCollectionCapability = nftPublicCollectionCapability
			
			// Check that the provider contains the NFT.
			// We will check it again when the token is funded.
			// We cannot move this into a function because initializers cannot call member functions.
			let provider = self.nftProviderCapability.borrow()!
			
			// This will precondition assert if the token is not available.
			let nft = provider.borrowNFT(self.details.nftID)
			assert(nft.isInstance(self.details.nftType), message: "token is not of specified type")
			assert(nft.id == self.details.nftID, message: "token does not have specified ID")
		}
	
	// destructor
	//
	}
	
	// FundingDetails
	// A struct containing a Fundings's data.
	//
	access(all)
	struct FundingDetails{ 
		// The FlowtyStorefront that the Funding is stored in.
		// Note that this resource cannot be moved to a different FlowtyStorefront
		access(all)
		var flowtyStorefrontID: UInt64
		
		access(all)
		var listingResourceID: UInt64
		
		// Whether this funding has been repaid or not.
		access(all)
		var repaid: Bool
		
		// Whether this funding has been settled or not.
		access(all)
		var settled: Bool
		
		// The Type of the FungibleToken that fundings must be repaid.
		access(all)
		let paymentVaultType: Type
		
		// The amount that must be repaid in the specified FungibleToken.
		access(all)
		let repaymentAmount: UFix64
		
		// the time the funding start at
		access(all)
		var startTime: UFix64
		
		// The length in seconds for this funding
		access(all)
		var term: UFix64
		
		// setToRepaid
		// Irreversibly set this funding as repaid.
		//
		access(contract)
		fun setToRepaid(){ 
			self.repaid = true
		}
		
		// setToSettled
		// Irreversibly set this funding as settled.
		//
		access(contract)
		fun setToSettled(){ 
			self.settled = true
		}
		
		// initializer
		//
		init(
			flowtyStorefrontID: UInt64,
			listingResourceID: UInt64,
			paymentVaultType: Type,
			repaymentAmount: UFix64,
			term: UFix64
		){ 
			self.flowtyStorefrontID = flowtyStorefrontID
			self.listingResourceID = listingResourceID
			self.paymentVaultType = paymentVaultType
			self.repaid = false
			self.settled = false
			self.repaymentAmount = repaymentAmount
			self.term = term
			self.startTime = getCurrentBlock().timestamp
		}
	}
	
	// FundingPublic
	// An interface providing a useful public interface to a Funding.
	//
	access(all)
	resource interface FundingPublic{ 
		
		// repay
		//
		access(all)
		fun repay(payment: @{FungibleToken.Vault})
		
		// getDetails
		//
		access(all)
		fun getDetails(): FundingDetails
		
		// get the listing details for this loan
		//
		access(all)
		fun getListingDetails(): Flowty.ListingDetails
		
		// timeRemaining
		// 
		access(all)
		view fun timeRemaining(): Fix64
		
		// isFundingExpired
		//
		access(all)
		view fun isFundingExpired(): Bool
		
		// get the amount stored in a vault for royalty payouts
		//
		access(all)
		fun getRoyaltyAmount(): UFix64?
		
		access(all)
		fun settleFunding()
	}
	
	// Funding
	// 
	access(all)
	resource Funding: FundingPublic, FlowtyListingCallback.Listing{ 
		// The simple (non-Capability, non-complex) details of the listing
		access(self)
		let details: FundingDetails
		
		access(self)
		let listingDetails: ListingDetails
		
		// A capability allowing this resource to access the owner's NFT public collection 
		access(contract)
		let ownerNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>
		
		// A capability allowing this resource to access the lender's NFT public collection 
		access(contract)
		let lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>
		
		// The receiver for the repayment.
		access(contract)
		let lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>
		
		// NFT escrow
		access(contract)
		var NFT: @{NonFungibleToken.NFT}?
		
		// FUSD Allowance
		access(contract)
		let fusdProviderCapability: Capability<&{FungibleToken.Provider}>?
		
		// royalty payment vault to be deposited to the specified desination on repayment or default
		access(contract)
		var royaltyVault: @{FungibleToken.Vault}?
		
		// getDetails
		// Get the details of the current state of the Listing as a struct.
		// This avoids having more public variables and getter methods for them, and plays
		// nicely with scripts (which cannot return resources).
		//
		access(all)
		fun getDetails(): FundingDetails{ 
			return self.details
		}
		
		access(all)
		fun getListingDetails(): ListingDetails{ 
			return self.listingDetails
		}
		
		access(all)
		fun getRoyaltyAmount(): UFix64?{ 
			return self.royaltyVault?.balance
		}
		
		access(contract)
		fun borrowNFT(): &{NonFungibleToken.NFT}?{ 
			return &self.NFT as &{NonFungibleToken.NFT}?
		}
		
		// repay
		// Repay the funding.
		// This pays the lender and returns the NFT to the owner.
		//
		access(all)
		fun repay(payment: @{FungibleToken.Vault}){ 
			pre{ 
				!self.isFundingExpired():
					"the loan has expired"
				self.details.repaid == false:
					"funding has already been repaid"
				payment.isInstance(self.details.paymentVaultType):
					"payment vault is not requested fungible token"
				payment.balance == self.details.repaymentAmount:
					"payment vault does not contain requested price"
			}
			self.details.setToRepaid()
			let royaltyAmount = self.royaltyVault != nil ? self.royaltyVault?.balance! : 0.0
			let tmp <- self.NFT <- nil
			let nft <- tmp!
			let nftID: UInt64 = nft.id
			let nftType = nft.getType()
			let depositor = Flowty.account.storage.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
			let royaltyVault <- self.royaltyVault <- nil
			if royaltyVault != nil{ 
				let vault <-! royaltyVault!
				vault.deposit(from: <-payment.withdraw(amount: self.details.repaymentAmount))
				destroy payment
				assert(vault.balance == self.details.repaymentAmount + royaltyAmount, message: "insufficient balance to send to lender")
				FlowtyUtils.trySendFungibleTokenVault(vault: <-vault, receiver: self.lenderFungibleTokenReceiver, depositor: depositor)
			} else{ 
				FlowtyUtils.trySendFungibleTokenVault(vault: <-payment, receiver: self.lenderFungibleTokenReceiver, depositor: depositor)
				destroy royaltyVault
			}
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Completed, listing: &self as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.ownerNFTCollection, depositor: depositor)
			let borrower = self.ownerNFTCollection.address
			let lender = self.lenderFungibleTokenReceiver.address
			emit FundingRepaid(fundingResourceID: self.uuid, listingResourceID: self.details.listingResourceID, borrower: borrower, lender: lender, nftID: nftID, nftType: nftType.identifier, repaymentAmount: self.details.repaymentAmount, repaymentAddress: self.fusdProviderCapability?.address)
		}
		
		// repay
		// Repay the funding with borrower permit.
		// This pays the lender and returns the NFT to the owner using FUSD allowance from borrower account.
		//
		access(all)
		fun repayWithPermit(){ 
			pre{ 
				self.details.repaid == false:
					"funding has already been repaid"
				self.details.settled == false:
					"funding has already been settled"
				(self.fusdProviderCapability!).check():
					"listing is created without FUSD allowance"
			}
			self.details.setToRepaid()
			let royaltyAmount = self.royaltyVault != nil ? self.royaltyVault?.balance! : 0.0
			let tmp <- self.NFT <- nil
			let nft <- tmp!
			let nftID = nft.id
			let nftType = nft.getType()
			let borrowerVault = (self.fusdProviderCapability!).borrow()!
			let payment <- borrowerVault.withdraw(amount: self.details.repaymentAmount)
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Completed, listing: &self as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			let depositor = Flowty.account.storage.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
			FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.ownerNFTCollection, depositor: depositor)
			let royaltyVault <- self.royaltyVault <- nil
			let vault <-! royaltyVault!
			vault.deposit(from: <-payment.withdraw(amount: self.details.repaymentAmount))
			destroy payment
			assert(vault.balance == self.details.repaymentAmount + royaltyAmount, message: "insufficient balance to send to lender")
			FlowtyUtils.trySendFungibleTokenVault(vault: <-vault, receiver: self.lenderFungibleTokenReceiver, depositor: depositor)
			let borrower = self.ownerNFTCollection.address
			let lender = self.lenderFungibleTokenReceiver.address
			emit FundingRepaid(fundingResourceID: self.uuid, listingResourceID: self.details.listingResourceID, borrower: borrower, lender: lender, nftID: nftID, nftType: nftType.identifier, repaymentAmount: self.details.repaymentAmount, repaymentAddress: self.fusdProviderCapability?.address)
		}
		
		// settleFunding
		// Settle the different statuses responsible for the repayment and claiming processes.
		// NFT is moved to the lender, because the borrower hasn't repaid the loan.
		//
		access(all)
		fun settleFunding(){ 
			pre{ 
				self.isFundingExpired():
					"the loan hasn't expired"
				self.details.repaid == false:
					"funding has already been repaid"
				self.details.settled == false:
					"funding has already been settled"
			}
			let lender = self.lenderNFTCollection.address
			let borrower = self.ownerNFTCollection.address
			let repayer = self.fusdProviderCapability?.address ?? nil
			let borrowerTokenBalance = repayer != nil ? FlowtyUtils.getTokenBalance(address: repayer!, vaultType: self.details.paymentVaultType) : 0.0
			let ref = &self.NFT as &{NonFungibleToken.NFT}?
			let royalties = (ref!).resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?
			let tmp <- self.NFT <- nil
			let nft <- tmp!
			let nftID = nft.id
			let nftType = nft.getType()
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Completed, listing: &self as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			let depositor = Flowty.account.storage.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
			if borrowerTokenBalance >= self.details.repaymentAmount && self.fusdProviderCapability?.check() == true{ 
				// borrower has funds to repay loan
				// repay lender
				// return NFT to owner
				self.details.setToRepaid()
				let borrowerVault = (self.fusdProviderCapability!).borrow()!
				let payment <- borrowerVault.withdraw(amount: self.details.repaymentAmount)
				FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.ownerNFTCollection, depositor: depositor)
				let repaymentVault <- payment
				let royaltyVault <- self.royaltyVault <- nil
				if royaltyVault != nil{ 
					repaymentVault.deposit(from: <-royaltyVault!)
				} else{ 
					destroy royaltyVault
				}
				FlowtyUtils.trySendFungibleTokenVault(vault: <-repaymentVault, receiver: self.lenderFungibleTokenReceiver, depositor: depositor)
				emit FundingRepaid(fundingResourceID: self.uuid, listingResourceID: self.details.listingResourceID, borrower: borrower, lender: lender, nftID: nftID, nftType: nftType.identifier, repaymentAmount: self.details.repaymentAmount, repaymentAddress: self.fusdProviderCapability?.address)
				return
			}
			
			// loan defaults; move NFT to lender as payment
			self.details.setToSettled()
			assert(nft != nil, message: "NFT is already moved")
			FlowtyUtils.trySendNFT(nft: <-nft, receiver: self.lenderNFTCollection, depositor: depositor)
			emit FundingSettled(fundingResourceID: self.uuid, listingResourceID: self.details.listingResourceID, borrower: borrower, lender: lender, nftID: nftID, nftType: nftType.identifier, repaymentAmount: self.details.repaymentAmount, repaymentAddress: self.fusdProviderCapability?.address)
			let royaltyVault <- self.royaltyVault <- nil
			if royaltyVault == nil{ 
				destroy royaltyVault
				return
			}
			let v <- royaltyVault!
			let originalBalance = v.balance
			if v.balance == 0.0{ 
				destroy v
				return
			}
			if royalties == nil{ 
				// no defined royalties on this NFT, return is back to the lender
				FlowtyUtils.trySendFungibleTokenVault(vault: <-v, receiver: self.lenderFungibleTokenReceiver, depositor: depositor)
				return
			}
			
			// distribute royalties!
			let tokenInfo = FlowtyUtils.getTokenInfo(self.details.paymentVaultType)!
			let royaltyCuts = FlowtyUtils.metadataRoyaltiesToRoyaltyCuts(tokenInfo: tokenInfo, mdRoyalties: [royalties!])
			FlowtyUtils.distributeRoyaltiesWithDepositor(royaltyCuts: royaltyCuts, depositor: depositor, vault: <-v)
		}
		
		// timeRemaining
		// The remaining time. This can be negative if is expired
		access(all)
		view fun timeRemaining(): Fix64{ 
			let fundingTerm = self.details.term
			let startTime = self.details.startTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(startTime + fundingTerm) - Fix64(currentTime)
			return remaining
		}
		
		// isFundingExpired
		access(all)
		view fun isFundingExpired(): Bool{ 
			let timeRemaining = self.timeRemaining()
			return timeRemaining < Fix64(0.0)
		}
		
		// initializer
		//
		init(flowtyStorefrontID: UInt64, listingResourceID: UInt64, ownerNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>, lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>, NFT: @{NonFungibleToken.NFT}, paymentVaultType: Type, repaymentAmount: UFix64, lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>, term: UFix64, fusdProviderCapability: Capability<&{FungibleToken.Provider}>?, royaltyVault: @{FungibleToken.Vault}?, listingDetails: ListingDetails){ 
			self.ownerNFTCollection = ownerNFTCollection
			self.lenderNFTCollection = lenderNFTCollection
			self.lenderFungibleTokenReceiver = lenderFungibleTokenReceiver
			self.fusdProviderCapability = fusdProviderCapability
			self.listingDetails = listingDetails
			self.NFT <- NFT
			self.royaltyVault <- royaltyVault
			
			// Store the detailed information
			self.details = FundingDetails(flowtyStorefrontID: flowtyStorefrontID, listingResourceID: listingResourceID, paymentVaultType: paymentVaultType, repaymentAmount: repaymentAmount, term: term)
		}
	}
	
	// FlowtyMarketplaceManager
	// An interface for adding and removing Fundings within a FlowtyMarketplace,
	// intended for use by the FlowtyStorefront's own
	//
	access(all)
	resource interface FlowtyMarketplaceManager{ 
		// createFunding
		// Allows the FlowtyMarketplace owner to create and insert Fundings.
		//
		access(contract)
		fun createFunding(
			flowtyStorefrontID: UInt64,
			listingResourceID: UInt64,
			ownerNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>,
			lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>,
			NFT: @{NonFungibleToken.NFT},
			paymentVaultType: Type,
			lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>,
			repaymentAmount: UFix64,
			term: UFix64,
			fusdProviderCapability: Capability<&{FungibleToken.Provider}>?,
			royaltyVault: @{FungibleToken.Vault}?,
			listingDetails: ListingDetails
		): UInt64
		
		// removeFunding
		// Allows the FlowtyMarketplace owner to remove any funding.
		//
		access(all)
		fun removeFunding(fundingResourceID: UInt64)
		
		access(all)
		fun borrowPrivateFunding(fundingResourceID: UInt64): &Funding?
	}
	
	// FlowtyMarketplacePublic
	// An interface to allow listing and borrowing Listings, and funding loans via Listings
	// in a FlowtyStorefront.
	//
	access(all)
	resource interface FlowtyMarketplacePublic{ 
		access(all)
		fun getFundingIDs(): [UInt64]
		
		access(all)
		fun borrowFunding(fundingResourceID: UInt64): &Funding?
	}
	
	// FlowtyStorefront
	// A resource that allows its owner to manage a list of Listings, and anyone to interact with them
	// in order to query their details and fund the loans that they represent.
	//
	access(all)
	resource FlowtyMarketplace: FlowtyMarketplaceManager, FlowtyMarketplacePublic{ 
		// The dictionary of Fundings uuids to Funding resources.
		access(self)
		var fundings: @{UInt64: Funding}
		
		// insert
		// Create and publish a funding for an NFT.
		//
		access(contract)
		fun createFunding(flowtyStorefrontID: UInt64, listingResourceID: UInt64, ownerNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>, lenderNFTCollection: Capability<&{NonFungibleToken.CollectionPublic}>, NFT: @{NonFungibleToken.NFT}, paymentVaultType: Type, lenderFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>, repaymentAmount: UFix64, term: UFix64, fusdProviderCapability: Capability<&{FungibleToken.Provider}>?, royaltyVault: @{FungibleToken.Vault}?, listingDetails: ListingDetails): UInt64{ 
			// FundingAvailable event fields
			let nftID = NFT.id
			let nftType = NFT.getType()
			let lenderVaultCap = lenderFungibleTokenReceiver.borrow()!
			let lender = (lenderVaultCap.owner!).address
			let borrowerNFTCollectionCap = ownerNFTCollection.borrow()!
			let borrower = (borrowerNFTCollectionCap.owner!).address
			
			// Create funding resource
			let funding <- create Funding(flowtyStorefrontID: flowtyStorefrontID, listingResourceID: listingResourceID, ownerNFTCollection: ownerNFTCollection, lenderNFTCollection: lenderNFTCollection, NFT: <-NFT, paymentVaultType: paymentVaultType, repaymentAmount: repaymentAmount, lenderFungibleTokenReceiver: lenderFungibleTokenReceiver, term: term, fusdProviderCapability: fusdProviderCapability, royaltyVault: <-royaltyVault, listingDetails: listingDetails)
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Created, listing: &funding as &{FlowtyListingCallback.Listing}, nft: funding.borrowNFT())
			}
			let fundingResourceID = funding.uuid
			
			// Add the new Funding to the dictionary.
			let oldFunding <- self.fundings[fundingResourceID] <- funding
			// Note that oldFunding will always be nil, but we have to handle it.
			destroy oldFunding
			let enabledAutoRepayment = fusdProviderCapability != nil
			emit FundingAvailable(fundingResourceID: fundingResourceID, listingResourceID: listingResourceID, borrower: borrower, lender: lender, nftID: nftID, nftType: nftType.identifier, repaymentAmount: repaymentAmount, enabledAutoRepayment: enabledAutoRepayment, repaymentAddress: fusdProviderCapability?.address)
			return fundingResourceID
		}
		
		// removeFunding
		// Remove a Funding.
		//
		access(all)
		fun removeFunding(fundingResourceID: UInt64){ 
			let funding <- self.fundings.remove(key: fundingResourceID) ?? panic("missing Funding")
			assert(funding.getDetails().repaid == true || funding.getDetails().settled == true, message: "funding is not repaid or settled")
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &funding as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			
			// This will emit a FundingCompleted event.
			destroy funding
		}
		
		// getFundingIDs
		// Returns an array of the Funding resource IDs that are in the collection
		//
		access(all)
		fun getFundingIDs(): [UInt64]{ 
			return self.fundings.keys
		}
		
		// borrowFunding
		// Returns a read-only view of the Funding for the given fundingID if it is contained by this collection.
		//
		access(all)
		fun borrowFunding(fundingResourceID: UInt64): &Funding?{ 
			if self.fundings[fundingResourceID] != nil{ 
				return &self.fundings[fundingResourceID] as &Funding?
			} else{ 
				return nil
			}
		}
		
		// borrowPrivateFunding
		// Returns a private view of the Funding for the given fundingID if it is contained by this collection.
		//
		access(all)
		fun borrowPrivateFunding(fundingResourceID: UInt64): &Funding?{ 
			if self.fundings[fundingResourceID] != nil{ 
				return &self.fundings[fundingResourceID] as &Funding?
			} else{ 
				return nil
			}
		}
		
		// destructor
		//
		// constructor
		//
		init(){ 
			self.fundings <-{} 
			
			// Let event consumers know that this storefront exists
			emit FlowtyMarketplaceInitialized(flowtyMarketplaceResourceID: self.uuid)
		}
	}
	
	// FlowtyStorefrontManager
	// An interface for adding and removing Listings within a FlowtyStorefront,
	// intended for use by the FlowtyStorefront's own
	access(all)
	resource interface FlowtyStorefrontManager{ 
		// createListing
		// Allows the FlowtyStorefront owner to create and insert Listings.
		//
		access(all)
		fun createListing(
			payment: @{FungibleToken.Vault},
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>,
			nftPublicCollectionCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			fusdProviderCapability: Capability<&{FungibleToken.Provider}>?,
			nftType: Type,
			nftID: UInt64,
			amount: UFix64,
			interestRate: UFix64,
			term: UFix64,
			paymentVaultType: Type,
			paymentCuts: [
				PaymentCut
			],
			expiresAfter: UFix64
		): UInt64
		
		// removeListing
		// Allows the FlowtyStorefront owner to remove any sale listing, accepted or not.
		//
		access(all)
		fun removeListing(listingResourceID: UInt64)
	}
	
	// FlowtyStorefrontPublic
	// An interface to allow listing and borrowing Listings, and funding loans via Listings
	// in a FlowtyStorefront.
	//
	access(all)
	resource interface FlowtyStorefrontPublic{ 
		access(all)
		fun getListingIDs(): [UInt64]
		
		access(all)
		fun borrowListing(listingResourceID: UInt64): &Listing?
		
		access(all)
		fun cleanup(listingResourceID: UInt64)
		
		access(all)
		fun getRoyalties():{ String: Flowty.Royalty}
	}
	
	// FlowtyStorefront
	// A resource that allows its owner to manage a list of Listings, and anyone to interact with them
	// in order to query their details and fund the loans that they represent.
	//
	access(all)
	resource FlowtyStorefront: FlowtyStorefrontManager, FlowtyStorefrontPublic{ 
		// The dictionary of Listing uuids to Listing resources.
		access(self)
		var listings: @{UInt64: Listing}
		
		// insert
		// Create and publish a Listing for an NFT.
		//
		access(all)
		fun createListing(payment: @{FungibleToken.Vault}, nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftPublicCollectionCapability: Capability<&{NonFungibleToken.CollectionPublic}>, fusdProviderCapability: Capability<&{FungibleToken.Provider}>?, nftType: Type, nftID: UInt64, amount: UFix64, interestRate: UFix64, term: UFix64, paymentVaultType: Type, paymentCuts: [PaymentCut], expiresAfter: UFix64): UInt64{ 
			pre{ 
				// We don't allow all tokens to be used as payment. Check that the provided one is supported.
				FlowtyUtils.isTokenSupported(type: paymentVaultType):
					"provided payment type is not supported"
				// make sure that the FUSD vault has at least the listing fee
				payment.balance == Flowty.ListingFee:
					"payment vault does not contain requested listing fee amount"
				// check that the repayment token type is the same as the payment token if repayment is not nil
				fusdProviderCapability == nil || (fusdProviderCapability!).check() && ((fusdProviderCapability!).borrow()!).getType() == paymentVaultType:
					"repayment vault type and payment vault type do not match"
				// There are no listing fees right now so this will ensure that no one attempts to send any
				payment.balance == 0.0:
					"no listing fee required"
				// make sure the payment type is the same as paymentVaultType
				payment.getType() == paymentVaultType:
					"payment type and paymentVaultType do not match"
				nftProviderCapability.check():
					"invalid nft provider"
			}
			let nft = (nftProviderCapability.borrow()!).borrowNFT(nftID)
			assert(nft.getType() == nftType, message: "incorrect nft type")
			assert(FlowtyUtils.isSupported(nft!), message: "nft type is not supported")
			let royaltyRate = FlowtyUtils.getRoyaltyRate(nft!)
			let listing <- create Listing(nftProviderCapability: nftProviderCapability, nftPublicCollectionCapability: nftPublicCollectionCapability, fusdProviderCapability: fusdProviderCapability, nftType: nftType, nftID: nftID, amount: amount, interestRate: interestRate, term: term, paymentVaultType: paymentVaultType, paymentCuts: paymentCuts, flowtyStorefrontID: self.uuid, expiresAfter: expiresAfter, royaltyRate: royaltyRate)
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Created, listing: &listing as &{FlowtyListingCallback.Listing}, nft: nft)
			}
			let listingResourceID = listing.uuid
			let expiration = listing.getDetails().expiresAfter
			
			// Add the new listing to the dictionary.
			let oldListing <- self.listings[listingResourceID] <- listing
			// Note that oldListing will always be nil, but we have to handle it.
			destroy oldListing
			
			// Listing fee
			// let listingFee <- payment.withdraw(amount: Flowty.ListingFee)
			// let flowtyFusdReceiver = Flowty.account.borrow<&FUSD.Vault{FungibleToken.Receiver}>(from: Flowty.FusdVaultStoragePath)
			//	 ?? panic("Missing or mis-typed FUSD Reveiver")
			// flowtyFusdReceiver.deposit(from: <-listingFee)
			destroy payment
			let enabledAutoRepayment = fusdProviderCapability != nil
			emit ListingAvailable(flowtyStorefrontAddress: self.owner?.address!, flowtyStorefrontID: self.uuid, listingResourceID: listingResourceID, nftType: nftType.identifier, nftID: nftID, amount: amount, interestRate: interestRate, term: term, enabledAutoRepayment: enabledAutoRepayment, royaltyRate: royaltyRate, expiresAfter: expiration, paymentTokenType: paymentVaultType.identifier, repaymentAddress: fusdProviderCapability?.address)
			return listingResourceID
		}
		
		// removeListing
		// Remove a Listing that has not yet been funded from the collection and destroy it.
		//
		access(all)
		fun removeListing(listingResourceID: UInt64){ 
			let listing <- self.listings.remove(key: listingResourceID) ?? panic("missing Listing")
			if let callback = Flowty.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &listing as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			
			// This will emit a ListingCompleted event.
			destroy listing
		}
		
		// getListingIDs
		// Returns an array of the Listing resource IDs that are in the collection
		//
		access(all)
		fun getListingIDs(): [UInt64]{ 
			return self.listings.keys
		}
		
		// borrowListing
		// Returns a read-only view of the Listing for the given listingID if it is contained by this collection.
		//
		access(all)
		fun borrowListing(listingResourceID: UInt64): &Listing?{ 
			if self.listings[listingResourceID] != nil{ 
				return &self.listings[listingResourceID] as &Listing?
			} else{ 
				return nil
			}
		}
		
		// cleanup
		// Remove an listing *if* it has been funded and expired.
		// Anyone can call, but at present it only benefits the account owner to do so.
		// Kind purchasers can however call it if they like.
		//
		access(all)
		fun cleanup(listingResourceID: UInt64){ 
			pre{ 
				self.listings[listingResourceID] != nil:
					"could not find listing with given id"
			}
			let listing <- self.listings.remove(key: listingResourceID)!
			assert(listing.getDetails().funded == true, message: "listing is not funded, only admin can remove")
			destroy listing
		}
		
		access(all)
		fun getRoyalties():{ String: Flowty.Royalty}{ 
			return Flowty.Royalties
		}
		
		// destructor
		//
		// constructor
		//
		init(){ 
			self.listings <-{} 
			
			// Let event consumers know that this storefront exists
			emit FlowtyStorefrontInitialized(flowtyStorefrontResourceID: self.uuid)
		}
	}
	
	// createStorefront
	// Make creating a FlowtyStorefront publicly accessible.
	//
	access(all)
	fun createStorefront(): @FlowtyStorefront{ 
		return <-create FlowtyStorefront()
	}
	
	access(account)
	fun borrowMarketplace(): &Flowty.FlowtyMarketplace{ 
		return self.account.storage.borrow<&Flowty.FlowtyMarketplace>(
			from: Flowty.FlowtyMarketplaceStoragePath
		)!
	}
	
	access(all)
	fun borrowMarketplacePublic(): &Flowty.FlowtyMarketplace{ 
		let mp =
			self.account.capabilities.get<&Flowty.FlowtyMarketplace>(
				Flowty.FlowtyMarketplacePublicPath
			).borrow()
			?? panic("marketplac does not exist")
		return mp
	}
	
	access(all)
	fun getRoyaltySafe(nftTypeIdentifier: String): Royalty?{ 
		return Flowty.Royalties[nftTypeIdentifier]
	}
	
	access(all)
	fun getRoyalty(nftTypeIdentifier: String): Royalty{ 
		return Flowty.Royalties[nftTypeIdentifier]!
	}
	
	access(all)
	fun getTokenPaths():{ String: PublicPath}{ 
		return self.TokenPaths
	}
	
	access(all)
	fun settleFunding(fundingResourceID: UInt64){ 
		let marketplace = Flowty.borrowMarketplace()
		let funding = marketplace.borrowFunding(fundingResourceID: fundingResourceID)
		(funding!).settleFunding()
	}
	
	// FlowtyAdmin
	// Allows the adminitrator to set the amount of fees, set the suspended funding period
	//
	access(all)
	resource FlowtyAdmin{ 
		access(all)
		fun setFees(listingFixedFee: UFix64, fundingPercentageFee: UFix64){ 
			pre{ 
				// The UFix64 type covers a negative numbers
				fundingPercentageFee <= 1.0:
					"Funding fee should be a percentage"
			}
			Flowty.ListingFee = listingFixedFee
			Flowty.FundingFee = fundingPercentageFee
		}
		
		access(all)
		fun setSuspendedFundingPeriod(period: UFix64){ 
			Flowty.SuspendedFundingPeriod = period
		}
		
		access(all)
		fun setSupportedCollection(collection: String, state: Bool){ 
			Flowty.SupportedCollections[collection] = state
			emit CollectionSupportChanged(collectionIdentifier: collection, state: state)
		}
		
		access(all)
		fun setCollectionRoyalty(collection: String, royalty: Royalty){ 
			pre{ 
				royalty.Rate <= 1.0:
					"Royalty rate must be a percentage"
			}
			Flowty.Royalties[collection] = royalty
			emit RoyaltyAdded(collectionIdentifier: collection, rate: royalty.Rate)
		}
		
		access(all)
		fun registerFungibleTokenPath(vaultType: Type, path: PublicPath){ 
			Flowty.TokenPaths[vaultType.identifier] = path
		}
	}
	
	access(contract)
	fun borrowCallbackContainer(): &FlowtyListingCallback.Container?{ 
		return self.account.storage.borrow<&FlowtyListingCallback.Container>(
			from: FlowtyListingCallback.ContainerStoragePath
		)
	}
	
	init(){ 
		self.FlowtyStorefrontStoragePath = /storage/FlowtyStorefront
		self.FlowtyStorefrontPublicPath = /public/FlowtyStorefront
		self.FlowtyMarketplaceStoragePath = /storage/FlowtyMarketplace
		self.FlowtyMarketplacePublicPath = /public/FlowtyMarketplace
		self.FlowtyAdminStoragePath = /storage/FlowtyAdmin
		self.FusdVaultStoragePath = /storage/fusdVault
		self.FusdReceiverPublicPath = /public/fusdReceiver
		self.FusdBalancePublicPath = /public/fusdBalance
		self.ListingFee = 0.0 // Fixed FUSD
		
		self.FundingFee = 0.1 // Percentage of the interest, a number between 0 and 1.
		
		self.SuspendedFundingPeriod = 1.0 // Period in seconds
		
		self.Royalties ={} 
		self.SupportedCollections ={} 
		self.TokenPaths ={} 
		let marketplace <- create FlowtyMarketplace()
		self.account.storage.save(<-marketplace, to: self.FlowtyMarketplaceStoragePath)
		// create a public capability for the .Marketplace
		var capability_1 =
			self.account.capabilities.storage.issue<&Flowty.FlowtyMarketplace>(
				Flowty.FlowtyMarketplaceStoragePath
			)
		self.account.capabilities.publish(capability_1, at: Flowty.FlowtyMarketplacePublicPath)
		
		// FlowtyAdmin
		let flowtyAdmin <- create FlowtyAdmin()
		self.account.storage.save(<-flowtyAdmin, to: self.FlowtyAdminStoragePath)
		if self.account.storage.borrow<&AnyResource>(
			from: FlowtyListingCallback.ContainerStoragePath
		)
		== nil{ 
			let dnaHandler <- DNAHandler.createHandler()
			let listingHandler <-
				FlowtyListingCallback.createContainer(defaultHandler: <-dnaHandler)
			self.account.storage.save(
				<-listingHandler,
				to: FlowtyListingCallback.ContainerStoragePath
			)
		}
		emit FlowtyInitialized()
	}
}
