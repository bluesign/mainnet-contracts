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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import Bl0x from "./Bl0x.cdc"

import Bl0xPack from "./Bl0xPack.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Admin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	access(all)
	let AdminServerStoragePath: StoragePath
	
	access(all)
	let AdminServerPrivatePath: PrivatePath
	
	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	access(all)
	resource Server{} 
	
	/// ===================================================================================
	// Admin things
	/// ===================================================================================
	//Admin client to use for capability receiver pattern
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&Admin.Server>): Void
	}
	
	//admin proxy with capability receiver 
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&Server>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&Server>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerTrait(_ trait: Bl0x.Trait){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Bl0x.addTrait(trait)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintBl0x(recipient: &{NonFungibleToken.Receiver}, serial: UInt64, rootHash: String, season: UInt64, traits:{ String: UInt64}){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Bl0x.mintNFT(recipient: recipient, serial: serial, rootHash: rootHash, season: season, traits: traits)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun debug(_ value: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(value)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerPackMetadata(typeId: UInt64, metadata: Bl0xPack.Metadata){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Bl0xPack.registerMetadata(typeId: typeId, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintPacks(typeId: UInt64, hashes: [String]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let recipient = Admin.account.capabilities.get<&{NonFungibleToken.Receiver}>(Bl0xPack.CollectionPublicPath).borrow()!
			for hash in hashes{ 
				Bl0xPack.mintNFT(recipient: recipient, typeId: typeId, hash: hash)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun requeue(packId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let cap = Admin.account.storage.borrow<&Bl0xPack.Collection>(from: Bl0xPack.DLQCollectionStoragePath)!
			cap.requeue(packId: packId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun fulfill(packId: UInt64, rewardIds: [UInt64], salt: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Bl0xPack.fulfill(packId: packId, rewardIds: rewardIds, salt: salt)
		}
		
		//THis cap here could be the server really in this case
		access(TMP_ENTITLEMENT_OWNER)
		fun getProviderCap(): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(Bl0x.CollectionPrivatePath)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addRoyaltycut(_ cutInfo: MetadataViews.Royalty){ 
			Bl0x.addRoyaltycut(cutInfo)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/bl0xAdminProxy
		self.AdminProxyStoragePath = /storage/bl0xAdminProxy
		
		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.AdminServerPrivatePath = /private/bl0xAdminServer
		self.AdminServerStoragePath = /storage/bl0xAdminServer
		self.account.storage.save(<-create Server(), to: self.AdminServerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Server>(self.AdminServerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminServerPrivatePath)
	}
}
