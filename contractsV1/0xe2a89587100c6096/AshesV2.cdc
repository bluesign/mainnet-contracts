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

	import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import Ashes from "./Ashes.cdc"

import UFC_NFT from "../0x329feb3ab062d289/UFC_NFT.cdc"

import AllDay from "../0xe4cf4bdc1751c65d/AllDay.cdc"

access(all)
contract AshesV2{ 
	access(contract)
	var recentBurn: [AshData?]
	
	access(all)
	var nextAshSerial: UInt64
	
	access(all)
	var allowMint: Bool
	
	access(all)
	var maxMessageSize: Int
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// admin events
	access(all)
	event AllowMintToggled(allowMint: Bool)
	
	// nft events
	access(all)
	event AshMinted(
		id: UInt64,
		ashSerial: UInt64,
		nftType: Type,
		nftID: UInt64,
		ashMeta:{ 
			String: String
		}
	)
	
	access(all)
	event AshDestroyed(id: UInt64)
	
	// Ash Collection events
	access(all)
	event AshWithdrawn(id: UInt64, from: Address?)
	
	access(all)
	event AshDeposited(id: UInt64, to: Address?)
	
	// Declare the NFT resource type
	access(all)
	struct AshData{ 
		access(all)
		let meta:{ String: String}
		
		access(all)
		let ashSerial: UInt64
		
		access(all)
		let nftType: Type
		
		access(all)
		let nftID: UInt64
		
		init(ashSerial: UInt64, nftType: Type, nftID: UInt64, ashMeta:{ String: String}){ 
			ashMeta["_burnedAtTimestamp"] = getCurrentBlock().timestamp.toString()
			ashMeta["_burnedAtBlockheight"] = getCurrentBlock().height.toString()
			self.meta = ashMeta
			self.ashSerial = ashSerial
			self.nftType = nftType
			self.nftID = nftID
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRecentBurn(index: Int): AshData?{ 
		return self.recentBurn[index]
	}
	
	access(self)
	fun addRecentBurn(ashData: AshData){ 
		self.recentBurn.append(ashData)
	}
	
	access(self)
	fun setRecentBurn(ashData: AshData, index: Int){ 
		self.recentBurn[index] = ashData
	}
	
	access(all)
	resource Ash{ 
		access(all)
		let data: AshData
		
		init(
			nftType: Type,
			nftID: UInt64,
			ashMeta:{ 
				String: String
			},
			serial: UInt64,
			overwriteSerial: Bool
		){ 
			if !AshesV2.allowMint{ 
				panic("minting is closed")
			}
			if let msg = ashMeta["_message"]{ 
				if (msg!).length > AshesV2.maxMessageSize{ 
					panic("message exceeds max size")
				}
			}
			var ashSerial = AshesV2.nextAshSerial
			if overwriteSerial{ 
				ashSerial = serial
			} else{ 
				ashSerial = AshesV2.nextAshSerial
				AshesV2.nextAshSerial = AshesV2.nextAshSerial + 1
			}
			let ashData =
				AshData(ashSerial: ashSerial, nftType: nftType, nftID: nftID, ashMeta: ashMeta)
			self.data = ashData
			emit AshMinted(
				id: self.uuid,
				ashSerial: ashData.ashSerial,
				nftType: ashData.nftType,
				nftID: ashData.nftID,
				ashMeta: ashData.meta
			)
			if overwriteSerial{ 
				AshesV2.setRecentBurn(ashData: ashData, index: Int(ashSerial - 1))
			} else{ 
				AshesV2.addRecentBurn(ashData: ashData)
			}
		}
	}
	
	// We define this interface purely as a way to allow users
	// to create public, restricted references to their NFT Collection.
	// They would use this to only expose the deposit, getIDs,
	// and idExists fields in their Collection
	access(all)
	resource interface AshReceiver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @AshesV2.Ash): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAsh(id: UInt64): &Ash?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.uuid == id:
					"Cannot borrow ash reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: AshReceiver{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64: Ash}
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw
		//
		// Function that removes an NFT from the collection
		// and moves it to the calling context
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @Ash{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit AshWithdrawn(id: token.uuid, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		//
		// Function that takes a NFT as an argument and
		// adds it to the collections dictionary
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @Ash){ 
			// add the new token to the dictionary with a force assignment
			// if there is already a value at that key, it will fail and revert
			emit AshDeposited(id: token.uuid, to: self.owner?.address)
			self.ownedNFTs[token.uuid] <-! token
		}
		
		// idExists checks to see if a NFT
		// with the given ID exists in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAsh(id: UInt64): &Ash?{ 
			return (&self.ownedNFTs[id] as &Ash?)!
		}
	}
	
	// creates a new empty Collection resource and returns it
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintFromTopShot(topshotNFT: @TopShot.NFT, msg: String): @Ash{ 
		let ashMeta:{ String: String} ={} 
		ashMeta["_message"] = msg
		ashMeta["topshotID"] = topshotNFT.id.toString()
		ashMeta["topshotSerial"] = topshotNFT.data.serialNumber.toString()
		ashMeta["topshotSetID"] = topshotNFT.data.setID.toString()
		ashMeta["topshotPlayID"] = topshotNFT.data.playID.toString()
		let res <-
			create Ash(
				nftType: topshotNFT.getType(),
				nftID: topshotNFT.uuid,
				ashMeta: ashMeta,
				serial: 0,
				overwriteSerial: false
			)
		destroy topshotNFT
		return <-res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintFromVanillaAshes(vanillaAshNFT: @Ashes.Ash, msg: String): @Ash{ 
		let ashMeta:{ String: String} ={} 
		ashMeta["_message"] = msg
		ashMeta["vanillaAshTopshotID"] = vanillaAshNFT.id.toString()
		ashMeta["vanillaAshTopshotSerial"] = vanillaAshNFT.momentData.serialNumber.toString()
		ashMeta["vanillaAshTopshotSetID"] = vanillaAshNFT.momentData.setID.toString()
		ashMeta["vanillaAshTopshotPlayID"] = vanillaAshNFT.momentData.playID.toString()
		let res <-
			create Ash(
				nftType: vanillaAshNFT.getType(),
				nftID: vanillaAshNFT.uuid,
				ashMeta: ashMeta,
				serial: vanillaAshNFT.ashSerial,
				overwriteSerial: true
			)
		destroy vanillaAshNFT
		return <-res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintFromUFCStrike(ufcNFT: @UFC_NFT.NFT, msg: String): @Ash{ 
		let ashMeta:{ String: String} ={} 
		ashMeta["_message"] = msg
		ashMeta["ufcID"] = ufcNFT.id.toString()
		ashMeta["ufcSetID"] = ufcNFT.setId.toString()
		ashMeta["ufcEditionNum"] = ufcNFT.editionNum.toString()
		let res <-
			create Ash(
				nftType: ufcNFT.getType(),
				nftID: ufcNFT.uuid,
				ashMeta: ashMeta,
				serial: 0,
				overwriteSerial: false
			)
		destroy ufcNFT
		return <-res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintFromNFLAllDay(alldayNFT: @AllDay.NFT, msg: String): @Ash{ 
		let ashMeta:{ String: String} ={} 
		ashMeta["alldayID"] = alldayNFT.id.toString()
		ashMeta["alldayEditionID"] = alldayNFT.editionID.toString()
		ashMeta["alldaySerialNumber"] = alldayNFT.serialNumber.toString()
		ashMeta["alldayMintingDate"] = alldayNFT.mintingDate.toString()
		let res <-
			create Ash(
				nftType: alldayNFT.getType(),
				nftID: alldayNFT.uuid,
				ashMeta: ashMeta,
				serial: 0,
				overwriteSerial: false
			)
		destroy alldayNFT
		return <-res
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleAllowMint(allowMint: Bool){ 
			AshesV2.allowMint = allowMint
			emit AllowMintToggled(allowMint: allowMint)
		}
	}
	
	init(){ 
		// Set named paths
		self.CollectionStoragePath = /storage/AshesV2CollectionV2
		self.CollectionPublicPath = /public/AshesV2CollectionV2
		self.AdminStoragePath = /storage/AshesV2AdminV2
		self.AdminPrivatePath = /private/AshesV2AdminV2
		self.nextAshSerial = Ashes.nextAshSerial
		self.allowMint = false
		self.maxMessageSize = 420
		self.recentBurn = []
		var i = UInt64(1)
		while i < self.nextAshSerial{ 
			self.recentBurn.append(nil)
			i = i + 1
		}
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
