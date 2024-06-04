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
contract AFLMetadataHelper{ 
	access(contract)
	let metadataByTemplateId:{ UInt64:{ String: String}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadataForTemplate(id: UInt64):{ String: String}{ 
		if self.metadataByTemplateId[id] == nil{ 
			return{} 
		}
		return self.metadataByTemplateId[id]!
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadataForTemplate(id: UInt64, metadata:{ String: String}){ 
			if AFLMetadataHelper.metadataByTemplateId[id] == nil{ 
				AFLMetadataHelper.metadataByTemplateId[id] ={} 
			}
			AFLMetadataHelper.metadataByTemplateId[id] = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addMetadataToTemplate(id: UInt64, key: String, value: String){ 
			if AFLMetadataHelper.metadataByTemplateId[id] == nil{ 
				AFLMetadataHelper.metadataByTemplateId[id] ={} 
			}
			let templateRef =
				&AFLMetadataHelper.metadataByTemplateId[id]! as auth(Mutate) &{String: String}
			templateRef[key] = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMetadataFromTemplate(id: UInt64, key: String){ 
			let templateRef =
				&AFLMetadataHelper.metadataByTemplateId[id]! as auth(Mutate) &{String: String}
			templateRef[key] = nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAllExtendedMetadataFromTemplate(id: UInt64){ 
			AFLMetadataHelper.metadataByTemplateId[id] ={} 
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/AFLMetadataHelperAdmin
		self.metadataByTemplateId ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
