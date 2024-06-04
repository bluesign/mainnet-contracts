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

import FungibleTokenMetadataViews from "./../../standardsV1/FungibleTokenMetadataViews.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract Lama: ViewResolver{ 
	access(all)
	let LamaStoragePath: StoragePath
	
	access(all)
	let LamaPrivatePath: PrivatePath
	
	access(all)
	event Allowed(path: PrivatePath, limit: UFix64)
	
	access(all)
	event Collected(path: PrivatePath, limit: UFix64, receiver: Address)
	
	// private functions only accessed by Account Parent
	access(all)
	resource interface ParentAccess{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun collect(path: PrivatePath, receiverPath: PublicPath, receiver: Address): Void
	}
	
	// private functions only accessed by Account Child
	access(all)
	resource interface ChildAccess{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowance(path: PrivatePath, allowance: UFix64, provider: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>): Void
	}
	
	access(all)
	resource Allowance: ParentAccess, ChildAccess{ 
		access(self)
		var allowances:{ PrivatePath: UFix64}
		
		access(self)
		var collected:{ PrivatePath: UFix64}
		
		access(self)
		var capabilities:{ PrivatePath: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>}
		
		init(){ 
			self.allowances ={} 
			self.collected ={} 
			self.capabilities ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllowance(path: PrivatePath): UFix64{ 
			return self.allowances[path] ?? 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollected(path: PrivatePath): UFix64{ 
			return self.collected[path] ?? 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun collect(path: PrivatePath, receiverPath: PublicPath, receiver: Address){ 
			let childProvider: Capability<&{FungibleToken.Provider, FungibleToken.Balance}> = self.capabilities[path] ?? panic("FungibleToken.Provider capability not found for provider path")
			let childVault: &{FungibleToken.Provider, FungibleToken.Balance} = childProvider.borrow() ?? panic("Could not borrow FungibleToken.Provider")
			let parentVault: &{FungibleToken.Receiver} = getAccount(receiver).capabilities.get<&{FungibleToken.Receiver}>(receiverPath).borrow() ?? panic("Problem getting parent receiver for this public path")
			var collectable: UFix64 = self.getAllowance(path: path)
			if collectable == 0.0 || childVault.balance == 0.0{ 
				panic("No more tokens to be collected")
			}
			if collectable >= childVault.balance{ 
				collectable = childVault.balance
				// leave 0.001 for account storage in case of flow token
				let isTokenFlow: Bool = path == /private/flowTokenVault
				let storageAmount: UFix64 = 0.001 // TDB by user
				
				if isTokenFlow && childVault.balance >= storageAmount{ 
					collectable = childVault.balance - storageAmount
				}
			}
			parentVault.deposit(from: <-childVault.withdraw(amount: collectable))
			self._setAllowance(path: path, allowance: self.getAllowance(path: path) - collectable)
			self.collected.insert(key: path, collectable + self.getCollected(path: path))
			emit Lama.Collected(path: path, limit: collectable, receiver: receiver)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAllowance(path: PrivatePath, allowance: UFix64, provider: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>){ 
			self.capabilities.insert(key: path, provider)
			self._setAllowance(path: path, allowance: allowance)
		}
		
		access(self)
		fun _setAllowance(path: PrivatePath, allowance: UFix64){ 
			self.allowances.insert(key: path, allowance)
			emit Lama.Allowed(path: path, limit: allowance)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createAllowance(): @Lama.Allowance{ 
		return <-create Allowance()
	}
	
	init(){ 
		self.LamaStoragePath = /storage/lama
		self.LamaPrivatePath = /private/lama
	}
}
