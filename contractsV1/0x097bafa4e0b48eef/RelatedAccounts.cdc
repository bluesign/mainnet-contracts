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
contract RelatedAccounts{ 
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let publicPath: PublicPath
	
	// Deprecated
	access(all)
	event RelatedFlowAccountAdded()
	
	access(all)
	event RelatedFlowAccountRemoved()
	
	access(all)
	event RelatedAccountAdded(name: String, address: Address, related: String, network: String)
	
	access(all)
	event RelatedAccountRemoved(name: String, address: Address, related: String, network: String)
	
	access(all)
	struct AccountInformation{ 
		// unique alias for each wallet
		access(all)
		let name: String
		
		access(all)
		let address: Address?
		
		access(all)
		let network: String //do not use enum because of contract upgrade
		
		
		access(all)
		let otherAddress: String? //other networks besides flow may be not support Address
		
		
		init(name: String, address: Address?, network: String, otherAddress: String?){ 
			self.name = name
			self.address = address
			self.network = network
			self.otherAddress = otherAddress
		}
	}
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlowAccounts():{ String: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRelatedAccounts(_ network: String):{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccounts():{ String:{ String: String}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(network: String, address: String): Bool
	}
	
	/// This is just an empty resource we create in storage, you can safely send a reference to it to obtain msg.sender
	access(all)
	resource Accounts: Public{ 
		access(self)
		let accounts:{ String: AccountInformation}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(network: String, address: String): Bool{ 
			for account in self.accounts.keys{ 
				let item = self.accounts[account]!
				let addr = item.address?.toString() ?? item.otherAddress!
				if item.network == network && addr == address{ 
					return true
				}
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlowAccounts():{ String: Address}{ 
			let items:{ String: Address} ={} 
			for account in self.accounts.keys{ 
				let item = self.accounts[account]!
				if item.network == "Flow"{ 
					items[item.name] = item.address!
				}
			}
			return items
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRelatedAccounts(_ network: String):{ String: String}{ 
			let items:{ String: String} ={} 
			for account in self.accounts.keys{ 
				let item = self.accounts[account]!
				if item.network == network{ 
					let address = item.address?.toString() ?? item.otherAddress!
					items[item.name] = address
				}
			}
			return items
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccounts():{ String:{ String: String}}{ 
			let items:{ String:{ String: String}} ={} 
			for account in self.accounts.keys{ 
				let item = self.accounts[account]!
				if item.address != nil{ 
					let i = items[item.network] ??{} 
					i[item.name] = (item.address!).toString()
					items[item.name] = i
					continue
				}
				let i = items[item.network] ??{} 
				i[item.name] = item.otherAddress!
				items[item.name] = i
			}
			return items
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFlowAccount(name: String, address: Address){ 
			self.accounts[name] = AccountInformation(name: name, address: address, network: "Flow", otherAddress: nil)
			emit RelatedAccountAdded(name: name, address: (self.owner!).address, related: address.toString(), network: "Flow")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRelatedAccount(name: String, address: String, network: String){ 
			self.accounts[name] = AccountInformation(name: name, address: nil, network: network, otherAddress: address)
			emit RelatedAccountAdded(name: name, address: (self.owner!).address, related: address, network: network)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteAccount(name: String){ 
			let item = self.accounts.remove(key: name)!
			emit RelatedAccountRemoved(name: name, address: (self.owner!).address, related: item.address?.toString() ?? item.otherAddress!, network: "Flow")
		}
		
		init(){ 
			self.accounts ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyAccounts(): @Accounts{ 
		return <-create Accounts()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun findRelatedFlowAccounts(address: Address):{ String: Address}{ 
		let cap = getAccount(address).capabilities.get<&Accounts>(self.publicPath)
		if !cap.check(){ 
			return{} 
		}
		return (cap.borrow()!).getFlowAccounts()
	}
	
	init(){ 
		self.storagePath = /storage/findAccounts
		self.publicPath = /public/findAccounts
	}
}
