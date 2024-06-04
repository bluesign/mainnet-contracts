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
contract AFLBurnRegistry{ 
	access(all)
	let totalBurnsByTemplateId:{ UInt64: UInt64}
	
	access(account)
	fun burn(templateId: UInt64){ 
		if self.totalBurnsByTemplateId[templateId] == nil{ 
			self.totalBurnsByTemplateId[templateId] = 1
		} else{ 
			self.totalBurnsByTemplateId[templateId] = self.totalBurnsByTemplateId[templateId]! + 1
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBurnDetails(templateId: UInt64): UInt64{ 
		return self.totalBurnsByTemplateId[templateId] ?? 0
	}
	
	init(){ 
		self.totalBurnsByTemplateId ={} 
	}
}
