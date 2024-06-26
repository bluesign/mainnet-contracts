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

import FIND from "./FIND.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FindMarket from "./FindMarket.cdc"

import FindViews from "./FindViews.cdc"

import FindLostAndFoundWrapper from "./FindLostAndFoundWrapper.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FindAirdropper{ 
	access(all)
	event Airdropped(
		from: Address,
		fromName: String?,
		to: Address,
		toName: String?,
		uuid: UInt64,
		nftInfo: FindMarket.NFTInfo,
		context:{ 
			String: String
		},
		remark: String?
	)
	
	access(all)
	event AirdroppedToLostAndFound(
		from: Address,
		fromName: String?,
		to: Address,
		toName: String?,
		uuid: UInt64,
		nftInfo: FindMarket.NFTInfo,
		context:{ 
			String: String
		},
		remark: String?,
		ticketID: UInt64
	)
	
	access(all)
	event AirdropFailed(
		from: Address,
		fromName: String?,
		to: Address,
		toName: String?,
		uuid: UInt64,
		id: UInt64,
		type: String,
		context:{ 
			String: String
		},
		reason: String
	)
	
	// The normal way of airdrop. If the user didn't init account, they cannot receive it
	access(TMP_ENTITLEMENT_OWNER)
	fun safeAirdrop(
		pointer: FindViews.AuthNFTPointer,
		receiver: Address,
		path: PublicPath,
		context:{ 
			String: String
		},
		deepValidation: Bool
	){ 
		let toName = FIND.reverseLookup(receiver)
		let from = pointer.owner()
		let fromName = FIND.reverseLookup(from)
		if deepValidation && !pointer.valid(){ 
			emit AirdropFailed(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid NFT Pointer")
			return
		}
		let vr = pointer.getViewResolver()
		let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
		let receiverCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.Receiver}>(path)
		// calculate the required storage and check sufficient balance
		let senderStorageBeforeSend = getAccount(from).storage.used
		let item <- pointer.withdraw()
		let requiredStorage = senderStorageBeforeSend - getAccount(from).storage.used
		let receiverAvailableStorage =
			getAccount(receiver).storage.capacity - getAccount(receiver).storage.used
		// If requiredStorage > receiverAvailableStorage, deposit will not be successful, we will emit fail event and deposit back to the sender's collection
		if receiverAvailableStorage < requiredStorage{ 
			emit AirdropFailed(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Insufficient User Storage")
			pointer.deposit(<-item)
			return
		}
		if receiverCap.check(){ 
			emit Airdropped(from: from, fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
			(receiverCap.borrow()!).deposit(token: <-item)
			return
		} else{ 
			let collectionPublicCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.CollectionPublic}>(path)
			if collectionPublicCap.check(){ 
				let from = pointer.owner()
				emit Airdropped(from: from, fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: "Receiver Not Linked")
				(collectionPublicCap.borrow()!).deposit(token: <-item)
				return
			}
		}
		emit AirdropFailed(
			from: pointer.owner(),
			fromName: fromName,
			to: receiver,
			toName: toName,
			uuid: pointer.uuid,
			id: pointer.id,
			type: pointer.itemType.identifier,
			context: context,
			reason: "Invalid Receiver Capability"
		)
		pointer.deposit(<-item)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun forcedAirdrop(
		pointer: FindViews.AuthNFTPointer,
		receiver: Address,
		path: PublicPath,
		context:{ 
			String: String
		},
		storagePayment: &{FungibleToken.Vault},
		flowTokenRepayment: Capability<&FlowToken.Vault>,
		deepValidation: Bool
	){ 
		let toName = FIND.reverseLookup(receiver)
		let from = pointer.owner()
		let fromName = FIND.reverseLookup(from)
		if deepValidation && !pointer.valid(){ 
			emit AirdropFailed(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid NFT Pointer")
			return
		}
		let vr = pointer.getViewResolver()
		let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
		let receiverCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.Receiver}>(path)
		
		// use LostAndFound for dropping
		let ticketID =
			FindLostAndFoundWrapper.depositNFT(
				receiver: receiver,
				collectionPublicPath: path,
				item: pointer,
				memo: context["message"],
				storagePayment: storagePayment,
				flowTokenRepayment: flowTokenRepayment,
				subsidizeReceiverStorage: false
			)
		if ticketID == nil{ 
			emit Airdropped(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
			return
		}
		emit AirdroppedToLostAndFound(
			from: pointer.owner(),
			fromName: fromName,
			to: receiver,
			toName: toName,
			uuid: pointer.uuid,
			nftInfo: nftInfo,
			context: context,
			remark: nil,
			ticketID: ticketID!
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun subsidizedAirdrop(
		pointer: FindViews.AuthNFTPointer,
		receiver: Address,
		path: PublicPath,
		context:{ 
			String: String
		},
		storagePayment: &{FungibleToken.Vault},
		flowTokenRepayment: Capability<&FlowToken.Vault>,
		deepValidation: Bool
	){ 
		let toName = FIND.reverseLookup(receiver)
		let from = pointer.owner()
		let fromName = FIND.reverseLookup(from)
		if deepValidation && !pointer.valid(){ 
			emit AirdropFailed(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, id: pointer.id, type: pointer.itemType.identifier, context: context, reason: "Invalid NFT Pointer")
			return
		}
		let vr = pointer.getViewResolver()
		let nftInfo = FindMarket.NFTInfo(vr, id: pointer.id, detail: true)
		let receiverCap = getAccount(receiver).capabilities.get<&{NonFungibleToken.Receiver}>(path)
		
		// use LostAndFound for dropping
		let ticketID =
			FindLostAndFoundWrapper.depositNFT(
				receiver: receiver,
				collectionPublicPath: path,
				item: pointer,
				memo: context["message"],
				storagePayment: storagePayment,
				flowTokenRepayment: flowTokenRepayment,
				subsidizeReceiverStorage: true
			)
		if ticketID == nil{ 
			emit Airdropped(from: pointer.owner(), fromName: fromName, to: receiver, toName: toName, uuid: pointer.uuid, nftInfo: nftInfo, context: context, remark: nil)
			return
		}
		emit AirdroppedToLostAndFound(
			from: pointer.owner(),
			fromName: fromName,
			to: receiver,
			toName: toName,
			uuid: pointer.uuid,
			nftInfo: nftInfo,
			context: context,
			remark: nil,
			ticketID: ticketID!
		)
	}
}
