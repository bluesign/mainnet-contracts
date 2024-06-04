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

	import FindMarketCutStruct from "./FindMarketCutStruct.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface FindMarketCutInterface{ 
	access(all)
	let contractName: String
	
	access(all)
	let category: String
	
	access(all)
	event Cut(
		tenant: String,
		type: String,
		cutInfo: [
			FindMarketCutStruct.EventSafeCut
		],
		action: String,
		remark: String?
	)
	
	access(account)
	fun setTenantCuts(tenant: String, types: [Type], cuts: FindMarketCutStruct.Cuts)
	
	access(account)
	fun removeTenantCuts(tenant: String, types: [Type]): [FindMarketCutStruct.Cuts]
	
	access(account)
	fun setTenantRulesCache(tenant: String, ruleId: String, result: FindMarketCutStruct.Cuts)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTenantRulesCache(tenant: String, ruleId: String): FindMarketCutStruct.Cuts?
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCut(
		tenant: String,
		listingType: Type,
		nftType: Type,
		ftType: Type
	): FindMarketCutStruct.Cuts?
	
	access(account)
	fun resetTenantRulesCache(_ tenant: String)
}
