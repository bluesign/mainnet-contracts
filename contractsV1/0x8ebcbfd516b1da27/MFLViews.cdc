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

import MFLPackTemplate from "./MFLPackTemplate.cdc"

/**
  This contract defines MFL customised views. They are used to represent NFTs data.
  This allows us to take full advantage of the new metadata standard.
**/

access(all)
contract MFLViews{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	struct PackDataViewV1{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packTemplate: MFLPackTemplate.PackTemplateData
		
		init(id: UInt64, packTemplate: MFLPackTemplate.PackTemplateData){ 
			self.id = id
			self.packTemplate = packTemplate
		}
	}
	
	access(all)
	struct PlayerMetadataViewV1{ 
		access(all)
		let name: String?
		
		access(contract)
		let nationalities: [String]?
		
		access(contract)
		let positions: [String]?
		
		access(all)
		let preferredFoot: String?
		
		access(all)
		let ageAtMint: UInt32?
		
		access(all)
		let height: UInt32?
		
		access(all)
		let overall: UInt32?
		
		access(all)
		let pace: UInt32?
		
		access(all)
		let shooting: UInt32?
		
		access(all)
		let passing: UInt32?
		
		access(all)
		let dribbling: UInt32?
		
		access(all)
		let defense: UInt32?
		
		access(all)
		let physical: UInt32?
		
		access(all)
		let goalkeeping: UInt32?
		
		access(all)
		let potential: String?
		
		access(all)
		let resistance: UInt32?
		
		init(metadata:{ String: AnyStruct}){ 
			self.name = metadata["name"] as! String?
			self.nationalities = metadata["nationalities"] as! [String]?
			self.positions = metadata["positions"] as! [String]?
			self.preferredFoot = metadata["preferredFoot"] as! String?
			self.ageAtMint = metadata["ageAtMint"] as! UInt32?
			self.height = metadata["height"] as! UInt32?
			self.overall = metadata["overall"] as! UInt32?
			self.pace = metadata["pace"] as! UInt32?
			self.shooting = metadata["shooting"] as! UInt32?
			self.passing = metadata["passing"] as! UInt32?
			self.dribbling = metadata["dribbling"] as! UInt32?
			self.defense = metadata["defense"] as! UInt32?
			self.physical = metadata["physical"] as! UInt32?
			self.goalkeeping = metadata["goalkeeping"] as! UInt32?
			self.potential = metadata["potential"] as! String?
			self.resistance = metadata["resistance"] as! UInt32?
		}
	}
	
	access(all)
	struct PlayerDataViewV1{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: PlayerMetadataViewV1
		
		access(all)
		let season: UInt32
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		init(
			id: UInt64,
			metadata:{ 
				String: AnyStruct
			},
			season: UInt32,
			thumbnail:{ MetadataViews.File}
		){ 
			self.id = id
			self.metadata = PlayerMetadataViewV1(metadata: metadata)
			self.season = season
			self.thumbnail = thumbnail
		}
	}
	
	init(){ 
		emit ContractInitialized()
	}
}
