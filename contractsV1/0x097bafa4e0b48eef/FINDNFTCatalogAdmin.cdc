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

	import FINDNFTCatalog from "./FINDNFTCatalog.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

// NFTCatalogAdmin
//
// An admin contract that defines an	admin resource and
// a proxy resource to receive a capability that lets you make changes to the NFT Catalog
// and manage proposals
access(all)
contract FINDNFTCatalogAdmin{ 
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	// Admin
	// Admin resource to manage NFT Catalog
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCatalogEntry(collectionIdentifier: String, metadata: NFTCatalog.NFTCatalogMetadata){ 
			FINDNFTCatalog.addCatalogEntry(
				collectionIdentifier: collectionIdentifier,
				metadata: metadata
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateCatalogEntry(
			collectionIdentifier: String,
			metadata: NFTCatalog.NFTCatalogMetadata
		){ 
			FINDNFTCatalog.updateCatalogEntry(
				collectionIdentifier: collectionIdentifier,
				metadata: metadata
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeCatalogEntry(collectionIdentifier: String){ 
			FINDNFTCatalog.removeCatalogEntry(collectionIdentifier: collectionIdentifier)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun approveCatalogProposal(proposalID: UInt64){ 
			pre{ 
				FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID) != nil:
					"Invalid Proposal ID"
				(FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID)!).status == "IN_REVIEW":
					"Invalid Proposal"
			}
			let catalogProposalEntry =
				FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID)!
			let newCatalogProposalEntry =
				NFTCatalog.NFTCatalogProposal(
					collectionIdentifier: catalogProposalEntry.collectionIdentifier,
					metadata: catalogProposalEntry.metadata,
					message: catalogProposalEntry.message,
					status: "APPROVED",
					proposer: catalogProposalEntry.proposer
				)
			FINDNFTCatalog.updateCatalogProposal(
				proposalID: proposalID,
				proposalMetadata: newCatalogProposalEntry
			)
			if FINDNFTCatalog.getCatalogEntry(
				collectionIdentifier: (
					FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID)!
				).collectionIdentifier
			)
			== nil{ 
				FINDNFTCatalog.addCatalogEntry(
					collectionIdentifier: newCatalogProposalEntry.collectionIdentifier,
					metadata: newCatalogProposalEntry.metadata
				)
			} else{ 
				FINDNFTCatalog.updateCatalogEntry(collectionIdentifier: newCatalogProposalEntry.collectionIdentifier, metadata: newCatalogProposalEntry.metadata)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rejectCatalogProposal(proposalID: UInt64){ 
			pre{ 
				FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID) != nil:
					"Invalid Proposal ID"
				(FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID)!).status == "IN_REVIEW":
					"Invalid Proposal"
			}
			let catalogProposalEntry =
				FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID)!
			let newCatalogProposalEntry =
				NFTCatalog.NFTCatalogProposal(
					collectionIdentifier: catalogProposalEntry.collectionIdentifier,
					metadata: catalogProposalEntry.metadata,
					message: catalogProposalEntry.message,
					status: "REJECTED",
					proposer: catalogProposalEntry.proposer
				)
			FINDNFTCatalog.updateCatalogProposal(
				proposalID: proposalID,
				proposalMetadata: newCatalogProposalEntry
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeCatalogProposal(proposalID: UInt64){ 
			pre{ 
				FINDNFTCatalog.getCatalogProposalEntry(proposalID: proposalID) != nil:
					"Invalid Proposal ID"
			}
			FINDNFTCatalog.removeCatalogProposal(proposalID: proposalID)
		}
		
		init(){} 
	}
	
	// AdminProxy
	// A proxy resource that can store
	// a capability to admin controls
	access(all)
	resource interface IAdminProxy{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(capability: Capability<&FINDNFTCatalogAdmin.Admin>): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasCapability(): Bool
	}
	
	access(all)
	resource AdminProxy: IAdminProxy{ 
		access(self)
		var capability: Capability<&Admin>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(capability: Capability<&Admin>){ 
			pre{ 
				capability.check():
					"Invalid Admin Capability"
				self.capability == nil:
					"Admin Proxy already set"
			}
			self.capability = capability
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCapability(): Capability<&Admin>?{ 
			return self.capability
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasCapability(): Bool{ 
			return self.capability != nil
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxy(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/FINDnftCatalogAdminProxy
		self.AdminProxyStoragePath = /storage/FINDnftCatalogAdminProxy
		self.AdminPrivatePath = /private/FINDnftCatalogAdmin
		self.AdminStoragePath = /storage/FINDnftCatalogAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
}
