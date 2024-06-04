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

	import MotoGPAdmin from "./MotoGPAdmin.cdc"

import MotoGPPack from "./MotoGPPack.cdc"

import MotoGPCard from "./MotoGPCard.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ContractVersion from "./ContractVersion.cdc"

// Contract for managing pack opening.
//
// A PackOpener Collection is created when a user authorizes a tx that saves a PackOpener Collection in the user's storage.
// The user authorises transfer of a pack to the pack opener.
// The admin accesses the pack opener to open the pack, which deposits the cards into the user's
// card collection and destroys the pack.
//
access(all)
contract PackOpener: ContractVersion{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.0.0"
	}
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event PackOpened(packId: UInt64, packType: UInt64, cardIDs: [UInt64], serials: [UInt64])
	
	access(all)
	resource interface IPackOpenerPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(adminRef: &MotoGPAdmin.Admin, id: UInt64, cardIDs: [UInt64], serials: [UInt64]): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @MotoGPPack.NFT)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(id: UInt64): &MotoGPPack.NFT?
	}
	
	access(all)
	let packOpenerStoragePath: StoragePath
	
	access(all)
	let packOpenerPublicPath: PublicPath
	
	access(all)
	resource Collection: IPackOpenerPublic{ 
		access(self)
		let packMap: @{UInt64: MotoGPPack.NFT}
		
		access(self)
		let cardCollectionCap: Capability<&MotoGPCard.Collection>
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.packMap.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @MotoGPPack.NFT){ 
			let id: UInt64 = token.id
			let oldToken <- self.packMap[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		// The withdraw method is not part of IPackOpenerPublic interface, and can only be accessed by the PackOpener collection owner
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @MotoGPPack.NFT{ 
			let token <- self.packMap.remove(key: withdrawID) ?? panic("MotoGPPack not found and can't be removed")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// The openPack method requires a admin reference as argument to open the pack
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(adminRef: &MotoGPAdmin.Admin, id: UInt64, cardIDs: [UInt64], serials: [UInt64]){ 
			pre{ 
				adminRef != nil:
					"adminRef is nil"
				cardIDs.length == serials.length:
					"cardIDs and serials are not same length"
				UInt64(cardIDs.length) == UInt64(3):
					"cardsIDs.length is not 3"
			}
			let cardCollectionRef = self.cardCollectionCap.borrow()!
			let pack <- self.withdraw(withdrawID: id)
			var tempCardCollection <- MotoGPCard.createEmptyCollection(nftType: Type<@MotoGPCard.Collection>())
			let numberOfCards: UInt64 = UInt64(cardIDs.length)
			var i: UInt64 = 0
			while i < numberOfCards{ 
				let tempCardID = cardIDs[i]
				let tempSerial = serials[i]
				let newCard <- MotoGPCard.createNFT(cardID: tempCardID, serial: tempSerial)
				tempCardCollection.deposit(token: <-newCard)
				i = i + 1 as UInt64
			}
			cardCollectionRef.depositBatch(cardCollection: <-tempCardCollection)
			emit PackOpened(packId: id, packType: pack.packInfo.packType, cardIDs: cardIDs, serials: serials)
			destroy pack
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(id: UInt64): &MotoGPPack.NFT?{ 
			return &self.packMap[id] as &MotoGPPack.NFT?
		}
		
		init(_cardCollectionCap: Capability<&MotoGPCard.Collection>){ 
			self.packMap <-{} 
			self.cardCollectionCap = _cardCollectionCap
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(cardCollectionCap: Capability<&MotoGPCard.Collection>): @Collection{ 
		return <-create Collection(_cardCollectionCap: cardCollectionCap)
	}
	
	init(){ 
		self.packOpenerStoragePath = /storage/motogpPackOpenerCollection
		self.packOpenerPublicPath = /public/motogpPackOpenerCollection
	}
}
