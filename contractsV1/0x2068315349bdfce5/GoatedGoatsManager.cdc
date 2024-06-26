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

	/*
	A contract that manages the creation and sale of Goated Goats, Traits, and Packs.

	A manager resource exists to allow modifications to the parameters of the public
	sale and have ability to mint editions themself.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import GoatedGoatsTrait from "./GoatedGoatsTrait.cdc"

import GoatedGoatsVouchers from "../0xdfc74d9d561374c0/GoatedGoatsVouchers.cdc"

import TraitPacksVouchers from "../0xdfc74d9d561374c0/TraitPacksVouchers.cdc"

import GoatedGoatsTraitPack from "./GoatedGoatsTraitPack.cdc"

import GoatedGoats from "./GoatedGoats.cdc"

access(all)
contract GoatedGoatsManager{ 
	// -----------------------------------------------------------------------
	//  Events
	// -----------------------------------------------------------------------
	// Emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	// -----------------------------------------------------------------------
	//  Trait
	// -----------------------------------------------------------------------
	// Emitted when an admin has initiated a mint of a GoatedGoat NFT
	access(all)
	event AdminMintTrait(id: UInt64)
	
	// Emitted when a GoatedGoatsTrait collection has had metadata updated
	access(all)
	event UpdateTraitCollectionMetadata()
	
	// Emitted when an edition within a GoatedGoatsTrait has had it's metadata updated
	access(all)
	event UpdateTraitEditionMetadata(id: UInt64)
	
	// -----------------------------------------------------------------------
	//  TraitPack
	// -----------------------------------------------------------------------
	// Emitted when an admin has initiated a mint of a GoatedGoat NFT
	access(all)
	event AdminMintTraitPack(id: UInt64)
	
	// Emitted when someone has redeemed a voucher for a trait pack
	access(all)
	event RedeemTraitPackVoucher(id: UInt64)
	
	// Emitted when someone has redeemed a trait pack for traits
	access(all)
	event RedeemTraitPack(id: UInt64, packID: UInt64, packEditionID: UInt64, address: Address)
	
	// Emitted when a GoatedGoatsTrait collection has had metadata updated
	access(all)
	event UpdateTraitPackCollectionMetadata()
	
	// Emitted when an edition within a GoatedGoatsTrait has had it's metadata updated
	access(all)
	event UpdateTraitPackEditionMetadata(id: UInt64)
	
	// Emitted when any info about redeem logistics has been modified
	access(all)
	event UpdateTraitPackRedeemInfo(redeemStartTime: UFix64)
	
	// -----------------------------------------------------------------------
	//  Goat
	// -----------------------------------------------------------------------
	// Emitted when someone has redeemed a voucher for a goat
	access(all)
	event RedeemGoatVoucher(id: UInt64, goatID: UInt64, address: Address)
	
	// Emitted whenever a goat trait action is done, e.g. equip/unequip
	access(all)
	event UpdateGoatTraits(id: UInt64, goatID: UInt64, address: Address)
	
	// Emitted when a GoatedGoats collection has had metadata updated
	access(all)
	event UpdateGoatCollectionMetadata()
	
	// Emitted when an edition within a GoatedGoats has had it's metadata updated
	access(all)
	event UpdateGoatEditionMetadata(id: UInt64)
	
	// Emitted when any info about redeem logistics has been modified
	access(all)
	event UpdateGoatRedeemInfo(redeemStartTime: UFix64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let ManagerStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// GoatedGoatsManager fields
	// -----------------------------------------------------------------------
	// -----------------------------------------------------------------------
	//  Trait
	// -----------------------------------------------------------------------
	access(self)
	let traitsMintedEditions:{ UInt64: Bool}
	
	access(self)
	var traitsSequentialMintMin: UInt64
	
	access(all)
	var traitTotalSupply: UInt64
	
	// -----------------------------------------------------------------------
	//  TraitPack
	// -----------------------------------------------------------------------
	access(self)
	let traitPacksMintedEditions:{ UInt64: Bool}
	
	access(self)
	let traitPacksByPackIdMintedEditions:{ UInt64:{ UInt64: Bool}}
	
	access(self)
	var traitPacksSequentialMintMin: UInt64
	
	access(self)
	var traitPacksByPackIdSequentialMintMin:{ UInt64: UInt64}
	
	access(all)
	var traitPackTotalSupply: UInt64
	
	access(all)
	var traitPackRedeemStartTime: UFix64
	
	// -----------------------------------------------------------------------
	//  Goat
	// -----------------------------------------------------------------------
	access(self)
	let goatsMintedEditions:{ UInt64: Bool}
	
	access(self)
	let goatsByGoatIdMintedEditions:{ UInt64: Bool}
	
	access(self)
	var goatsSequentialMintMin: UInt64
	
	access(all)
	var goatMaxSupply: UInt64
	
	access(all)
	var goatTotalSupply: UInt64
	
	access(all)
	var goatRedeemStartTime: UFix64
	
	// -----------------------------------------------------------------------
	// Manager resource for all NFTs
	// -----------------------------------------------------------------------
	access(all)
	resource Manager{ 
		// -----------------------------------------------------------------------
		//  Trait
		// -----------------------------------------------------------------------
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTraitCollectionMetadata(metadata:{ String: String}){ 
			GoatedGoatsTrait.setCollectionMetadata(metadata: metadata)
			emit UpdateTraitCollectionMetadata()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTraitEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
			GoatedGoatsTrait.setEditionMetadata(editionNumber: editionNumber, metadata: metadata)
			emit UpdateTraitEditionMetadata(id: editionNumber)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTraitAtEdition(edition: UInt64, packID: UInt64): @{NonFungibleToken.NFT}{ 
			emit AdminMintTrait(id: edition)
			return <-GoatedGoatsManager.mintTrait(edition: edition, packID: packID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSequentialTrait(packID: UInt64): @{NonFungibleToken.NFT}{ 
			let trait <- GoatedGoatsManager.mintSequentialTrait(packID: packID)
			emit AdminMintTrait(id: trait.id)
			return <-trait
		}
		
		// -----------------------------------------------------------------------
		//  TraitPack
		// -----------------------------------------------------------------------
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTraitPackCollectionMetadata(metadata:{ String: String}){ 
			GoatedGoatsTraitPack.setCollectionMetadata(metadata: metadata)
			emit UpdateTraitPackCollectionMetadata()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTraitPackEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
			GoatedGoatsTraitPack.setEditionMetadata(
				editionNumber: editionNumber,
				metadata: metadata
			)
			emit UpdateTraitPackEditionMetadata(id: editionNumber)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTraitPackAtEdition(edition: UInt64, packID: UInt64, packEditionID: UInt64): @{
			NonFungibleToken.NFT
		}{ 
			emit AdminMintTraitPack(id: edition)
			return <-GoatedGoatsManager.mintTraitPack(
				edition: edition,
				packID: packID,
				packEditionID: packEditionID
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSequentialTraitPack(packID: UInt64): @{NonFungibleToken.NFT}{ 
			let trait <- GoatedGoatsManager.mintSequentialTraitPack(packID: packID)
			emit AdminMintTraitPack(id: trait.id)
			return <-trait
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTraitPackRedeemStartTime(_ redeemStartTime: UFix64){ 
			GoatedGoatsManager.traitPackRedeemStartTime = redeemStartTime
			emit UpdateTraitPackRedeemInfo(
				redeemStartTime: GoatedGoatsManager.traitPackRedeemStartTime
			)
		}
		
		// -----------------------------------------------------------------------
		//  Goat
		// -----------------------------------------------------------------------
		access(TMP_ENTITLEMENT_OWNER)
		fun updateGoatCollectionMetadata(metadata:{ String: String}){ 
			GoatedGoats.setCollectionMetadata(metadata: metadata)
			emit UpdateGoatCollectionMetadata()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateGoatEditionMetadata(
			goatID: UInt64,
			metadata:{ 
				String: String
			},
			traitSlots: UInt8
		){ 
			GoatedGoats.setEditionMetadata(
				goatID: goatID,
				metadata: metadata,
				traitSlots: traitSlots
			)
			emit UpdateGoatEditionMetadata(id: goatID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateGoatRedeemStartTime(_ redeemStartTime: UFix64){ 
			GoatedGoatsManager.goatRedeemStartTime = redeemStartTime
			emit UpdateGoatRedeemInfo(redeemStartTime: GoatedGoatsManager.goatRedeemStartTime)
		}
	}
	
	// -----------------------------------------------------------------------
	//  Trait
	// -----------------------------------------------------------------------
	// Mint a GoatedGoatTrait
	access(contract)
	fun mintTrait(edition: UInt64, packID: UInt64): @{NonFungibleToken.NFT}{ 
		pre{ 
			edition >= 1:
				"Requested edition is outside of allowed bounds."
			self.traitsMintedEditions[edition] == nil:
				"Requested edition has already been minted"
		}
		self.traitsMintedEditions[edition] = true
		self.traitTotalSupply = self.traitTotalSupply + 1
		let trait <- GoatedGoatsTrait.mint(nftID: edition, packID: packID)
		return <-trait
	}
	
	// Look for the next available trait, and mint there
	access(self)
	fun mintSequentialTrait(packID: UInt64): @{NonFungibleToken.NFT}{ 
		var curEditionNumber = self.traitsSequentialMintMin
		while self.traitsMintedEditions.containsKey(UInt64(curEditionNumber)){ 
			curEditionNumber = curEditionNumber + 1
		}
		self.traitsSequentialMintMin = curEditionNumber
		let newTrait <- self.mintTrait(edition: UInt64(curEditionNumber), packID: packID)
		return <-newTrait
	}
	
	// -----------------------------------------------------------------------
	//  TraitPack
	// -----------------------------------------------------------------------
	// Mint a GoatedGoatTraitPack
	access(contract)
	fun mintTraitPack(edition: UInt64, packID: UInt64, packEditionID: UInt64): @{
		NonFungibleToken.NFT
	}{ 
		pre{ 
			edition >= 1:
				"Requested edition is outside of allowed bounds."
			self.traitPacksMintedEditions[edition] == nil:
				"Requested edition has already been minted"
			self.traitPacksByPackIdMintedEditions[packID] == nil || (self.traitPacksByPackIdMintedEditions[packID]!)[packEditionID] == nil:
				"Requested pack edition has already been minted"
		}
		self.traitPacksMintedEditions[edition] = true
		// Setup packID if doesn't exist.
		if self.traitPacksByPackIdMintedEditions[packID] == nil{ 
			self.traitPacksByPackIdMintedEditions[packID] ={} 
		}
		// Set packEditionID status
		let ref = self.traitPacksByPackIdMintedEditions[packID]!
		ref[packEditionID] = true
		self.traitPacksByPackIdMintedEditions[packID] = ref
		self.traitPackTotalSupply = self.traitPackTotalSupply + 1
		let trait <-
			GoatedGoatsTraitPack.mint(nftID: edition, packID: packID, packEditionID: packEditionID)
		return <-trait
	}
	
	// Look for the next available trait pack, and mint there
	access(self)
	fun mintSequentialTraitPack(packID: UInt64): @{NonFungibleToken.NFT}{ 
		// Grab the resource ID aka editionID
		var curEditionNumber = self.traitPacksSequentialMintMin
		while self.traitPacksMintedEditions.containsKey(UInt64(curEditionNumber)){ 
			curEditionNumber = curEditionNumber + 1
		}
		self.traitPacksSequentialMintMin = curEditionNumber
		
		// Setup sequential ID for new packs
		if self.traitPacksByPackIdSequentialMintMin[packID] == nil{ 
			self.traitPacksByPackIdSequentialMintMin[packID] = 1
		}
		// Grab the packEditionID
		var curPackEditionNumber = self.traitPacksByPackIdSequentialMintMin[packID]!
		while (self.traitPacksByPackIdMintedEditions[packID]!).containsKey(
			UInt64(curPackEditionNumber)
		){ 
			curPackEditionNumber = curPackEditionNumber + 1
		}
		self.traitPacksByPackIdSequentialMintMin[packID] = curPackEditionNumber
		let newTrait <-
			self.mintTraitPack(
				edition: UInt64(curEditionNumber),
				packID: packID,
				packEditionID: UInt64(curPackEditionNumber)
			)
		return <-newTrait
	}
	
	// -----------------------------------------------------------------------
	//  Goat
	// -----------------------------------------------------------------------
	// Mint a GoatedGoat
	access(contract)
	fun mintGoat(
		edition: UInt64,
		goatID: UInt64,
		traitActions: UInt64,
		goatCreationDate: UFix64,
		lastTraitActionDate: UFix64
	): @{NonFungibleToken.NFT}{ 
		pre{ 
			edition >= 1:
				"Requested edition is outside of allowed bounds."
			goatID >= 1 && goatID <= self.goatMaxSupply:
				"Requested goat ID is outside of allowed bounds."
			self.goatsMintedEditions[edition] == nil:
				"Requested edition has already been minted"
			self.goatsByGoatIdMintedEditions[goatID] == nil:
				"Requested goat ID has already been minted"
		}
		self.goatsMintedEditions[edition] = true
		self.goatsByGoatIdMintedEditions[goatID] = true
		self.goatTotalSupply = self.goatTotalSupply + 1
		let goat <-
			GoatedGoats.mint(
				nftID: edition,
				goatID: goatID,
				traitActions: traitActions,
				goatCreationDate: goatCreationDate,
				lastTraitActionDate: lastTraitActionDate
			)
		return <-goat
	}
	
	// Look for the next available goat, and mint there
	access(self)
	fun mintSequentialGoat(
		goatID: UInt64,
		traitActions: UInt64,
		goatCreationDate: UFix64,
		lastTraitActionDate: UFix64
	): @{NonFungibleToken.NFT}{ 
		// Grab the resource ID aka editionID
		var curEditionNumber = self.goatsSequentialMintMin
		while self.goatsMintedEditions.containsKey(UInt64(curEditionNumber)){ 
			curEditionNumber = curEditionNumber + 1
		}
		self.goatsSequentialMintMin = curEditionNumber
		let goat <-
			self.mintGoat(
				edition: UInt64(curEditionNumber),
				goatID: goatID,
				traitActions: traitActions,
				goatCreationDate: goatCreationDate,
				lastTraitActionDate: lastTraitActionDate
			)
		return <-goat
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	// -----------------------------------------------------------------------
	//  TraitPack
	// -----------------------------------------------------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun publicRedeemTraitPackWithVoucher(traitPackVoucher: @{NonFungibleToken.NFT}): @{
		NonFungibleToken.Collection
	}{ 
		pre{ 
			getCurrentBlock().timestamp >= self.traitPackRedeemStartTime:
				"Redemption has not yet started"
			traitPackVoucher.isInstance(Type<@TraitPacksVouchers.NFT>()):
				"Invalid type provided, expected TraitPacksVoucher.NFT"
		}
		
		// -- Burn voucher --
		let id = traitPackVoucher.id
		destroy traitPackVoucher
		
		// -- Mint the trait pack --
		let traitPackCollection <-
			GoatedGoatsTraitPack.createEmptyCollection(
				nftType: Type<@GoatedGoatsTraitPack.Collection>()
			)
		// Default To 1 for all Voucher Based Packs.
		let traitPack <- self.mintSequentialTraitPack(packID: 1)
		traitPackCollection.deposit(token: <-traitPack)
		emit RedeemTraitPackVoucher(id: id)
		return <-traitPackCollection
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun publicRedeemTraitPack(traitPack: @{NonFungibleToken.NFT}, address: Address){ 
		pre{ 
			getCurrentBlock().timestamp >= self.traitPackRedeemStartTime:
				"Redemption has not yet started"
			traitPack.isInstance(Type<@GoatedGoatsTraitPack.NFT>())
		}
		let traitPackInstance <- traitPack as! @GoatedGoatsTraitPack.NFT
		
		// Emit an event that our backend will read and mint traits to the associating address.
		emit RedeemTraitPack(
			id: traitPackInstance.id,
			packID: traitPackInstance.packID,
			packEditionID: traitPackInstance.packEditionID,
			address: address
		)
		// Burn trait pack
		destroy traitPackInstance
	}
	
	// -----------------------------------------------------------------------
	//  Goat
	// -----------------------------------------------------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun publicRedeemGoatWithVoucher(goatVoucher: @{NonFungibleToken.NFT}, address: Address): @{
		NonFungibleToken.Collection
	}{ 
		pre{ 
			getCurrentBlock().timestamp >= self.goatRedeemStartTime:
				"Redemption has not yet started"
			goatVoucher.isInstance(Type<@GoatedGoatsVouchers.NFT>()):
				"Invalid type provided, expected GoatedGoatsVouchers.NFT"
		}
		
		// -- Burn voucher --
		let id = goatVoucher.id
		destroy goatVoucher
		
		// -- Mint the goat with same Voucher ID --
		let goatCollection <-
			GoatedGoats.createEmptyCollection(nftType: Type<@GoatedGoats.Collection>())
		// Mint a clean goat with no equipped traits or counters
		let goat <-
			self.mintSequentialGoat(
				goatID: id,
				traitActions: 0,
				goatCreationDate: getCurrentBlock().timestamp,
				lastTraitActionDate: 0.0
			)
		let editionId = goat.id
		goatCollection.deposit(token: <-goat)
		emit RedeemGoatVoucher(id: editionId, goatID: id, address: address)
		return <-goatCollection
	}
	
	access(all)
	resource GoatAndTraits{ 
		// This is a list with only the goat.
		// Cannot move nested resource out of it otherwise.
		access(all)
		var goat: @[{NonFungibleToken.NFT}]
		
		access(all)
		var unequippedTraits: @[{NonFungibleToken.NFT}]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun extractGoat(): @{NonFungibleToken.NFT}{ 
			return <-self.goat.removeFirst()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun extractAllTraits(): @[{NonFungibleToken.NFT}]{ 
			var assets: @[{NonFungibleToken.NFT}] <- []
			self.unequippedTraits <-> assets
			assert(self.unequippedTraits.length == 0, message: "Couldn't extract all goats.")
			return <-assets
		}
		
		init(goat: @{NonFungibleToken.NFT}, unequippedTraits: @[{NonFungibleToken.NFT}]){ 
			self.goat <- [<-goat]
			self.unequippedTraits <- unequippedTraits
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun updateGoatTraits(
		goat: @{NonFungibleToken.NFT},
		traitsToEquip: @[{
			NonFungibleToken.NFT}
		],
		traitSlotsToUnequip: [
			String
		],
		address: Address
	): @GoatAndTraits{ 
		pre{ 
			getCurrentBlock().timestamp >= self.goatRedeemStartTime:
				"Updating traits on a goat in not enabled."
			goat != nil:
				"Goat not provided."
			goat.isInstance(Type<@GoatedGoats.NFT>()):
				"Invalid type provided, expected GoatedGoats.NFT"
			traitsToEquip.length != 0 || traitSlotsToUnequip.length != 0:
				"Must provide some action to take place."
		}
		// Get Goat typed instance
		let goatInstance <- goat as! @GoatedGoats.NFT
		// Unset the store of this Goat ID
		self.goatsByGoatIdMintedEditions[goatInstance.goatID] = nil
		// Mint a new goat with same Goat ID, traits to store, and counters (updated)
		let newGoat <-
			self.mintSequentialGoat(
				goatID: goatInstance.goatID,
				traitActions: goatInstance.traitActions + 1,
				goatCreationDate: goatInstance.goatCreationDate,
				lastTraitActionDate: getCurrentBlock().timestamp
			)
		let newGoatInstance <- newGoat as! @GoatedGoats.NFT
		let unequippedTraits: @[{NonFungibleToken.NFT}] <- []
		
		// Move traits over to the new Goat
		for traitSlot in goatInstance.traits.keys{ 
			let old <- newGoatInstance.setTrait(key: traitSlot, value: <-goatInstance.removeTrait(traitSlot))
			assert(old == nil, message: "Existing trait exists with this trait slot.")
			destroy old
		}
		// Destroy the old goat
		destroy goatInstance
		
		// First unequip anything provided and store in the return
		if traitSlotsToUnequip.length > 0{ 
			// For each trait ID, validate they exist in store, and return them.
			for traitSlot in traitSlotsToUnequip{ 
				assert(newGoatInstance.isTraitEquipped(traitSlot: traitSlot), message: "This goat has the provided trait slot empty.")
				let trait <- newGoatInstance.removeTrait(traitSlot)!
				assert(trait.getMetadata().containsKey("traitSlot"), message: "Provided trait is missing the trait slot.")
				unequippedTraits.append(<-trait)
			}
			assert(unequippedTraits.length == traitSlotsToUnequip.length, message: "Was not able to unequip all traits.")
		}
		
		// Equip the traits provided onto the new goat
		// If there are still traits on the goat swap them out and return them.
		if traitsToEquip.length > 0{ 
			while traitsToEquip.length > 0{ 
				let trait <- traitsToEquip.removeFirst() as! @GoatedGoatsTrait.NFT
				assert(trait.getMetadata().containsKey("traitSlot"), message: "Provided trait is missing the trait slot.")
				let traitSlot = trait.getMetadata()["traitSlot"]!
				// If goat already has this trait equipped, remove it
				if newGoatInstance.isTraitEquipped(traitSlot: traitSlot){ 
					let existingTrait <- newGoatInstance.removeTrait(traitSlot)!
					unequippedTraits.append(<-existingTrait)
				}
				let old <- newGoatInstance.setTrait(key: traitSlot, value: <-trait)
				assert(old == nil, message: "Existing trait exists with this trait slot.")
				destroy old
			}
			assert(traitsToEquip.length == 0, message: "Was not able to equip all traits.")
		}
		destroy traitsToEquip
		
		// Validate didn't equip too many traits.
		assert(
			newGoatInstance.traits.length <= Int(newGoatInstance.getTraitSlots()!),
			message: "Equipped more traits than this goat supports."
		)
		
		// Send event to the BE that will update the Goats image.
		emit UpdateGoatTraits(
			id: newGoatInstance.id,
			goatID: newGoatInstance.goatID,
			address: address
		)
		return <-create GoatAndTraits(goat: <-newGoatInstance, unequippedTraits: <-unequippedTraits)
	}
	
	init(){ 
		// Non-human modifiable variables
		// -----------------------------------------------------------------------
		//  Trait
		// -----------------------------------------------------------------------
		self.traitTotalSupply = 0
		self.traitsSequentialMintMin = 1
		// Start with no existing editions minted
		self.traitsMintedEditions ={} 
		// -----------------------------------------------------------------------
		//  TraitPack
		// -----------------------------------------------------------------------
		self.traitPackTotalSupply = 0
		self.traitPackRedeemStartTime = 4891048813.0
		self.traitPacksSequentialMintMin = 1
		// Start with no existing editions minted
		self.traitPacksMintedEditions ={} 
		// Setup with initial packID.
		self.traitPacksByPackIdMintedEditions ={ 1:{} }
		self.traitPacksByPackIdSequentialMintMin ={ 1: 1}
		// -----------------------------------------------------------------------
		//  Goat
		// -----------------------------------------------------------------------
		self.goatTotalSupply = 0
		self.goatMaxSupply = 10000
		self.goatRedeemStartTime = 4891048813.0
		self.goatsSequentialMintMin = 1
		// Start with no existing editions minted
		self.goatsMintedEditions ={} 
		self.goatsByGoatIdMintedEditions ={} 
		
		// Manager resource is only saved to the deploying account's storage
		self.ManagerStoragePath = /storage/GoatedGoatsManager
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		emit ContractInitialized()
	}
}
