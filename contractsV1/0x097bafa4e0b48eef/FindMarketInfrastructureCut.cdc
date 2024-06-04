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

	import FindMarketCutInterface from "./FindMarketCutInterface.cdc"

import FindMarketCutStruct from "./FindMarketCutStruct.cdc"

import FindMarketCut from "./FindMarketCut.cdc"

access(all)
contract FindMarketInfrastructureCut: FindMarketCutInterface{ 
	access(all)
	let contractName: String
	
	access(all)
	let category: String
	
	// tenant to {ruleId to cut}
	access(contract)
	let cuts:{ String:{ String: FindMarketCutStruct.Cuts}}
	
	access(contract)
	let cutsCache:{ String:{ String: FindMarketCutStruct.Cuts}}
	
	access(all)
	event Cut(tenant: String, type: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCut(tenant: String, listingType: Type, nftType: Type, ftType: Type): FindMarketCutStruct.Cuts?{ 
		let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
		if let cache = self.getTenantRulesCache(tenant: tenant, ruleId: ruleId){ 
			return cache
		}
		let types = [listingType.identifier, nftType.identifier, ftType.identifier]
		var cuts: [{FindMarketCutStruct.Cut}] = []
		var returningCut: FindMarketCutStruct.Cuts? = nil
		for t in types{ 
			let cutMapping = self.cuts[tenant] ??{} 
			if let c = cutMapping[t]{ 
				cuts.appendAll(c.cuts)
			}
		}
		if cuts.length > 0{ 
			returningCut = FindMarketCutStruct.Cuts(cuts: cuts)
			
			// set cache if not already
			// we do not need to check if cache exist here, because if it is, it will be returned earlier
			self.setTenantRulesCache(tenant: tenant, ruleId: ruleId, result: returningCut!)
		}
		return returningCut
	}
	
	access(account)
	fun setTenantCuts(tenant: String, types: [Type], cuts: FindMarketCutStruct.Cuts){ 
		let old = self.cuts[tenant] ??{} 
		for t in types{ 
			old[t.identifier] = cuts
			emit Cut(tenant: tenant, type: t.identifier, cutInfo: cuts.getEventSafeCuts(), action: "add", remark: nil)
		}
		self.cuts[tenant] = old
	}
	
	access(account)
	fun removeTenantCuts(tenant: String, types: [Type]): [FindMarketCutStruct.Cuts]{ 
		var panicMsg = "tenant infrastructure cut is not registered. Tenant : ".concat(tenant)
		let old = self.cuts[tenant] ?? panic(panicMsg)
		let cutsReturn: [FindMarketCutStruct.Cuts] = []
		for t in types{ 
			let detailedPanicMsg = panicMsg.concat(" Type : ".concat(t.identifier))
			let cuts = old.remove(key: t.identifier) ?? panic(detailedPanicMsg)
			cutsReturn.append(cuts)
			emit Cut(tenant: tenant, type: t.identifier, cutInfo: cuts.getEventSafeCuts(), action: "remove", remark: nil)
		}
		self.cuts[tenant] = old
		return cutsReturn
	}
	
	access(account)
	fun setTenantRulesCache(tenant: String, ruleId: String, result: FindMarketCutStruct.Cuts){ 
		let old = self.cutsCache[tenant] ??{} 
		if old[ruleId] != nil{ 
			panic("There is already a cache for this find rule. RuleId : ".concat(ruleId))
		}
		old[ruleId] = result
		self.cutsCache[tenant] = old
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTenantRulesCache(tenant: String, ruleId: String): FindMarketCutStruct.Cuts?{ 
		if self.cutsCache[tenant] == nil{ 
			return nil
		}
		return (self.cutsCache[tenant]!)[ruleId]
	}
	
	access(account)
	fun resetTenantRulesCache(_ tenant: String){ 
		self.cutsCache.remove(key: tenant)
	}
	
	init(){ 
		self.cuts ={} 
		self.cutsCache ={} 
		self.contractName = "FindMarketInfrastructureCut"
		self.category = "infrastructure"
		FindMarketCut.setCategory(category: self.category, contractName: self.contractName)
	}
}
