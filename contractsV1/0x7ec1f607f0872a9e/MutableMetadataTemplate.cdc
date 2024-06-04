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
MutableMetadataTemplate

We want to be able to:

- associate multiple objects (resources or structs) with the same metadata. For
example, we might have a pack of serialized NFTs which all represent the same
metadata, but each with a different serial number.

- assure collectors that more resources of the same metadata cannot be produced,
guaranteeing scarcity

- allow "minting" of a declared resource without allowing other authorized
functionality.

MutableMetadataTemplate provides these abilities. Creators may associate
a MutableMetadata.Metadata (please see that contract for more details) with a
Template in order to specify an optional "maxMint" field to associate with
a Template. Once maxMint for a Template has been reached, then no more
resources with the same metadata may be created.

This was primarily created to control mints for NonFungibleTokens, but this
should work generically with any resource. That being said, this contract does
not actually do minting of new NFTs. Whenever an NFT is minted, registerMint
must be called alongside and will fail if minting should not be allowed.

*/

import MutableMetadata from "./MutableMetadata.cdc"

access(all)
contract MutableMetadataTemplate{ 
	
	// ===========================================================================
	// Template
	// ===========================================================================
	access(all)
	resource interface Public{ 
		
		// Is this template locked for future minting?
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool
		
		// Max mint allowed for this metadata. Can be set to nil for unlimited
		access(TMP_ENTITLEMENT_OWNER)
		fun maxMint(): UInt64?
		
		// Public version of underyling MutableMetadata.Metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): &MutableMetadata.Metadata
		
		// Number of times registerMint has been called on this template
		access(TMP_ENTITLEMENT_OWNER)
		fun minted(): UInt64
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock the metadata from any additional future minting.
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(): Void
		
		// Set the maximum mint of this template if not already set and if not
		// locked
		access(TMP_ENTITLEMENT_OWNER)
		fun setMaxMint(_ max: UInt64)
		
		// Private version of underyling MutableMetadata.Metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun metadataMutable(): &MutableMetadata.Metadata
		
		// Register a new mint.
		access(TMP_ENTITLEMENT_OWNER)
		fun registerMint()
	}
	
	access(all)
	resource Template: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this template locked for future minting?
		access(self)
		var _locked: Bool
		
		// Max mint allowed for this metadata. Can be set to nil for unlimited
		access(self)
		var _maxMint: UInt64?
		
		// A MutableMetadata instance is used to store the underyling metadata
		access(self)
		let _metadata: @MutableMetadata.Metadata
		
		// Number of times registerMint has been called on this template
		access(self)
		var _minted: UInt64
		
		// ========================================================================
		// Public
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun maxMint(): UInt64?{ 
			return self._maxMint
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun minted(): UInt64{ 
			return self._minted
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			self._locked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMaxMint(_ max: UInt64){ 
			pre{ 
				self._maxMint == nil:
					"Max mint already set to ".concat((self._maxMint!).toString())
				max < self._minted:
					"Proposed max mint of ".concat(max.toString()).concat(" must be less than currently minted: ").concat(self._minted.toString())
				!self._locked:
					"Template is locked"
			}
			self._maxMint = max
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadataMutable(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerMint(){ 
			pre{ 
				self._maxMint == nil || self._minted < self._maxMint!:
					"Minting limit of ".concat((self._maxMint!).toString()).concat(" reached.")
				!self._locked:
					"Template is locked"
			}
			self._minted = self._minted + 1
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(metadata: @MutableMetadata.Metadata, maxMint: UInt64?){ 
			self._locked = false
			self._metadata <- metadata
			self._maxMint = maxMint
			self._minted = 0
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a Template resource with the given metadata and maxMint
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(metadata: @MutableMetadata.Metadata, maxMint: UInt64?): @Template{ 
		return <-create Template(metadata: <-metadata, maxMint: maxMint)
	}
}
