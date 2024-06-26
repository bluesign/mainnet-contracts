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

	// SPDX-License-Identifier: MIT

// This contracts contains Metadata structs for Everbloom
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract EverbloomMetadata{ 
	access(all)
	struct Perk{ 
		access(all)
		let perkID: UInt32
		
		access(all)
		let type: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let url: String?
		
		access(all)
		let isValid: Bool?
		
		init(
			perkID: UInt32,
			type: String,
			title: String,
			description: String,
			url: String?,
			isValid: Bool?
		){ 
			self.perkID = perkID
			self.type = type
			self.title = title
			self.description = description
			self.url = url
			self.isValid = isValid
		}
	}
	
	access(all)
	struct PerkData{ 
		access(all)
		let type: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let url: String?
		
		init(type: String, title: String, description: String, url: String?){ 
			self.type = type
			self.title = title
			self.description = description
			self.url = url
		}
	}
	
	access(all)
	struct PerksView{ 
		access(self)
		let perks: [Perk]
		
		access(TMP_ENTITLEMENT_OWNER)
		init(_ perks: [Perk]){ 
			self.perks = perks
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPerks(): [Perk]{ 
			return self.perks
		}
	}
	
	access(all)
	struct EverbloomMetadataView{ 
		access(all)
		let name: String?
		
		access(all)
		let description: String?
		
		access(all)
		let image: MetadataViews.HTTPFile?
		
		access(all)
		let thumbnail: MetadataViews.HTTPFile?
		
		access(all)
		let video: MetadataViews.HTTPFile?
		
		access(all)
		let signature: MetadataViews.HTTPFile?
		
		access(all)
		let previewUrl: String?
		
		access(all)
		let creatorName: String?
		
		access(all)
		let creatorUrl: String?
		
		access(all)
		let creatorDescription: String?
		
		access(all)
		let creatorAddress: String?
		
		access(all)
		let externalPostId: String
		
		access(all)
		let externalPrintId: String
		
		access(all)
		let rarity: String?
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let totalPrintMinted: UInt32?
		
		init(
			name: String?,
			description: String?,
			image: MetadataViews.HTTPFile?,
			thumbnail: MetadataViews.HTTPFile?,
			video: MetadataViews.HTTPFile?,
			signature: MetadataViews.HTTPFile?,
			previewUrl: String?,
			creatorName: String?,
			creatorUrl: String?,
			creatorDescription: String?,
			creatorAddress: String?,
			externalPostId: String,
			externalPrintId: String,
			rarity: String?,
			serialNumber: UInt32,
			totalPrintMinted: UInt32?
		){ 
			self.name = name
			self.description = description
			self.image = image
			self.thumbnail = thumbnail
			self.video = video
			self.signature = signature
			self.previewUrl = previewUrl
			self.creatorName = creatorName
			self.creatorUrl = creatorUrl
			self.creatorDescription = creatorDescription
			self.creatorAddress = creatorAddress
			self.externalPostId = externalPostId
			self.externalPrintId = externalPrintId
			self.rarity = rarity
			self.serialNumber = serialNumber
			self.totalPrintMinted = totalPrintMinted
		}
	}
}
