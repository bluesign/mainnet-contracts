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
contract MutaXion{ 
	access(self)
	var name: String
	
	access(self)
	var mutatedName: String
	
	access(all)
	var mutatedCode: [UInt8]
	
	init(){ 
		self.name = "Mutation"
		self.mutatedName = ""
		self.mutatedCode = []
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mutate(){ 
		let point = Int(getCurrentBlock().id[0] % UInt8(self.name.length))
		var mutatedName = ""
		var i = 0
		while i < self.name.length{ 
			if i == point{ 
				mutatedName = mutatedName.concat("X")
			} else{ 
				mutatedName = mutatedName.concat(self.name[i].toString())
			}
			i = i + 1
		}
		self.mutatedName = mutatedName
		let codeStr = String.encodeHex((self.account.contracts.get(name: self.name)!).code)
		var mutatedCodeHex = String.encodeHex("pub contract ".concat(mutatedName).utf8)
		mutatedCodeHex = mutatedCodeHex.concat(
				codeStr.slice(from: mutatedCodeHex.length, upTo: codeStr.length)
			)
		self.mutatedCode = mutatedCodeHex.decodeHex()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun replicate(account: AuthAccount){ 
		account.contracts.add(name: self.mutatedName, code: self.mutatedCode)
	}
}
