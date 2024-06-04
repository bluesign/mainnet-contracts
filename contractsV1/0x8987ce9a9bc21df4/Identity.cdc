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

	access(all)
contract Identity{ 
	access(all)
	event DelegationAdded(chainId: UInt8, operator: String, caller: Address?)
	
	access(all)
	let DelegationStoragePath: StoragePath
	
	access(all)
	let DelegationPublicPath: PublicPath
	
	access(all)
	var AddressesLookup:{ String:{ Address: Bool}}
	
	access(all)
	enum CHAINS: UInt8{ 
		access(all)
		case EVM
		
		access(all)
		case FLOW
		
		access(all)
		case BSC
		
		access(all)
		case TRON
	}
	
	access(all)
	resource Delegation{ 
		access(all)
		let chainId: CHAINS
		
		access(all)
		let address: String
		
		// We set the Chain id of the address
		init(chainId: CHAINS, address: String){ 
			self.chainId = chainId
			self.address = address
		}
	}
	
	access(all)
	resource interface DelegationsPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getDelegatedChains(): [Identity.CHAINS]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDelegation(chainId: CHAINS): &Delegation?
	}
	
	// Resource that contains functions to set and get delegations
	access(all)
	resource Delegations: DelegationsPublic{ 
		access(all)
		var delegations: @{CHAINS: Delegation}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun set(chainId: UInt8, address: String){ 
			let formattedAddress = address.toLower()
			var newDelegation <- create Delegation(chainId: Identity.CHAINS(rawValue: chainId) ?? panic("Invalid chain"), address: formattedAddress)
			let lookups = Identity.AddressesLookup[formattedAddress]
			if lookups != nil{ 
				let lookup = (lookups!)[(self.owner!).address]
				if lookup == nil{ 
					(lookups!).insert(key: (self.owner!).address, true)
					Identity.AddressesLookup.insert(key: formattedAddress, lookups!)
				}
			} else{ 
				var lookups:{ Address: Bool} ={} 
				lookups.insert(key: (self.owner!).address, true)
				Identity.AddressesLookup.insert(key: formattedAddress, lookups)
			}
			var oldDelegation = self.getDelegation(chainId: Identity.CHAINS(rawValue: chainId) ?? panic("Invalid chain"))
			if oldDelegation != nil{ 
				let lookupsToRemove = Identity.AddressesLookup[(oldDelegation!).address]
				(lookupsToRemove!).remove(key: (self.owner!).address)
				if (lookupsToRemove!).length == 0{ 
					Identity.AddressesLookup.remove(key: (oldDelegation!).address)
				} else{ 
					Identity.AddressesLookup[(oldDelegation!).address] = lookupsToRemove
				}
			}
			let oldDelegation2 <- self.delegations[newDelegation.chainId] <- newDelegation
			destroy oldDelegation2
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDelegatedChains(): [CHAINS]{ 
			return self.delegations.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDelegation(chainId: CHAINS): &Delegation?{ 
			return &self.delegations[chainId] as &Delegation?
		}
		
		init(){ 
			self.delegations <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createDelegations(): @Delegations{ 
		return <-create Delegations()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLookupsKeys(): [String]{ 
		return self.AddressesLookup.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLookupsByDelegatedAddress(address: String):{ Address: Bool}?{ 
		return self.AddressesLookup[address]
	}
	
	init(){ 
		self.DelegationStoragePath = /storage/Identity_v2
		self.DelegationPublicPath = /public/Identity_v2
		self.AddressesLookup ={} 
		
		// Create a Collection for the deployer
		let delegations <- create Delegations()
		self.account.storage.save(<-delegations, to: self.DelegationStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Identity.Delegations>(
				self.DelegationStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.DelegationPublicPath)
	}
}
