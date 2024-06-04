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

	// SPDX-License-Identifier: MIT
access(all)
contract GenesisBoxRegistry{ 
	
	//mapping of genesis box id to Data
	access(contract)
	let registryRemote:{ UInt64: Data}
	
	access(all)
	struct Data{ 
		
		//the receiver address on flow
		access(all)
		let receiver: Address
		
		//the doodleId of the asset beeing teleported
		access(all)
		let genesisBoxId: UInt64
		
		//the remote address on ETH
		access(all)
		let remoteAddress: String
		
		//context like ethTx or other info to add to event
		access(all)
		let context:{ String: String}
		
		//the wearable template ids that will be minted and sent
		access(all)
		let wearableTemplateIds: [UInt64]
		
		init(
			receiver: Address,
			genesisBoxId: UInt64,
			remoteAddress: String,
			wearableTemplateIds: [
				UInt64
			],
			context:{ 
				String: String
			},
			teleporterId: UInt64
		){ 
			self.receiver = receiver
			self.genesisBoxId = genesisBoxId
			self.remoteAddress = remoteAddress
			self.context = context
			self.wearableTemplateIds = wearableTemplateIds
		}
	}
	
	access(all)
	struct AllowedStatus{ 
		access(all)
		let allowed: Bool
		
		access(all)
		let message: String
		
		init(_ id: UInt64){ 
			var allowed = true
			var message = "Genesis Box ID : ".concat(id.toString()).concat(" can be opened.")
			if let data = GenesisBoxRegistry.registryRemote[id]{ 
				allowed = false
				message = "Genesis Box ID : ".concat(data.genesisBoxId.toString()).concat(" has already been opened by ").concat((data!).receiver.toString())
			}
			self.allowed = allowed
			self.message = message
		}
	}
	
	access(account)
	fun setData(_ data: Data){ 
		pre{ 
			!self.registryRemote.containsKey(data.genesisBoxId):
				"Genesis Box ID : ".concat(data.genesisBoxId.toString()).concat(" has already been opened.")
		}
		self.registryRemote[data.genesisBoxId] = data
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getGenesisBoxStatus(_ id: UInt64): Data?{ 
		return self.registryRemote[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isValid(_ id: UInt64): Bool{ 
		return self.registryRemote.containsKey(id)
	}
	
	init(){ 
		self.registryRemote ={} 
	}
}
