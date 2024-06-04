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
contract ListedPairs{ 
	/****** Events ******/
	access(all)
	event PairAdded(key: String, name: String, token0: String, token1: String, address: Address)
	
	access(all)
	event PairUpdated(key: String)
	
	access(all)
	event PairRemoved(key: String)
	
	/****** Contract Variables ******/
	access(contract)
	var _pairs:{ String: PairInfo}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/****** Composite Type Definitions ******/
	access(all)
	struct PairInfo{ 
		access(all)
		let name: String
		
		access(all)
		let token0: String
		
		access(all)
		let token1: String
		
		access(all)
		let address: Address
		
		access(all)
		var liquidityToken: String?
		
		init(
			name: String,
			token0: String,
			token1: String,
			address: Address,
			liquidityToken: String?
		){ 
			self.name = name
			self.token0 = token0
			self.token1 = token1
			self.address = address
			self.liquidityToken = liquidityToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun update(liquidityToken: String?){ 
			self.liquidityToken = liquidityToken ?? self.liquidityToken
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addPair(
			name: String,
			token0: String,
			token1: String,
			address: Address,
			liquidityToken: String?
		){ 
			var key = name.concat(".").concat(address.toString())
			if ListedPairs.pairExists(key: key){ 
				return
			}
			ListedPairs._pairs[key] = PairInfo(
					name: name,
					token0: token0,
					token1: token1,
					address: address,
					liquidityToken: liquidityToken
				)
			emit PairAdded(key: key, name: name, token0: token0, token1: token1, address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePair(name: String, address: Address, liquidityToken: String?){ 
			var key = name.concat(".").concat(address.toString())
			(ListedPairs._pairs[key]!).update(liquidityToken: liquidityToken)
			emit PairUpdated(key: key)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removePair(key: String){ 
			ListedPairs._pairs.remove(key: key)
			emit PairRemoved(key: key)
		}
	}
	
	/****** Methods ******/
	access(TMP_ENTITLEMENT_OWNER)
	fun pairExists(key: String): Bool{ 
		return self._pairs.containsKey(key)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPairs(): [PairInfo]{ 
		return self._pairs.values
	}
	
	init(){ 
		self._pairs ={} 
		self.AdminStoragePath = /storage/bloctoSwapListedPairsAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
