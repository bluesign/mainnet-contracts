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

	import AFLPack from "../0x8f9231920da9af6d/AFLPack.cdc"

access(all)
contract ProxyAdmin{ 
	access(all)
	resource interface MinterProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCapability(cap: Capability<&AFLPack.Pack>): Void
	}
	
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		access(self)
		var minterCapability: Capability<&AFLPack.Pack>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCapability(cap: Capability<&AFLPack.Pack>){ 
			self.minterCapability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOwner(owner: Address){ 
			((self.minterCapability!).borrow()!).updateOwnerAddress(owner: owner)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	init(){ 
		self.account.storage.save(<-create MinterProxy(), to: /storage/proxy)
		var capability_1 = self.account.capabilities.storage.issue<&MinterProxy>(/storage/proxy)
		self.account.capabilities.publish(capability_1, at: /public/proxy)
	}
}
