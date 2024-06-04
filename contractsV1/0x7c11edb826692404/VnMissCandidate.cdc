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
contract VnMissCandidate{ 
	access(self)
	let listCandidate:{ UInt64: Candidate}
	
	access(self)
	let top40:{ UInt64: Bool}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MaxCandidate: Int
	
	access(all)
	event NewCandidate(id: UInt64, name: String, fundAddress: Address)
	
	access(all)
	event CandidateUpdate(id: UInt64, name: String, fundAddress: Address)
	
	access(all)
	struct Candidate{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let code: String
		
		access(all)
		let description: String
		
		access(all)
		let fundAdress: Address
		
		access(all)
		let properties:{ String: String}
		
		init(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			self.id = id
			self.name = name
			self.code = code
			self.description = description
			self.fundAdress = fundAddress
			self.properties = properties
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buildName(level: String, id: UInt64): String{ 
			return self.name.concat(" ").concat(self.code).concat(" - ").concat(level).concat("#")
				.concat(id.toString())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun inTop40(): Bool{ 
			return VnMissCandidate.top40[self.id] ?? false
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createCandidate(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			pre{ 
				VnMissCandidate.listCandidate.length < VnMissCandidate.MaxCandidate:
					"Exceed maximum"
			}
			VnMissCandidate.listCandidate[id] = Candidate(
					id: id,
					name: name,
					code: code,
					description: description,
					fundAddress: fundAddress,
					properties: properties
				)
			emit NewCandidate(id: id, name: name, fundAddress: fundAddress)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markTop40(ids: [UInt64], isTop40: Bool){ 
			for id in ids{ 
				VnMissCandidate.top40[id] = isTop40
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateCandidate(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			pre{ 
				VnMissCandidate.listCandidate.containsKey(id):
					"Candidate not exist"
			}
			VnMissCandidate.listCandidate[id] = Candidate(
					id: id,
					name: name,
					code: code,
					description: description,
					fundAddress: fundAddress,
					properties: properties
				)
			emit CandidateUpdate(id: id, name: name, fundAddress: fundAddress)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCandidate(id: UInt64): Candidate?{ 
		return self.listCandidate[id]
	}
	
	init(){ 
		self.listCandidate ={} 
		self.AdminStoragePath = /storage/BNVNMissCandidateAdmin
		self.MaxCandidate = 71
		self.top40 ={} 
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
