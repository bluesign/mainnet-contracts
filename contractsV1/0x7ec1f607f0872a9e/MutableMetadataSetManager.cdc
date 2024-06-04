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

	/*
MutableSetManager

MutableSet.Set (please see that contract for more details) provides a way to
create Sets of alike resources with some shared properties. This contract
provides management and access to a logical collection of these Sets. For
example, this contract would be best used to manage the metadata for an entire
NFT contract.

A SetManager should have a name and description and provides a way to add
additional Sets and access those Sets for mutation, if allowed by the Set.

*/

import MutableMetadataSet from "./MutableMetadataSet.cdc"

access(all)
contract MutableMetadataSetManager{ 
	
	// ==========================================================================
	// Manager
	// ==========================================================================
	access(all)
	resource interface Public{ 
		
		// Name of this manager
		access(TMP_ENTITLEMENT_OWNER)
		fun name(): String
		
		// Description of this manager
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String
		
		// Number of sets in this manager
		access(TMP_ENTITLEMENT_OWNER)
		fun numSets(): Int
		
		// Get the public version of a particular set
		access(TMP_ENTITLEMENT_OWNER)
		fun getSet(_ id: Int): &MutableMetadataSet.Set
	}
	
	access(all)
	resource interface Private{ 
		
		// Set the name of the manager
		access(TMP_ENTITLEMENT_OWNER)
		fun setName(_ name: String): Void
		
		// Set the name of the description
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ description: String)
		
		// Get the private version of a particular set
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetMutable(_ id: Int): &MutableMetadataSet.Set
		
		// Add a mutable set to the set manager.
		access(TMP_ENTITLEMENT_OWNER)
		fun addSet(_ set: @MutableMetadataSet.Set)
	}
	
	access(all)
	resource Manager: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Name of this manager
		access(self)
		var _name: String
		
		// Description of this manager
		access(self)
		var _description: String
		
		// Sets owned by this manager
		access(self)
		var _mutableSets: @[MutableMetadataSet.Set]
		
		// ========================================================================
		// Public functions
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun name(): String{ 
			return self._name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String{ 
			return self._description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun numSets(): Int{ 
			return self._mutableSets.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSet(_ id: Int): &MutableMetadataSet.Set{ 
			pre{ 
				id >= 0 && id < self._mutableSets.length:
					id.toString().concat(" is not a valid set ID. Number of sets is ").concat(self._mutableSets.length.toString())
			}
			return &self._mutableSets[id] as &MutableMetadataSet.Set
		}
		
		// ========================================================================
		// Private functions
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun setName(_ name: String){ 
			self._name = name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ description: String){ 
			self._description = description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetMutable(_ id: Int): &MutableMetadataSet.Set{ 
			pre{ 
				id >= 0 && id < self._mutableSets.length:
					id.toString().concat(" is not a valid set ID. Number of sets is ").concat(self._mutableSets.length.toString())
			}
			return &self._mutableSets[id] as &MutableMetadataSet.Set
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSet(_ set: @MutableMetadataSet.Set){ 
			let id = self._mutableSets.length
			self._mutableSets.append(<-set)
			emit SetAdded(id: id)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(name: String, description: String){ 
			self._name = name
			self._description = description
			self._mutableSets <- []
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new SetManager resource with the given name and description
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(name: String, description: String): @Manager{ 
		return <-create Manager(name: name, description: description)
	}
	
	// ==========================================================================
	// Ignore
	// ==========================================================================
	// Not used - exists to conform to contract updatability requirements
	access(all)
	event SetAdded(id: Int)
}
