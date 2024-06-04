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

	// The Influencer Registry stores the mappings from the name of an
// influencer to the vaults in which they'd like to receive tokens,
// as well as the cut they'd like to take from marketplace transactions.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract InfluencerRegistry{ 
	
	// Emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a FT-receiving capability for an influencer has been updated
	// If address is nil, that means the capability has been removed.
	access(all)
	event CapabilityUpdated(name: String, ftType: Type, address: Address?)
	
	// Emitted when an influencer's cut percentage has been updated
	// If the cutPercentage is nil, that means it has been removed.
	access(all)
	event CutPercentageUpdated(name: String, cutPercentage: UFix64?)
	
	// Emitted when the default cut percentage has been updated
	access(all)
	event DefaultCutPercentageUpdated(cutPercentage: UFix64?)
	
	// capabilities is a mapping from influencer name, to fungible token ID, to
	// the capability for a receiver for the fungible token
	access(all)
	var capabilities:{ String:{ String: Capability<&{FungibleToken.Receiver}>}}
	
	// The mappings from the name of an influencer to the cut percentage
	// that they are supposed to receive.
	access(all)
	var cutPercentages:{ String: UFix64}
	
	// The default cut percentage
	access(all)
	var defaultCutPercentage: UFix64
	
	// Get the capability for depositing accounting tokens to the influencer
	access(TMP_ENTITLEMENT_OWNER)
	fun getCapability(name: String, ftType: Type): Capability?{ 
		let ftId = ftType.identifier
		if let caps = self.capabilities[name]{ 
			return caps[ftId]
		} else{ 
			return nil
		}
	}
	
	// Get the current cut percentage for the influencer
	access(TMP_ENTITLEMENT_OWNER)
	fun getCutPercentage(name: String): UFix64{ 
		if let cut = InfluencerRegistry.cutPercentages[name]{ 
			return cut
		} else{ 
			return InfluencerRegistry.defaultCutPercentage
		}
	}
	
	// Admin is an authorization resource that allows the contract owner to 
	// update values in the registry.
	access(all)
	resource Admin{ 
		
		// Update the FT-receiving capability for an influencer
		access(TMP_ENTITLEMENT_OWNER)
		fun setCapability(
			name: String,
			ftType: Type,
			capability: Capability<&{FungibleToken.Receiver}>?
		){ 
			let ftId = ftType.identifier
			if let cap = capability{ 
				if let caps = InfluencerRegistry.capabilities[name]{ 
					caps[ftId] = cap
					InfluencerRegistry.capabilities[name] = caps
				} else{ 
					InfluencerRegistry.capabilities[name] ={ ftId: cap}
				}
				// This is the only way to get the address behind a capability from Cadence right
				// now.  It will panic if the capability is not pointing to anything, but in that
				// case we should in fact panic anyways.
				let addr = ((cap.borrow() ?? panic("Capability is empty")).owner ?? panic("Capability owner is empty")).address
				emit CapabilityUpdated(name: name, ftType: ftType, address: addr)
			} else{ 
				if let caps = InfluencerRegistry.capabilities[name]{ 
					caps.remove(key: ftId)
					InfluencerRegistry.capabilities[name] = caps
				}
				emit CapabilityUpdated(name: name, ftType: ftType, address: nil)
			}
		}
		
		// Update the cut percentage for the influencer
		access(TMP_ENTITLEMENT_OWNER)
		fun setCutPercentage(name: String, cutPercentage: UFix64?){ 
			InfluencerRegistry.cutPercentages[name] = cutPercentage
			emit CutPercentageUpdated(name: name, cutPercentage: cutPercentage)
		}
		
		// Update the default cut percentage
		access(TMP_ENTITLEMENT_OWNER)
		fun setDefaultCutPercentage(cutPercentage: UFix64){ 
			InfluencerRegistry.defaultCutPercentage = cutPercentage
			emit DefaultCutPercentageUpdated(cutPercentage: cutPercentage)
		}
	}
	
	init(){ 
		self.cutPercentages ={} 
		self.capabilities ={} 
		self.defaultCutPercentage = 0.04
		self.account.storage.save<@Admin>(
			<-create Admin(),
			to: /storage/EternalInfluencerRegistryAdmin
		)
	}
}
