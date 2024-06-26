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
	Description: TheFabricantS2Minting Contract
   
	This contract lets users mint TheFabricantS2ItemNFT NFTs for a specified amount of FLOW
*/


// NOTE: WHEN PUSHING TO MN OR TN FOR WOW, YOU MUST SET THE EDITION CORRECTLY!!!!!!
// For Testnet: 161
// MN 486
// for testing: 1
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TheFabricantS2GarmentNFT from "./TheFabricantS2GarmentNFT.cdc"

import TheFabricantS2MaterialNFT from "./TheFabricantS2MaterialNFT.cdc"

import TheFabricantS2ItemNFT from "./TheFabricantS2ItemNFT.cdc"

import ItemNFT from "../0xfc91de5e6566cc7c/ItemNFT.cdc"

import TheFabricantS1ItemNFT from "../0x09e03b1f871b3513/TheFabricantS1ItemNFT.cdc"

import TheFabricantMysteryBox_FF1 from "../0xa0cbe021821c0965/TheFabricantMysteryBox_FF1.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import TheFabricantAccessPass from "./TheFabricantAccessPass.cdc"

access(all)
contract TheFabricantS2Minting{ 
	access(all)
	event ItemMintedAndTransferred(
		recipientAddr: Address,
		garmentDataID: UInt32,
		materialDataID: UInt32,
		primaryColor: String,
		secondaryColor: String,
		itemID: UInt64,
		itemDataID: UInt32,
		name: String,
		eventName: String,
		edition: String,
		variant: String,
		season: String
	)
	
	access(all)
	event EventAdded(eventName: String, eventDetail: EventDetail)
	
	access(all)
	event IsEventClosedChanged(eventName: String, isClosed: Bool)
	
	access(all)
	event MaxMintAmountChanged(eventName: String, newMax: UInt32)
	
	access(all)
	event PaymentTypeChanged(eventName: String, newPaymentType: Type)
	
	access(all)
	event PaymentAmountChanged(eventName: String, newPaymentAmount: UFix64)
	
	access(all)
	event ItemMinterCapabilityChanged(address: Address)
	
	access(all)
	event GarmentMinterCapabilityChanged(address: Address)
	
	access(all)
	event MaterialMinterCapabilityChanged(address: Address)
	
	access(all)
	event PaymentReceiverCapabilityChanged(address: Address, paymentType: Type)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(self)
	var eventsDetail:{ String: EventDetail}
	
	access(contract)
	var itemMinterCapability: Capability<&TheFabricantS2ItemNFT.Admin>?
	
	access(contract)
	var garmentMinterCapability: Capability<&TheFabricantS2GarmentNFT.Admin>?
	
	access(contract)
	var materialMinterCapability: Capability<&TheFabricantS2MaterialNFT.Admin>?
	
	access(contract)
	var paymentReceiverCapability: Capability<&{FungibleToken.Receiver}>?
	
	access(all)
	struct EventDetail{ 
		access(self)
		var addressMintCount:{ Address: UInt32}
		
		access(all)
		var closed: Bool
		
		access(all)
		var paymentAmount: UFix64
		
		access(all)
		var paymentType: Type
		
		access(all)
		var maxMintAmount: UInt32
		
		init(paymentAmount: UFix64, paymentType: Type, maxMintAmount: UInt32){ 
			self.addressMintCount ={} 
			self.closed = true
			self.paymentAmount = paymentAmount
			self.paymentType = paymentType
			self.maxMintAmount = maxMintAmount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeIsEventClosed(isClosed: Bool){ 
			self.closed = isClosed
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeMaxMintAmount(newMax: UInt32){ 
			self.maxMintAmount = newMax
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePaymentType(newPaymentType: Type){ 
			self.paymentType = newPaymentType
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePaymentAmount(newPaymentAmount: UFix64){ 
			self.paymentAmount = newPaymentAmount
		}
		
		access(contract)
		fun incrementAddressMintCount(address: Address){ 
			if self.addressMintCount[address] == nil{ 
				self.addressMintCount[address] = 1
			} else{ 
				self.addressMintCount[address] = self.addressMintCount[address]! + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressMintCount():{ Address: UInt32}{ 
			return self.addressMintCount
		}
	}
	
	// check if an address holds certain nfts to allow mint
	access(TMP_ENTITLEMENT_OWNER)
	view fun doesAddressHoldAccessPass(address: Address): Bool{ 
		var hasTheFabricantAccessPass: Bool = false
		if getAccount(address).capabilities.get<
			&{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}
		>(TheFabricantAccessPass.TheFabricantAccessPassCollectionPublicPath).check(){ 
			let collectionRef =
				getAccount(address).capabilities.get<
					&{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}
				>(TheFabricantAccessPass.TheFabricantAccessPassCollectionPublicPath).borrow<
					&{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}
				>()!
			hasTheFabricantAccessPass = collectionRef.getIDs().length > 0
		}
		return hasTheFabricantAccessPass
	}
	
	access(all)
	resource Minter{ 
		
		//call S2ItemNFT's mintItem function
		access(TMP_ENTITLEMENT_OWNER)
		fun mintAndTransferItem(
			garmentDataID: UInt32,
			materialDataID: UInt32,
			primaryColor: String,
			secondaryColor: String,
			payment: @{FungibleToken.Vault},
			eventName: String,
			accessPassRef: &TheFabricantAccessPass.NFT
		): @TheFabricantS2ItemNFT.NFT{ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] != nil:
					"event does not exist"
				(TheFabricantS2Minting.eventsDetail[eventName]!).closed == false:
					"minting is closed"
				payment.isInstance((TheFabricantS2Minting.eventsDetail[eventName]!).paymentType):
					"payment vault is not requested fungible token"
				TheFabricantS2Minting.doesAddressHoldAccessPass(address: (self.owner!).address):
					"address does not have an accesspass"
				accessPassRef != nil && payment.balance == 0.0 || accessPassRef != nil && payment.balance == (TheFabricantS2Minting.eventsDetail[eventName]!).paymentAmount:
					"Payment is free if you use a free mint from your access pass, otherwise you must pay the mint fee and hold an access pass"
				garmentDataID > 12 && materialDataID > 15:
					"garmentData and materialData not available for this event"
				(accessPassRef.owner!).address == 0xdc496a70f3b89c08:
					"Only the archive account can mint during mint test"
			}
			
			// If the user has provided an accessPassRef and 0.0 FLOW, 
			// then they wish to mint by spending an access unit 
			if payment.balance == 0.0{ 
				assert(accessPassRef.accessUnits > 0, message: "You have spent all of your access units!")
				assert(accessPassRef.campaignName == eventName, message: "You must use the correct AccessPass to mint")
				assert((accessPassRef.owner!).address == (self.owner!).address, message: "accessPass does not belong to owner")
				destroy accessPassRef.spendAccessUnit()
			// Access unit has now been spent and payment vault balance is 0, so the mint will be free
			}
			if (TheFabricantS2Minting.eventsDetail[eventName]!).getAddressMintCount()[
				(self.owner!).address
			]
			!= nil{ 
				if (TheFabricantS2Minting.eventsDetail[eventName]!).getAddressMintCount()[
					(self.owner!).address
				]!
				>= (TheFabricantS2Minting.eventsDetail[eventName]!).maxMintAmount{ 
					panic("Address has minted max amount of items already")
				}
			}
			
			// mint the garment and material
			let garment <-
				((TheFabricantS2Minting.garmentMinterCapability!).borrow()!).mintNFT(
					garmentDataID: garmentDataID
				)
			let material <-
				((TheFabricantS2Minting.materialMinterCapability!).borrow()!).mintNFT(
					materialDataID: materialDataID
				)
			
			// split the royalty from price to garment and material address
			let garmentData = garment.garment.garmentDataID
			let garmentRoyalties =
				TheFabricantS2GarmentNFT.getGarmentData(id: garmentData).getRoyalty()
			let materialData = material.material.materialDataID
			let materialRoyalties =
				TheFabricantS2MaterialNFT.getMaterialData(id: materialData).getRoyalty()
			let garmentRoyaltyCount = UFix64(garmentRoyalties.keys.length)
			let materialRoyaltyCount = UFix64(materialRoyalties.keys.length)
			let paymentAmount = payment.balance
			for key in garmentRoyalties.keys{ 
				var paymentSplit: UFix64 = paymentAmount * 0.45 / garmentRoyaltyCount
				if key == "The Fabricant"{ 
					paymentSplit = paymentAmount * 0.3
				}
				if key as! String == "World Of Women"{ 
					paymentSplit = paymentAmount * 0.15
				}
				if let garmentRoyaltyReceiver = (garmentRoyalties[key]!).wallet.borrow(){ 
					let garmentRoyaltyPaymentCut <- payment.withdraw(amount: paymentSplit)
					garmentRoyaltyReceiver.deposit(from: <-garmentRoyaltyPaymentCut)
				}
			}
			for key in materialRoyalties.keys{ 
				let paymentSplit = paymentAmount * 0.45 / materialRoyaltyCount
				if let materialRoyaltyReceiver = (materialRoyalties[key]!).wallet.borrow(){ 
					let materialRoyaltyPaymentCut <- payment.withdraw(amount: paymentSplit)
					materialRoyaltyReceiver.deposit(from: <-materialRoyaltyPaymentCut)
				}
			}
			
			// testnet: 161
			// mainnet: 486
			// for test purposes we use 1, so before this 2 items were minted,
			// edition for next season at 1
			let edition = (TheFabricantS2ItemNFT.totalSupply - 486).toString()
			
			// create the metadata for the item
			let metadatas:{ String: TheFabricantS2ItemNFT.Metadata} ={} 
			metadatas["itemImage"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: "https://leela.mypinata.cloud/ipfs/QmU5aYSJ7js6KpuJNw7R7pTBvGmJoucX9GWBWfB6rJFrfa",
					mutable: true
				)
			metadatas["itemVideo"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: "https://leela.mypinata.cloud/ipfs/QmcQHb28TADJjzTkJgXKekWs5WFbyFsNwEez8Msc9uZ248/WoW_unboxing_LOOP.mp4",
					mutable: true
				)
			metadatas["itemImage2"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: "",
					mutable: true
				)
			metadatas["itemImage3"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: "",
					mutable: true
				)
			metadatas["itemImage4"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: "",
					mutable: true
				)
			metadatas["season"] = TheFabricantS2ItemNFT.Metadata(metadataValue: "2", mutable: false)
			metadatas["edition"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: edition,
					mutable: false
				)
			metadatas["eventName"] = TheFabricantS2ItemNFT.Metadata(
					metadataValue: eventName,
					mutable: false
				)
			((			  
			  // create the item data with allocation for the item
			  TheFabricantS2Minting.itemMinterCapability!).borrow()!).createItemDataWithAllocation(
				garmentDataID: garment.garment.garmentDataID,
				materialDataID: material.material.materialDataID,
				primaryColor: primaryColor,
				secondaryColor: secondaryColor,
				metadatas: metadatas,
				coCreator: (self.owner!).address
			)
			
			// create the royalty struct for the item
			let royalty =
				TheFabricantS2ItemNFT.Royalty(
					wallet: getAccount((self.owner!).address).capabilities.get<&FlowToken.Vault>(
						/public/flowTokenReceiver
					),
					initialCut: 0.3,
					cut: 0.1 / 3.0
				)
			
			//set mint count of transacter as 1 if first time, else increment
			let eventDetails = TheFabricantS2Minting.eventsDetail[eventName]!
			eventDetails.incrementAddressMintCount(address: (self.owner!).address)
			
			//update event detail for eventName with new detail
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetails
			
			//set initial name of item to "Season 2 WoW Collection #:id"
			let name = "Season 2 WoW Collection #".concat(edition)
			
			//user mints the item
			let item <-
				TheFabricantS2ItemNFT.mintNFT(
					name: name,
					royaltyVault: royalty,
					garment: <-garment,
					material: <-material,
					primaryColor: primaryColor,
					secondaryColor: secondaryColor
				)
			emit ItemMintedAndTransferred(
				recipientAddr: (self.owner!).address,
				garmentDataID: garmentDataID,
				materialDataID: materialDataID,
				primaryColor: primaryColor,
				secondaryColor: secondaryColor,
				itemID: item.id,
				itemDataID: item.item.itemDataID,
				name: name,
				eventName: eventName,
				edition: edition,
				variant: "PinkPurse",
				season: "2"
			)
			((			  
			  //The Fabricant receives the remainder of the payment ofter royalty split
			  TheFabricantS2Minting.paymentReceiverCapability!).borrow()!).deposit(from: <-payment)
			return <-item
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun changeIsEventClosed(eventName: String, isClosed: Bool){ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] != nil:
					"eventName doesnt exist"
			}
			let eventDetail = TheFabricantS2Minting.eventsDetail[eventName]!
			eventDetail.changeIsEventClosed(isClosed: isClosed)
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetail
			emit IsEventClosedChanged(eventName: eventName, isClosed: isClosed)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeMaxMintAmount(eventName: String, newMax: UInt32){ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] != nil:
					"eventName doesnt exist"
			}
			let eventDetail = TheFabricantS2Minting.eventsDetail[eventName]!
			eventDetail.changeMaxMintAmount(newMax: newMax)
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetail
			emit MaxMintAmountChanged(eventName: eventName, newMax: newMax)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePaymentType(eventName: String, newPaymentType: Type){ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] != nil:
					"eventName doesnt exist"
			}
			let eventDetail = TheFabricantS2Minting.eventsDetail[eventName]!
			eventDetail.changePaymentType(newPaymentType: newPaymentType)
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetail
			emit PaymentTypeChanged(eventName: eventName, newPaymentType: newPaymentType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePaymentAmount(eventName: String, newPaymentAmount: UFix64){ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] != nil:
					"eventName doesnt exist"
			}
			let eventDetail = TheFabricantS2Minting.eventsDetail[eventName]!
			eventDetail.changePaymentAmount(newPaymentAmount: newPaymentAmount)
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetail
			emit PaymentAmountChanged(eventName: eventName, newPaymentAmount: newPaymentAmount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeItemMinterCapability(minterCapability: Capability<&TheFabricantS2ItemNFT.Admin>){ 
			TheFabricantS2Minting.itemMinterCapability = minterCapability
			emit ItemMinterCapabilityChanged(address: minterCapability.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeGarmentMinterCapability(
			minterCapability: Capability<&TheFabricantS2GarmentNFT.Admin>
		){ 
			TheFabricantS2Minting.garmentMinterCapability = minterCapability
			emit GarmentMinterCapabilityChanged(address: minterCapability.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeMaterialMinterCapability(
			minterCapability: Capability<&TheFabricantS2MaterialNFT.Admin>
		){ 
			TheFabricantS2Minting.materialMinterCapability = minterCapability
			emit MaterialMinterCapabilityChanged(address: minterCapability.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePaymentReceiverCapability(
			paymentReceiverCapability: Capability<&{FungibleToken.Receiver}>
		){ 
			TheFabricantS2Minting.paymentReceiverCapability = paymentReceiverCapability
			emit PaymentReceiverCapabilityChanged(
				address: paymentReceiverCapability.address,
				paymentType: paymentReceiverCapability.getType()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addEvent(eventName: String, eventDetail: EventDetail){ 
			pre{ 
				TheFabricantS2Minting.eventsDetail[eventName] == nil:
					"eventName already exists"
			}
			TheFabricantS2Minting.eventsDetail[eventName] = eventDetail
			emit EventAdded(eventName: eventName, eventDetail: eventDetail)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createNewMinter(): @Minter{ 
		return <-create Minter()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getEventsDetail():{ String: EventDetail}{ 
		return TheFabricantS2Minting.eventsDetail
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPaymentReceiverAddress(): Address{ 
		return (TheFabricantS2Minting.paymentReceiverCapability!).address
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMinterCapabilityAddress(): Address{ 
		return (TheFabricantS2Minting.itemMinterCapability!).address
	}
	
	init(){ 
		self.paymentReceiverCapability = nil
		self.eventsDetail ={} 
		self.itemMinterCapability = nil
		self.garmentMinterCapability = nil
		self.materialMinterCapability = nil
		self.AdminStoragePath = /storage/TheFabricantS2MintingAdmin0028
		self.MinterStoragePath = /storage/TheFabricantS2Minter0028
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
