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
MutableMetadata

This contract serves as a container for metadata that can be modified after it
has been created. Any underyling struct can be used as the metadata, and any
observer should be able to inpsect the metadata. A common strategy would be to
use a {String: String} map as the metadata.

Administrators with access to this resource's private capabilities will be
allowed to modify the metadata as they wish until they decide to lock it. After
it has been locked, observers can rest asssured knowing the metadata for a
particular item (most likely an NFT) can no longer be modified.

*/

access(all)
contract MutableMetadata{ 
	
	// =========================================================================
	// Metadata
	// =========================================================================
	access(all)
	resource interface Public{ 
		
		// Is this metadata locked for modification?
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool
		
		// Get a copy of the underlying metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun get(): AnyStruct
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock this metadata, preventing further modification.
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(): Void
		
		// Retrieve a modifiable version of the underlying metadata, only if the
		// metadata has not been locked.
		access(TMP_ENTITLEMENT_OWNER)
		fun getMutable(): &AnyStruct
		
		// Replace the metadata entirely with a new underlying metadata AnyStruct,
		// only if the metadata has not been locked.
		access(TMP_ENTITLEMENT_OWNER)
		fun replace(_ new: AnyStruct)
	}
	
	access(all)
	resource Metadata: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this metadata locked for modification?
		access(self)
		var _locked: Bool
		
		// The actual underlying metadata
		access(self)
		var _metadata: AnyStruct
		
		// ========================================================================
		// Public
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun get(): AnyStruct{ 
			// It's important that a copy is returned and not a reference.
			return self._metadata
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			self._locked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMutable(): &AnyStruct{ 
			pre{ 
				!self._locked:
					"Metadata is locked"
			}
			return &self._metadata as &AnyStruct
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun replace(_ new: AnyStruct){ 
			pre{ 
				!self._locked:
					"Metadata is locked"
			}
			self._metadata = new
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(metadata: AnyStruct){ 
			self._locked = false
			self._metadata = metadata
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Metadata resource with the given generic AnyStruct metadata
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(metadata: AnyStruct): @Metadata{ 
		return <-create Metadata(metadata: metadata)
	}
}
