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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheFabricantNFTAccess{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantNFTAccess contract Events
	// -----------------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let RedeemerStoragePath: StoragePath
	
	access(all)
	event EventAdded(eventName: String, types: [Type])
	
	access(all)
	event EventRedemption(
		eventName: String,
		address: Address,
		nftID: UInt64,
		nftType: Type,
		nftUuid: UInt64
	)
	
	access(all)
	event AccessListChanged(eventName: String, addresses: [Address])
	
	// eventName: {redeemerAddress: nftUuid}
	access(self)
	var event:{ String:{ Address: UInt64}}
	
	// eventName: [nftTypes]
	access(self)
	var eventToTypes:{ String: [Type]}
	
	// eventName: [addresses]
	access(self)
	var accessList:{ String: [Address]}
	
	access(all)
	resource Admin{ 
		
		//add event to event dictionary
		access(TMP_ENTITLEMENT_OWNER)
		fun addEvent(eventName: String, types: [Type]){ 
			pre{ 
				TheFabricantNFTAccess.event[eventName] == nil:
					"eventName already exists"
			}
			TheFabricantNFTAccess.event[eventName] ={} 
			TheFabricantNFTAccess.eventToTypes[eventName] = types
			emit EventAdded(eventName: eventName, types: types)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeAccessList(eventName: String, addresses: [Address]){ 
			TheFabricantNFTAccess.accessList[eventName] = addresses
			emit AccessListChanged(eventName: eventName, addresses: addresses)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource Redeemer{ 
		
		// user redeems an nft for an event
		access(TMP_ENTITLEMENT_OWNER)
		fun redeem(eventName: String, nftRef: &{NonFungibleToken.NFT}){ 
			pre{ 
				(nftRef.owner!).address == (self.owner!).address:
					"redeemer is not owner of nft"
				TheFabricantNFTAccess.event[eventName] != nil:
					"event does exist"
				!(TheFabricantNFTAccess.event[eventName]!).keys.contains((self.owner!).address):
					"address already redeemed for this event"
				!(TheFabricantNFTAccess.event[eventName]!).values.contains(nftRef.uuid):
					"nft is already used for redemption for this event"
			}
			let array = TheFabricantNFTAccess.getEventToTypes()[eventName]!
			if array.contains(nftRef.getType()){ 
				let oldAddressToUUID = TheFabricantNFTAccess.event[eventName]!
				oldAddressToUUID[(self.owner!).address] = nftRef.uuid
				TheFabricantNFTAccess.event[eventName] = oldAddressToUUID
				emit EventRedemption(eventName: eventName, address: (self.owner!).address, nftID: nftRef.id, nftType: nftRef.getType(), nftUuid: nftRef.uuid)
				return
			} else{ 
				panic("the nft you have provided is not a redeemable type for this event")
			}
		}
		
		// destructor
		//
		// initializer
		//
		init(){} 
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createNewRedeemer(): @Redeemer{ 
		return <-create Redeemer()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getEvent():{ String:{ Address: UInt64}}{ 
		return TheFabricantNFTAccess.event
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getEventToTypes():{ String: [Type]}{ 
		return TheFabricantNFTAccess.eventToTypes
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAccessList():{ String: [Address]}{ 
		return TheFabricantNFTAccess.accessList
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.event ={} 
		self.eventToTypes ={} 
		self.accessList ={} 
		self.AdminStoragePath = /storage/NFTAccessAdmin0022
		self.RedeemerStoragePath = /storage/NFTAccessRedeemer0022
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
