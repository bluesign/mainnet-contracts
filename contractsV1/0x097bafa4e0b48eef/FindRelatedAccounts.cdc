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
contract FindRelatedAccounts{ 
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let publicPath: PublicPath
	
	access(all)
	event RelatedAccount(
		user: Address,
		walletId: String,
		walletName: String,
		address: String,
		network: String,
		action: String
	)
	
	access(all)
	struct AccountInformation{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address?
		
		access(all)
		let network: String //do not use enum because of contract upgrade
		
		
		access(all)
		let stringAddress: String //other networks besides flow may be not support Address, duplication of flow address in string
		
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(name: String, address: Address?, network: String, otherAddress: String?){ 
			pre{ 
				address == nil && otherAddress != nil || address != nil && otherAddress == nil:
					"Please put either flow address or other address for account"
			}
			self.name = name
			self.address = address
			self.network = network
			self.stringAddress = otherAddress ?? (address!).toString()
			self.extra ={} 
		}
	}
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlowAccounts():{ String: [Address]}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRelatedAccounts(_ network: String):{ String: [String]}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccounts():{ String:{ String: [String]}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccountInfo():{ String: AccountInformation}
		
		// verify ensure this wallet address exist under the network
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(network: String, address: String): Bool
		
		// linked ensure this wallet is linked in both wallet with the same name (but not socially linked only)
		// only supports flow for now
		access(TMP_ENTITLEMENT_OWNER)
		fun linked(name: String, network: String, address: Address): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccount(name: String, network: String, address: String): AccountInformation?
	}
	
	/// This is just an empty resource we create in storage, you can safely send a reference to it to obtain msg.sender
	access(all)
	resource Accounts: Public{ 
		
		// { ETH : ETH_Blocto }
		access(self)
		let networks:{ String: [String]}
		
		// { ETH_Blocto : [Address] }
		access(self)
		let wallets:{ String: [String]}
		
		// { ETH_Blocto_Address : AccountInformation }
		access(self)
		let accounts:{ String: AccountInformation}
		
		init(){ 
			self.networks ={} 
			self.wallets ={} 
			self.accounts ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun linked(name: String, network: String, address: Address): Bool{ 
			let cap = FindRelatedAccounts.getCapability(address)
			if cap.check(){ 
				if let acct = (cap.borrow()!).getAccount(name: name, network: network, address: (self.owner!).address.toString()){ 
					return true
				}
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(network: String, address: String): Bool{ 
			if let wallets = self.networks[network]{ 
				for wallet in wallets{ 
					let ws = self.wallets[wallet]!
					for candiidate in ws{ 
						if candiidate.toLower() == address.toLower(){ 
							return true
						}
					}
				}
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlowAccounts():{ String: [Address]}{ 
			let network = "Flow"
			let tempItems:{ String: [Address]} ={} 
			if let wallets = self.networks[network]{ 
				for wallet in wallets{ 
					let ws = self.wallets[wallet]!
					for addr in ws{ 
						let id = wallet.concat("_").concat(addr)
						let info = self.accounts[id]!
						let tempArray = tempItems[wallet] ?? []
						tempArray.append(info.address!)
						tempItems[wallet] = tempArray
					}
				}
			}
			return tempItems
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRelatedAccounts(_ network: String):{ String: [String]}{ 
			return self.internal_getRelatedAccounts(network)[network] ??{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccounts():{ String:{ String: [String]}}{ 
			return self.internal_getRelatedAccounts(nil)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllRelatedAccountInfo():{ String: AccountInformation}{ 
			return self.accounts
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccount(name: String, network: String, address: String): AccountInformation?{ 
			let id = FindRelatedAccounts.getIdentifier(name: name, network: network, address: address)
			return self.accounts[id]
		}
		
		access(contract)
		fun internal_getRelatedAccounts(_ network: String?):{ String:{ String: [String]}}{ 
			var isNil = network == nil
			fun wanted(_ n: String): Bool{ 
				if network! == n{ 
					return true
				}
				return false
			}
			var tempRes:{ String:{ String: [String]}} ={} 
			for n in self.networks.keys{ 
				if !isNil && !wanted(n){ 
					continue
				}
				let tempItems:{ String: [String]} = tempRes[n] ??{} 
				if let wallets = self.networks[n]{ 
					for wallet in wallets{ 
						let ws = self.wallets[wallet]!
						let tempArray = tempItems[wallet] ?? []
						tempArray.appendAll(ws)
						tempItems[wallet] = tempArray
					}
				}
				tempRes[n] = tempItems
			}
			return tempRes
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFlowAccount(name: String, address: Address){ 
			let network = "Flow"
			let id = FindRelatedAccounts.getIdentifier(name: name, network: network, address: address.toString())
			if self.accounts[id] != nil{ 
				return
			}
			self.internal_add(id: id, acct: AccountInformation(name: name, address: address, network: network, otherAddress: nil))
			emit RelatedAccount(user: (self.owner!).address, walletId: id, walletName: name, address: address.toString(), network: network, action: "add")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addRelatedAccount(name: String, network: String, address: String){ 
			let id = FindRelatedAccounts.getIdentifier(name: name, network: network, address: address)
			if self.accounts[id] != nil{ 
				return
			}
			self.internal_add(id: id, acct: AccountInformation(name: name, address: nil, network: network, otherAddress: address))
			emit RelatedAccount(user: (self.owner!).address, walletId: id, walletName: name, address: address, network: network, action: "add")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateFlowAccount(name: String, oldAddress: Address, address: Address){ 
			self.removeRelatedAccount(name: name, network: "Flow", address: oldAddress.toString())
			self.addFlowAccount(name: name, address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateRelatedAccount(name: String, network: String, oldAddress: String, address: String){ 
			self.removeRelatedAccount(name: name, network: network, address: oldAddress)
			self.addRelatedAccount(name: name, network: network, address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRelatedAccount(name: String, network: String, address: String){ 
			let id = FindRelatedAccounts.getIdentifier(name: name, network: network, address: address)
			if self.accounts[id] == nil{ 
				panic(network.concat(" address is not added as related account : ").concat(address))
			}
			self.internal_remove(id: id)
			emit RelatedAccount(user: (self.owner!).address, walletId: id, walletName: name, address: address, network: network, action: "remove")
		}
		
		access(contract)
		fun internal_add(id: String, acct: AccountInformation){ 
			let walletName = acct.network.concat("_").concat(acct.name)
			let tempNetworks = self.networks[acct.network] ?? []
			if !tempNetworks.contains(walletName){ 
				tempNetworks.append(walletName)
				self.networks[acct.network] = tempNetworks
			}
			let tempWallets = self.wallets[walletName] ?? []
			tempWallets.append(acct.stringAddress)
			self.wallets[walletName] = tempWallets
			self.accounts[id] = acct
		}
		
		access(contract)
		fun internal_remove(id: String){ 
			let acct = self.accounts.remove(key: id)!
			let walletName = acct.network.concat("_").concat(acct.name)
			let tempWallets = self.wallets[walletName]!
			tempWallets.remove(at: tempWallets.firstIndex(of: acct.stringAddress)!)
			if tempWallets.length > 0{ 
				self.wallets[walletName] = tempWallets
				return
			}
			self.wallets.remove(key: walletName)
			let tempNetwork = self.networks[acct.network]!
			tempNetwork.remove(at: tempNetwork.firstIndex(of: walletName)!)
			if tempNetwork.length > 0{ 
				self.networks[acct.network] = tempNetwork
				return
			}
			self.networks.remove(key: acct.network)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyAccounts(): @Accounts{ 
		return <-create Accounts()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getIdentifier(name: String, network: String, address: String): String{ 
		return network.concat("_").concat(name).concat("_").concat(address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCapability(_ addr: Address): Capability<&Accounts>{ 
		return getAccount(addr).capabilities.get<&Accounts>(self.publicPath)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun findRelatedFlowAccounts(address: Address):{ String: [Address]}{ 
		let cap = self.getCapability(address)
		if !cap.check(){ 
			return{} 
		}
		return (cap.borrow()!).getFlowAccounts()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun findRelatedAccounts(address: Address):{ String:{ String: [String]}}{ 
		let cap = self.getCapability(address)
		if !cap.check(){ 
			return{} 
		}
		return (cap.borrow()!).getAllRelatedAccounts()
	}
	
	init(){ 
		self.storagePath = /storage/findRelatedAccounts
		self.publicPath = /public/findRelatedAccounts
	}
}
