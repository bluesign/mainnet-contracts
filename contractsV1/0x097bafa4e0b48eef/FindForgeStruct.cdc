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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FindForgeStruct{ 
	access(all)
	event ContractInitialized()
	
	// for all traits in info :
	/* 
			We stores needed data in maps, if max / scores are also needed, we create key-value pairs : key_max / key_score for storing that 
			if descriptions are added, we put that in description with prefix of the map variable, e.g. : scalar_key
		*/
	
	access(all)
	struct FindDIM{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let externalURL: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let descriptions:{ String: String}
		
		// stores number traits, max can be added
		access(all)
		let scalars:{ String: UFix64}
		
		// stores boost traits, max can be added
		access(all)
		let boosts:{ String: UFix64}
		
		// stores boost percentage traits
		access(all)
		let boostPercents:{ String: UFix64}
		
		// stores level traits, max can be stored
		access(all)
		let levels:{ String: UFix64}
		
		// stores string traits
		access(all)
		let traits:{ String: String}
		
		// stores date traits
		access(all)
		let dates:{ String: UFix64}
		
		access(all)
		let medias:{ String: String}
		
		access(all)
		let extras:{ String: AnyStruct}
		
		init(
			name: String,
			description: String,
			thumbnailHash: String,
			edition: UInt64,
			maxEdition: UInt64,
			externalURL: String,
			descriptions:{ 
				String: String
			},
			scalars:{ 
				String: UFix64
			},
			boosts:{ 
				String: UFix64
			},
			boostPercents:{ 
				String: UFix64
			},
			levels:{ 
				String: UFix64
			},
			traits:{ 
				String: String
			},
			dates:{ 
				String: UFix64
			},
			medias:{ 
				String: String
			}
		){ 
			self.name = name
			self.description = description
			self.thumbnailHash = thumbnailHash
			self.edition = edition
			self.maxEdition = maxEdition
			self.traits = traits
			self.levels = levels
			self.scalars = scalars
			self.dates = dates
			self.externalURL = externalURL
			self.medias = medias
			self.descriptions = descriptions
			self.boosts = boosts
			self.boostPercents = boostPercents
			self.extras ={} 
		}
	}
	
	init(){ 
		emit ContractInitialized()
	}
}
