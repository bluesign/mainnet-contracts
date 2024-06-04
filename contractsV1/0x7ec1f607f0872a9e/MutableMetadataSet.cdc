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
MutableSet

We want to be able to associate metadata with a group of related resources.
Those resources themselves may have their own metadata represented by
MutableMetadataTemplate.Template (please see that contract for more details).
However, imagine a use case like an NFT brand manager wanting to release a
season of NFTs. The attributes of the 'season' would apply to all of the NFTs.

MutableSet.Set allows for multiple Templates to be associated with a single
Set-wide MutableMetadata.Metadata.

A Set owner can also signal to observers that no more resources will be added
to a particular logical Set of NFTs by locking the Set.

*/

import MutableMetadata from "./MutableMetadata.cdc"

import MutableMetadataTemplate from "./MutableMetadataTemplate.cdc"

access(all)
contract MutableMetadataSet{ 
	
	// ===========================================================================
	// Set
	// ===========================================================================
	access(all)
	resource interface Public{ 
		
		// Is this set locked from more Templates being added?
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool
		
		// Number of Templates in this set
		access(TMP_ENTITLEMENT_OWNER)
		fun numTemplates(): Int
		
		// Public version of underyling MutableMetadata.Metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): &MutableMetadata.Metadata
		
		// Retrieve the public version of a particular template given by the
		// Template ID (index into the self._templates array) only if it exists
		access(TMP_ENTITLEMENT_OWNER)
		fun getTemplate(_ id: Int): &MutableMetadataTemplate.Template
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock this set so more Templates may not be added to it.
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(): Void
		
		// Private version of underyling MutableMetadata.Metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun metadataMutable(): &MutableMetadata.Metadata
		
		// Retrieve the private version of a particular template given by the
		// Template ID (index into the self._templates array) only if it exists
		access(TMP_ENTITLEMENT_OWNER)
		fun getTemplateMutable(_ id: Int): &MutableMetadataTemplate.Template
		
		// Add a Template to this set if not locked
		access(TMP_ENTITLEMENT_OWNER)
		fun addTemplate(_ template: @MutableMetadataTemplate.Template)
	}
	
	access(all)
	resource Set: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this set locked from more Templates being added?
		access(self)
		var _locked: Bool
		
		// Public version of underyling MutableMetadata.Metadata
		access(self)
		var _metadata: @MutableMetadata.Metadata
		
		// Templates in this set
		access(self)
		var _templates: @[MutableMetadataTemplate.Template]
		
		// ========================================================================
		// Public
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun numTemplates(): Int{ 
			return self._templates.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTemplate(_ id: Int): &MutableMetadataTemplate.Template{ 
			pre{ 
				id >= 0 && id < self._templates.length:
					id.toString().concat(" is not a valid template ID. Number of templates is ").concat(self._templates.length.toString())
			}
			return &self._templates[id] as &MutableMetadataTemplate.Template
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			self._locked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadataMutable(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTemplateMutable(_ id: Int): &MutableMetadataTemplate.Template{ 
			pre{ 
				id >= 0 && id < self._templates.length:
					id.toString().concat(" is not a valid template ID. Number of templates is ").concat(self._templates.length.toString())
			}
			return &self._templates[id] as &MutableMetadataTemplate.Template
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addTemplate(_ template: @MutableMetadataTemplate.Template){ 
			pre{ 
				!self._locked:
					"Cannot add template. Set is locked"
			}
			let id = self._templates.length
			self._templates.append(<-template)
			emit TemplateAdded(id: id)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(metadata: @MutableMetadata.Metadata){ 
			self._locked = false
			self._metadata <- metadata
			self._templates <- []
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Set resource with the given Metadata
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(metadata: @MutableMetadata.Metadata): @Set{ 
		return <-create Set(metadata: <-metadata)
	}
	
	// ==========================================================================
	// Ignore
	// ==========================================================================
	// Not used - exists to conform to contract updatability requirements
	access(all)
	event TemplateAdded(id: Int)
}
