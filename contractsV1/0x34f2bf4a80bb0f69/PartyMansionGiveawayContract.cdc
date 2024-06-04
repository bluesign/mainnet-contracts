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

	/**
*  SPDX-License-Identifier: GPL-3.0-only
*/


// PartyMansionGiveawayContract
//													  
access(all)
contract PartyMansionGiveawayContract{ 
	
	// Giveaways
	access(self)
	var giveaways:{ String: String}
	
	// Admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		// offerFreeDrinks
		access(TMP_ENTITLEMENT_OWNER)
		fun addGiveawayCode(giveawayKey: String){ 
			if PartyMansionGiveawayContract.giveaways.containsKey(giveawayKey){ 
				panic("Giveaway code already known.")
			}
			PartyMansionGiveawayContract.giveaways.insert(key: giveawayKey, giveawayKey)
		}
	}
	
	// checkGiveawayCode
	access(TMP_ENTITLEMENT_OWNER)
	fun checkGiveawayCode(giveawayCode: String): Bool{ 
		// Hash giveawayCode
		let digest = HashAlgorithm.SHA3_256.hash(giveawayCode.decodeHex())
		let giveawayKey = String.encodeHex(digest)
		if !PartyMansionGiveawayContract.giveaways.containsKey(giveawayKey){ 
			return false
		}
		return true
	}
	
	// removeGiveawayCode
	access(TMP_ENTITLEMENT_OWNER)
	fun removeGiveawayCode(giveawayCode: String){ 
		// Hash giveawayCode
		let digest = HashAlgorithm.SHA3_256.hash(giveawayCode.decodeHex())
		let giveawayKey = String.encodeHex(digest)
		if !PartyMansionGiveawayContract.giveaways.containsKey(giveawayKey){ 
			let msg = "Unknown Giveaway Code:"
			panic(msg.concat(giveawayKey))
		}
		PartyMansionGiveawayContract.giveaways.remove(key: giveawayKey)
	}
	
	// Init function of the smart contract
	init(){ 
		// init & save Admin
		self.AdminStoragePath = /storage/PartyMansionGiveawayAdmin
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		
		// Initialize Giveawaxys
		self.giveaways ={} 
	}
}
