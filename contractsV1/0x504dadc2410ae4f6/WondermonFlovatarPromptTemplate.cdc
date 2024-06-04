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
contract WondermonFlovatarPromptTemplate{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event PromptTemplateSet(flovatarId: UInt64)
	
	access(all)
	event PromptTemplateRemoved(flovatarId: UInt64)
	
	access(all)
	event DefaultPromptTemplateSet()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	let promptTemplates:{ UInt64: String}
	
	access(all)
	var defaultPrompt: String
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setTemplate(flovatarId: UInt64, template: String){ 
			WondermonFlovatarPromptTemplate.promptTemplates.insert(key: flovatarId, template)
			emit PromptTemplateSet(flovatarId: flovatarId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeTemplate(flovatarId: UInt64){ 
			WondermonFlovatarPromptTemplate.promptTemplates.remove(key: flovatarId)
			emit PromptTemplateRemoved(flovatarId: flovatarId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDefaultTemplate(_ template: String){ 
			WondermonFlovatarPromptTemplate.defaultPrompt = template
			emit DefaultPromptTemplateSet()
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPromptTemplate(flovatarId: UInt64): String{ 
		return self.promptTemplates[flovatarId] ?? self.defaultPrompt
	}
	
	init(){ 
		self.promptTemplates ={} 
		self.defaultPrompt = ""
		self.AdminStoragePath = /storage/WondermonFlovatarPromptTemplateAdmin
		self.AdminPublicPath = /public/WondermonFlovatarPromptTemplateAdmin
		self.AdminPrivatePath = /private/WondermonFlovatarPromptTemplateAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
