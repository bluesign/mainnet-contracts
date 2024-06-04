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

// TOKEN RUNNERS: Contract responsable for Default view
access(all)
contract StoreFrontViews{ 
	
	// Display is a basic view that includes the name, description,
	// thumbnail for an object and metadata as flexible field. Most objects should implement this view.
	//
	access(all)
	struct StoreFrontDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let metadata:{ String: String}
		
		init(
			name: String,
			description: String,
			thumbnail:{ MetadataViews.File},
			metadata:{ 
				String: String
			}
		){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
	}
}
