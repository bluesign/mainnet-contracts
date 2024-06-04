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
contract ListedTokens{ 
	/****** Events ******/
	access(all)
	event TokenAdded(
		key: String,
		name: String,
		displayName: String,
		symbol: String,
		address: Address
	)
	
	access(all)
	event TokenUpdated(
		key: String,
		name: String,
		displayName: String,
		symbol: String,
		address: Address
	)
	
	access(all)
	event TokenRemoved(key: String)
	
	/****** Contract Variables ******/
	access(contract)
	var _tokens:{ String: TokenInfo}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/****** Composite Type Definitions ******/
	access(all)
	struct TokenInfo{ 
		access(all)
		let name: String
		
		access(all)
		let displayName: String
		
		access(all)
		let symbol: String
		
		access(all)
		let address: Address
		
		access(all)
		let vaultPath: String
		
		access(all)
		let receiverPath: String
		
		access(all)
		let balancePath: String
		
		init(
			name: String,
			displayName: String,
			symbol: String,
			address: Address,
			vaultPath: String,
			receiverPath: String,
			balancePath: String
		){ 
			self.name = name
			self.displayName = displayName
			self.symbol = symbol
			self.address = address
			self.vaultPath = vaultPath
			self.receiverPath = receiverPath
			self.balancePath = balancePath
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addToken(
			name: String,
			displayName: String,
			symbol: String,
			address: Address,
			vaultPath: String,
			receiverPath: String,
			balancePath: String
		){ 
			var key = name.concat(".").concat(address.toString())
			if ListedTokens.tokenExists(key: key){ 
				return
			}
			ListedTokens._tokens[key] = TokenInfo(
					name: name,
					displayName: displayName,
					symbol: symbol,
					address: address,
					vaultPath: vaultPath,
					receiverPath: receiverPath,
					balancePath: balancePath
				)
			emit TokenAdded(
				key: key,
				name: name,
				displayName: displayName,
				symbol: symbol,
				address: address
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateToken(
			name: String,
			displayName: String,
			symbol: String,
			address: Address,
			vaultPath: String,
			receiverPath: String,
			balancePath: String
		){ 
			var key = name.concat(".").concat(address.toString())
			ListedTokens._tokens[key] = TokenInfo(
					name: name,
					displayName: displayName,
					symbol: symbol,
					address: address,
					vaultPath: vaultPath,
					receiverPath: receiverPath,
					balancePath: balancePath
				)
			emit TokenUpdated(
				key: key,
				name: name,
				displayName: displayName,
				symbol: symbol,
				address: address
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeToken(key: String){ 
			ListedTokens._tokens.remove(key: key)
			emit TokenRemoved(key: key)
		}
	}
	
	/****** Methods ******/
	access(TMP_ENTITLEMENT_OWNER)
	fun tokenExists(key: String): Bool{ 
		return self._tokens.containsKey(key)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTokens(): [TokenInfo]{ 
		return self._tokens.values
	}
	
	init(){ 
		self._tokens ={} 
		self.AdminStoragePath = /storage/bloctoSwapListedTokensAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
