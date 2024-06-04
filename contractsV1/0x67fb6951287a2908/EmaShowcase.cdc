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

	import MessageCard from "../0xf38fadaba79009cc/MessageCard.cdc"

access(all)
contract EmaShowcase{ 
	access(all)
	struct Ema{ 
		access(all)
		let id: UInt64
		
		access(all)
		let owner: Address
		
		init(id: UInt64, owner: Address){ 
			self.id = id
			self.owner = owner
		}
	}
	
	access(account)
	var emas: [Ema]
	
	access(account)
	var exists:{ UInt64: Bool}
	
	access(account)
	var max: Int
	
	access(account)
	var paused: Bool
	
	access(account)
	var allowedTemplateIds:{ UInt64: Bool}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMax(max: Int){ 
			EmaShowcase.max = max
			while EmaShowcase.emas.length > EmaShowcase.max{ 
				let lastEma = EmaShowcase.emas.removeLast()
				EmaShowcase.exists.remove(key: lastEma.id)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePaused(paused: Bool){ 
			EmaShowcase.paused = paused
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAllowedTemplateId(templateId: UInt64){ 
			EmaShowcase.allowedTemplateIds[templateId] = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAllowedTemplateId(templateId: UInt64){ 
			EmaShowcase.allowedTemplateIds.remove(key: templateId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun clearEmas(){ 
			EmaShowcase.emas = []
			EmaShowcase.exists ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun addEma(id: UInt64, collectionCapability: Capability<&MessageCard.Collection>){ 
		pre{ 
			!EmaShowcase.paused:
				"Paused"
			!EmaShowcase.exists.containsKey(id):
				"Already Existing"
			collectionCapability.borrow()?.borrowMessageCard(id: id) != nil:
				"Not Found"
			EmaShowcase.allowedTemplateIds.containsKey(((collectionCapability.borrow()!).borrowMessageCard(id: id)!).templateId):
				"Not Allowed Template"
		}
		EmaShowcase.emas.insert(at: 0, Ema(id: id, owner: collectionCapability.address))
		EmaShowcase.exists[id] = true
		if EmaShowcase.emas.length > EmaShowcase.max{ 
			let lastEma = EmaShowcase.emas.removeLast()
			EmaShowcase.exists.remove(key: lastEma.id)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getEmas(from: Int, upTo: Int): [Ema]{ 
		if from >= EmaShowcase.emas.length{ 
			return []
		}
		if upTo >= EmaShowcase.emas.length{ 
			return EmaShowcase.emas.slice(from: from, upTo: EmaShowcase.emas.length - 1)
		}
		return EmaShowcase.emas.slice(from: from, upTo: upTo)
	}
	
	init(){ 
		self.emas = []
		self.exists ={} 
		self.max = 1000
		self.paused = false
		self.allowedTemplateIds ={} 
		self.account.storage.save(<-create Admin(), to: /storage/EmaShowcaseAdmin)
	}
}
