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

	import FUSD from "./../../standardsV1/FUSD.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StarlyCardMarket from "./StarlyCardMarket.cdc"

access(all)
contract StarlyPack{ 
	// Since we are open to world, we need mechanism for securely selling packs to users without showing what is inside. StarlyPack.Purchased is an event that
	// that server relies on when giving pack to user. It checks packIDs (user must previously reserve those), price, correct addresses and cuts. It is
	// easy to fabricate this events with malformed ids, prices and address. Server job is to check all that information before giving pack to user.
	//
	// Actual NFTs are minted and deposited to user account when user opens pack.
	access(all)
	event Purchased(
		collectionID: String,
		packIDs: [
			String
		],
		price: UFix64,
		currency: String,
		buyerAddress: Address,
		beneficiarySaleCut: StarlyCardMarket.SaleCut,
		creatorSaleCut: StarlyCardMarket.SaleCut,
		additionalSaleCuts: [
			StarlyCardMarket.SaleCut
		]
	)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun purchase(
		collectionID: String,
		packIDs: [
			String
		],
		price: UFix64,
		buyerAddress: Address,
		paymentVault: @{FungibleToken.Vault},
		beneficiarySaleCutReceiver: StarlyCardMarket.SaleCutReceiver,
		creatorSaleCutReceiver: StarlyCardMarket.SaleCutReceiver,
		additionalSaleCutReceivers: [
			StarlyCardMarket.SaleCutReceiver
		]
	){ 
		pre{ 
			paymentVault.balance == price:
				"payment does not equal offer price"
			StarlyCardMarket.checkSaleCutReceiver(saleCutReceiver: beneficiarySaleCutReceiver):
				"Cannot borrow receiver in beneficiarySaleCutReceiver"
			StarlyCardMarket.checkSaleCutReceiver(saleCutReceiver: creatorSaleCutReceiver):
				"Cannot borrow receiver in creatorSaleCutReceiver"
			StarlyCardMarket.checkSaleCutReceivers(saleCutReceivers: additionalSaleCutReceivers):
				"Cannot borrow receiver in additionalSaleCutReceivers"
		}
		let beneficiaryCutAmount = price * beneficiarySaleCutReceiver.percent
		let beneficiaryCut <- paymentVault.withdraw(amount: beneficiaryCutAmount)
		(beneficiarySaleCutReceiver.receiver.borrow()!).deposit(from: <-beneficiaryCut)
		let creatorCutAmount = price * creatorSaleCutReceiver.percent
		let creatorCut <- paymentVault.withdraw(amount: creatorCutAmount)
		(creatorSaleCutReceiver.receiver.borrow()!).deposit(from: <-creatorCut)
		var additionalSaleCuts: [StarlyCardMarket.SaleCut] = []
		for additionalSaleCutReceiver in additionalSaleCutReceivers{ 
			let additionalCutAmount = price * additionalSaleCutReceiver.percent
			let additionalCut <- paymentVault.withdraw(amount: additionalCutAmount)
			(additionalSaleCutReceiver.receiver.borrow()!).deposit(from: <-additionalCut)
			additionalSaleCuts.append(StarlyCardMarket.SaleCut(address: additionalSaleCutReceiver.receiver.address, amount: additionalCutAmount, percent: additionalSaleCutReceiver.percent))
		}
		(		 // At this point paymentVault should be empty, any residiual amount goes to beneficiary to avoid resource loss.
		 beneficiarySaleCutReceiver.receiver.borrow()!).deposit(from: <-paymentVault)
		emit Purchased(
			collectionID: collectionID,
			packIDs: packIDs,
			price: price,
			currency: Type<@FUSD.Vault>().identifier,
			buyerAddress: buyerAddress,
			beneficiarySaleCut: StarlyCardMarket.SaleCut(
				address: beneficiarySaleCutReceiver.receiver.address,
				amount: beneficiaryCutAmount,
				percent: beneficiarySaleCutReceiver.percent
			),
			creatorSaleCut: StarlyCardMarket.SaleCut(
				address: creatorSaleCutReceiver.receiver.address,
				amount: creatorCutAmount,
				percent: creatorSaleCutReceiver.percent
			),
			additionalSaleCuts: additionalSaleCuts
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun purchaseV2(
		collectionID: String,
		packIDs: [
			String
		],
		price: UFix64,
		currency: Type,
		buyerAddress: Address,
		paymentVault: @{FungibleToken.Vault},
		beneficiarySaleCutReceiver: StarlyCardMarket.SaleCutReceiverV2,
		creatorSaleCutReceiver: StarlyCardMarket.SaleCutReceiverV2,
		additionalSaleCutReceivers: [
			StarlyCardMarket.SaleCutReceiverV2
		]
	){ 
		pre{ 
			paymentVault.balance == price:
				"payment does not equal offer price"
			paymentVault.isInstance(currency):
				"incorrect payment currency"
			StarlyCardMarket.checkSaleCutReceiverV2(saleCutReceiver: beneficiarySaleCutReceiver):
				"Cannot borrow receiver in beneficiarySaleCutReceiver"
			StarlyCardMarket.checkSaleCutReceiverV2(saleCutReceiver: creatorSaleCutReceiver):
				"Cannot borrow receiver in creatorSaleCutReceiver"
			StarlyCardMarket.checkSaleCutReceiversV2(saleCutReceivers: additionalSaleCutReceivers):
				"Cannot borrow receiver in additionalSaleCutReceivers"
		}
		let beneficiaryCutAmount = price * beneficiarySaleCutReceiver.percent
		let beneficiaryCut <- paymentVault.withdraw(amount: beneficiaryCutAmount)
		(beneficiarySaleCutReceiver.receiver.borrow()!).deposit(from: <-beneficiaryCut)
		let creatorCutAmount = price * creatorSaleCutReceiver.percent
		let creatorCut <- paymentVault.withdraw(amount: creatorCutAmount)
		(creatorSaleCutReceiver.receiver.borrow()!).deposit(from: <-creatorCut)
		var additionalSaleCuts: [StarlyCardMarket.SaleCut] = []
		for additionalSaleCutReceiver in additionalSaleCutReceivers{ 
			let additionalCutAmount = price * additionalSaleCutReceiver.percent
			let additionalCut <- paymentVault.withdraw(amount: additionalCutAmount)
			(additionalSaleCutReceiver.receiver.borrow()!).deposit(from: <-additionalCut)
			additionalSaleCuts.append(StarlyCardMarket.SaleCut(address: additionalSaleCutReceiver.receiver.address, amount: additionalCutAmount, percent: additionalSaleCutReceiver.percent))
		}
		(		 // At this point paymentVault should be empty, any residiual amount goes to beneficiary to avoid resource loss.
		 beneficiarySaleCutReceiver.receiver.borrow()!).deposit(from: <-paymentVault)
		emit Purchased(
			collectionID: collectionID,
			packIDs: packIDs,
			price: price,
			currency: currency.identifier,
			buyerAddress: buyerAddress,
			beneficiarySaleCut: StarlyCardMarket.SaleCut(
				address: beneficiarySaleCutReceiver.receiver.address,
				amount: beneficiaryCutAmount,
				percent: beneficiarySaleCutReceiver.percent
			),
			creatorSaleCut: StarlyCardMarket.SaleCut(
				address: creatorSaleCutReceiver.receiver.address,
				amount: creatorCutAmount,
				percent: creatorSaleCutReceiver.percent
			),
			additionalSaleCuts: additionalSaleCuts
		)
	}
}
