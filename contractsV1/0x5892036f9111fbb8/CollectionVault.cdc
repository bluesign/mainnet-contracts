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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract CollectionVault{ 
	access(all)
	event VaultAccessed(key: String)
	
	access(all)
	let DefaultStoragePath: StoragePath
	
	access(all)
	let DefaultPublicPath: PublicPath
	
	access(all)
	let DefaultPrivatePath: PrivatePath
	
	access(all)
	resource interface VaultPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun storeVaultPublic(
			capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		): Void
	}
	
	access(all)
	resource Vault: VaultPublic{ 
		access(contract)
		var storedCapabilities:{ String: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
		
		access(contract)
		var allowedPublic: [String]?
		
		access(contract)
		var enabled: Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getKeys(): [String]{ 
			return self.storedCapabilities.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasKey(_ key: String): Bool{ 
			let capability = self.storedCapabilities[key]
			if capability == nil{ 
				return false
			}
			return (capability!).check()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVault(_ key: String): &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}?{ 
			let capability = self.storedCapabilities[key]
			if capability == nil{ 
				return nil
			}
			emit VaultAccessed(key: key)
			return (capability!).borrow()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun storeVault(_ key: String, capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.storedCapabilities.insert(key: key, capability)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun storeVaultPublic(capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			let collection = capability.borrow() ?? panic("Could not borrow capability")
			let type = collection.getType().identifier
			if self.allowedPublic != nil && !(self.allowedPublic!).contains(type){ 
				panic("Type ".concat(type).concat(" is not allowed for storeVaultPublic"))
			}
			let owner = collection.owner ?? panic("Collection must be owned in order to use storeVaultPublic")
			let key = type.concat("@").concat(owner.address.toString())
			self.storedCapabilities.insert(key: key, capability)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeVault(_ key: String){ 
			self.storedCapabilities.remove(key: key)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowedPublic(_ allowedPublic: [String]?){ 
			self.allowedPublic = allowedPublic
		}
		
		init(_ allowedPublic: [String]?){ 
			self.storedCapabilities ={} 
			self.allowedPublic = allowedPublic
			self.enabled = true
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyVault(_ allowedPublic: [String]?): @Vault{ 
		return <-create Vault(allowedPublic)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAddress(): Address{ 
		return self.account.address
	}
	
	init(_ allowedPublic: [String]?){ 
		self.DefaultStoragePath = /storage/nftRealityCollectionVault
		self.DefaultPublicPath = /public/nftRealityCollectionVault
		self.DefaultPrivatePath = /private/nftRealityCollectionVault
		let vault <- create Vault(allowedPublic)
		self.account.storage.save(<-vault, to: self.DefaultStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{VaultPublic}>(self.DefaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.DefaultPublicPath)
	}
}
