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

	/* SPDX-License-Identifier: UNLICENSED */
import DimeCollectibleV4 from "../0xf5cdaace879e5a79/DimeCollectibleV4.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DimeRoyaltiesV2{ 
	// Events
	access(all)
	event ReleaseCreated(releaseId: UInt64)
	
	access(all)
	event RoyaltyNFTAdded(itemId: UInt64)
	
	// Named Paths
	access(all)
	let ReleasesStoragePath: StoragePath
	
	access(all)
	let ReleasesPrivatePath: PrivatePath
	
	access(all)
	let ReleasesPublicPath: PublicPath
	
	access(self)
	var nextReleaseId: UInt64
	
	access(all)
	struct SaleShares{ 
		access(self)
		let allotments:{ Address: UFix64}
		
		init(allotments:{ Address: UFix64}){ 
			var total = 0.0
			for allotment in allotments.values{ 
				assert(allotment > 0.0, message: "Each recipient must receive an allotment > 0")
				total = total + allotment
			}
			assert(total == 1.0, message: "Total sale shares must equal exactly 1")
			self.allotments = allotments
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getShares():{ Address: UFix64}{ 
			return self.allotments
		}
	}
	
	access(all)
	resource interface ReleasePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let royaltiesPerShare: UFix64
		
		access(all)
		let numRoyaltyNFTs: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyOwners():{ UInt64: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOwner(id: UInt64, newOwner: Address)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]
		
		access(all)
		let managerFees: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getArtistShares(): SaleShares
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getManagerShares(): SaleShares
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSecondarySaleRoyalties(): MetadataViews.Royalties
	}
	
	access(all)
	resource Release: ReleasePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let royaltiesPerShare: UFix64
		
		access(all)
		let numRoyaltyNFTs: UInt64
		
		// Map from each royalty NFT ID to the current owner.
		// When a royalty NFT is purchased, the corresponding address is updated.
		// When a release NFT is purchased, this list is used to pay the owners of
		// the royalty NFTs
		access(self)
		let royaltyNFTs:{ UInt64: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyIds(): [UInt64]{ 
			return self.royaltyNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyOwners():{ UInt64: Address}{ 
			return self.royaltyNFTs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addRoyaltyNFT(id: UInt64){ 
			assert(UInt64(self.royaltyNFTs.keys.length) < self.numRoyaltyNFTs, message: "This release already has the maximum number of royalty NFTs")
			self.royaltyNFTs[id] = (self.owner!).address
			emit RoyaltyNFTAdded(itemId: id)
		}
		
		// Called whenever a royalty NFT is purchased.
		// Since this is publicly accessible, anyone call call it. We verify
		// that the address given currently owns the specified NFT to make sure that
		// only the actual owner can change the listing
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOwner(id: UInt64, newOwner: Address){ 
			let collection = getAccount(newOwner).capabilities.get<&DimeCollectibleV4.Collection>(DimeCollectibleV4.CollectionPublicPath).borrow() ?? panic("Couldn't borrow a capability to the new owner's collection")
			let nft = collection.borrowCollectible(id: id)
			assert(nft != nil, message: "That user doesn't own that NFT")
			
			// We've verified that the provided address does currently own the
			// royalty NFT, so we update the royalty map to reflect this
			self.royaltyNFTs[id] = newOwner
		}
		
		// A list of the associated release NFTs
		access(self)
		let releaseNFTs: [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]{ 
			return self.releaseNFTs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addReleaseNFT(id: UInt64){ 
			self.releaseNFTs.append(id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeReleaseNFT(id: UInt64){ 
			self.releaseNFTs.remove(at: id)
		}
		
		// How the proceeds from sales of this release will be divided
		access(all)
		let managerFees: UFix64
		
		access(self)
		var artistShares: SaleShares
		
		access(self)
		var managerShares: SaleShares
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getArtistShares(): SaleShares{ 
			return self.artistShares
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getManagerShares(): SaleShares{ 
			return self.managerShares
		}
		
		access(all)
		let secondarySaleRoyalties: MetadataViews.Royalties
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSecondarySaleRoyalties(): MetadataViews.Royalties{ 
			return self.secondarySaleRoyalties
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		init(id: UInt64, royaltiesPerShare: UFix64, numRoyaltyNFTs: UInt64, managerFees: UFix64, artistShares: SaleShares, managerShares: SaleShares, secondarySaleRoyalties: MetadataViews.Royalties){ 
			self.id = id
			self.royaltiesPerShare = royaltiesPerShare
			self.numRoyaltyNFTs = numRoyaltyNFTs
			self.royaltyNFTs ={} 
			self.releaseNFTs = []
			assert(managerFees >= 0.1 && managerFees <= 0.9, message: "Manager cut must be between 0.1 and 0.9")
			self.managerFees = managerFees
			self.artistShares = artistShares
			self.managerShares = managerShares
			self.secondarySaleRoyalties = secondarySaleRoyalties
		}
	}
	
	access(all)
	resource interface ReleaseCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicRelease(id: UInt64): &Release?
	}
	
	access(all)
	resource ReleaseCollection: ReleaseCollectionPublic{ 
		access(all)
		let releases: @{UInt64: Release}
		
		init(){ 
			self.releases <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]{ 
			return self.releases.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicRelease(id: UInt64): &Release?{ 
			if self.releases[id] == nil{ 
				return nil
			}
			return &self.releases[id] as &Release?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPrivateRelease(id: UInt64): &Release?{ 
			if self.releases[id] == nil{ 
				return nil
			}
			return &self.releases[id] as &Release?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createRelease(collection: &DimeCollectibleV4.Collection, totalRoyalties: UFix64, numRoyaltyNFTs: UInt64, tradeable: Bool, managerFees: UFix64, artistShares: SaleShares, managerShares: SaleShares, secondarySaleRoyalties: MetadataViews.Royalties){ 
			let minterAddress: Address = 0x056a9cc93a020fad // 0x056a9cc93a020fad for testnet. 0xf5cdaace879e5a79 for mainnet
			
			let minterRef = getAccount(minterAddress).capabilities.get<&DimeCollectibleV4.NFTMinter>(DimeCollectibleV4.MinterPublicPath).borrow()!
			let release <- create Release(id: DimeRoyaltiesV2.nextReleaseId, royaltiesPerShare: totalRoyalties / UFix64(numRoyaltyNFTs), numRoyaltyNFTs: numRoyaltyNFTs, managerFees: managerFees, artistShares: artistShares, managerShares: managerShares, secondarySaleRoyalties: secondarySaleRoyalties)
			let existing <- self.releases[DimeRoyaltiesV2.nextReleaseId] <- release
			// This should always be null, but we need to handle this explicitly
			destroy existing
			emit ReleaseCreated(releaseId: DimeRoyaltiesV2.nextReleaseId)
			DimeRoyaltiesV2.nextReleaseId = DimeRoyaltiesV2.nextReleaseId + 1 as UInt64
		}
		
		// A release can only be deleted if the creator still owns all the associated royalty
		// and release NFTs. In this case, we delete all of them and then destroy the Release.
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteRelease(releaseId: UInt64, collection: Capability<&DimeCollectibleV4.Collection>){ 
			let release <- self.releases.remove(key: releaseId)!
			let collectionRef = collection.borrow() ?? panic("Couldn't borrow provided collection")
			let collectionIds = collectionRef.getIDs()
			for id in release.getRoyaltyIds().concat(release.getReleaseIds()){ 
				assert(collectionIds.contains(id), message: "Cannot destroy release because another user owns an associated NFT")
			}
			
			// The creator still owns all the related tokens, so we proceed by burning them
			for id in release.getRoyaltyIds().concat(release.getReleaseIds()){ 
				let nft <- collectionRef.withdraw(withdrawID: id)
				destroy nft
			}
			destroy release
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createReleaseCollection(): @ReleaseCollection{ 
		return <-create ReleaseCollection()
	}
	
	init(){ 
		self.ReleasesStoragePath = /storage/DimeReleasesV2
		self.ReleasesPrivatePath = /private/DimeReleasesV2
		self.ReleasesPublicPath = /public/DimeReleasesV2
		self.nextReleaseId = 0
	}
}
