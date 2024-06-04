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

	import FlowToken from "./../../standardsV1/FlowToken.cdc"

import DynamicImport from "./DynamicImport.cdc"

access(all)
contract Proxy_0x1654653399040a61{ 
	access(all)
	resource ContractObject: DynamicImport.ImportInterface{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun dynamicImport(name: String): &AnyStruct?{ 
			if name == "FlowToken"{ 
				return &FlowToken as &AnyStruct
			}
			return nil
		}
	}
	
	init(){ 
		self.account.storage.save(<-create ContractObject(), to: /storage/A0x1654653399040a61)
	}
}
