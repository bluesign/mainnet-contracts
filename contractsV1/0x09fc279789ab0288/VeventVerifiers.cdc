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

	import Vevent from "./Vevent.cdc"

import Wearables from "../0xe81193c424cfd3fb/Wearables.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract VeventVerifiers{ 
	access(all)
	struct DoodlesSock: Vevent.Verifier{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(user: Address): Bool{ 
			if let collection = getAccount(user).capabilities.get<&Wearables.Collection>(Wearables.CollectionPublicPath).borrow<&Wearables.Collection>(){ 
				for id in collection.getIDs(){ 
					let resolver = collection.borrowViewResolver(id: id)!
					let view = resolver.resolveView(Type<Wearables.Metadata>())! as! Wearables.Metadata
					let template = Wearables.templates[view.templateId]!
					let name = template.name
					if name == "crew socks"{ 
						return true
					}
				}
			}
			return false
		}
	}
}
