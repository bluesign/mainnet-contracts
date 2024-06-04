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
contract CryptoysMetadataView{ 
	access(all)
	struct Cryptoy{ 
		access(all)
		let name: String?
		
		access(all)
		let description: String?
		
		access(all)
		let image: String?
		
		access(all)
		let coreImage: String?
		
		access(all)
		let video: String?
		
		access(all)
		let platformId: String?
		
		access(all)
		let category: String?
		
		access(all)
		let type: String?
		
		access(all)
		let skin: String?
		
		access(all)
		let tier: String?
		
		access(all)
		let rarity: String?
		
		access(all)
		let edition: String?
		
		access(all)
		let series: String?
		
		access(all)
		let legionId: String?
		
		access(all)
		let creator: String?
		
		access(all)
		let packaging: String?
		
		access(all)
		let termsUrl: String?
		
		init(
			name: String?,
			description: String?,
			image: String?,
			coreImage: String?,
			video: String?,
			platformId: String?,
			category: String?,
			type: String?,
			skin: String?,
			tier: String?,
			rarity: String?,
			edition: String?,
			series: String?,
			legionId: String?,
			creator: String?,
			packaging: String?,
			termsUrl: String?
		){ 
			self.name = name
			self.description = description
			self.image = image
			self.coreImage = coreImage
			self.video = video
			self.platformId = platformId
			self.category = category
			self.type = type
			self.skin = skin
			self.tier = tier
			self.rarity = rarity
			self.edition = edition
			self.series = series
			self.legionId = legionId
			self.creator = creator
			self.packaging = packaging
			self.termsUrl = termsUrl
		}
	}
}
