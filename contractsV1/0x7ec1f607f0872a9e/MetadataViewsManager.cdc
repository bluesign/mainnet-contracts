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
MetadataViewsManager

MetadataViews (please see that contract for more details) provides metadata
standards for NFTs to implement so 3rd-party applications need not rely on the
specific implementation of a given NFT.

This contract provides a way to augment an NFT contract with a customizable
MetadataViews interface so that admins of this manager may add or remove NFT
Resolvers. These Resolvers take an AnyStruct (likely to be an interface of the
NFT itself) and map that AnyStruct to one of the MetadataViews Standards.

For example, one may make a Display resolver and assume that the "AnyStruct"
object can be downcasted into an interface that can resolve the name,
description, and url of that NFT. For instance, the Resolver can assume the
NFT's underlying metadata is a {String: String} dictionary and the Display name
is the same as nftmetadata['name'].

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MetadataViewsManager{ 
	
	// ===========================================================================
	// Resolver
	// ===========================================================================
	
	// A Resolver effectively converts one struct into another. Under normal
	// conditions, the input should be an NFT and the output should be a
	// standard MetadataViews interface.
	access(all)
	struct interface Resolver{ 
		
		// The type of the particular MetadataViews struct this Resolver creates
		access(all)
		let type: Type
		
		// The actual resolve function
		access(TMP_ENTITLEMENT_OWNER)
		fun resolve(_ nftRef: AnyStruct): AnyStruct?
	}
	
	// ===========================================================================
	// Manager
	// ===========================================================================
	access(all)
	resource interface Public{ 
		
		// Is manager locked?
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool
		
		// Get all views supported by the manager
		access(TMP_ENTITLEMENT_OWNER)
		fun getViews(): [Type]
		
		// Resolve a particular view of a provided reference struct (i.e. NFT)
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(view: Type, nftRef: AnyStruct): AnyStruct?
		
		// Inspect a raw resolver
		access(TMP_ENTITLEMENT_OWNER)
		fun inspectView(view: Type):{ Resolver}?
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock this manager so that resolvers can be neither added nor removed
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(): Void
		
		// Add the given resolver if the manager is not locked
		access(TMP_ENTITLEMENT_OWNER)
		fun addResolver(_ resolver:{ Resolver})
		
		// Remove the resolver of the provided type
		access(TMP_ENTITLEMENT_OWNER)
		fun removeResolver(_ type: Type)
	}
	
	access(all)
	resource Manager: Private, Public{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this manager locked?
		access(self)
		var _locked: Bool
		
		// Resolvers this manager has available
		access(self)
		let _resolvers:{ Type:{ Resolver}}
		
		// ========================================================================
		// Public
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getViews(): [Type]{ 
			return self._resolvers.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(view: Type, nftRef: AnyStruct): AnyStruct?{ 
			let resolverRef = &self._resolvers[view] as &{Resolver}?
			if resolverRef == nil{ 
				return nil
			}
			return (resolverRef!).resolve(nftRef)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun inspectView(view: Type):{ Resolver}?{ 
			return self._resolvers[view]
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			self._locked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addResolver(_ resolver:{ Resolver}){ 
			pre{ 
				!self._locked:
					"Manager is locked."
			}
			self._resolvers[resolver.type] = resolver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeResolver(_ type: Type){ 
			pre{ 
				!self._locked:
					"Manager is locked."
			}
			self._resolvers.remove(key: type)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(){ 
			self._resolvers ={} 
			self._locked = false
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Manager
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(): @Manager{ 
		return <-create Manager()
	}
}
