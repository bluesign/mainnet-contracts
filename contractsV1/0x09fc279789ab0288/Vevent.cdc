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

	import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Vevent{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	struct interface Verifier{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(user: Address): Bool
	}
	
	access(all)
	resource interface ProjectPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let buyers:{ Address: UInt64}
		
		access(all)
		let prices:{ UFix64: UInt64}
		
		access(all)
		var active: Bool
		
		access(account)
		fun purchase(user: Address, vault: @DapperUtilityCoin.Vault)
	}
	
	access(all)
	resource Project: ProjectPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let buyers:{ Address: UInt64}
		
		// maps the price to the amount of squares you get
		access(all)
		let prices:{ UFix64: UInt64}
		
		access(all)
		var active: Bool
		
		access(all)
		let verifier: [{Verifier}]
		
		access(account)
		fun purchase(user: Address, vault: @DapperUtilityCoin.Vault){ 
			pre{ 
				self.prices[vault.balance] != nil:
					"This price is not supported."
			}
			self.buyers[user] = (self.buyers[user] ?? 0) + self.prices[vault.balance]!
			let owner: Address = 0x14b41acafe20d346
			let ownerVault = getAccount(owner).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("This is not a Dapper Wallet account.")
			ownerVault.deposit(from: <-vault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleActive(){ 
			self.active = !self.active
		}
		
		init(prices:{ UFix64: UInt64}, verifier: [{Verifier}]){ 
			self.id = self.uuid
			self.buyers ={} 
			self.prices = prices
			self.active = true
			self.verifier = verifier
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectPublic(projectId: UInt64): &Project?
	}
	
	access(all)
	resource Collection: CollectionPublic{ 
		access(all)
		let projects: @{UInt64: Project}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createProject(prices:{ UFix64: UInt64}, verifier: [{Verifier}]){ 
			let project <- create Project(prices: prices, verifier: verifier)
			self.projects[project.id] <-! project
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(projectOwner: Address, projectId: UInt64, payment: @DapperUtilityCoin.Vault){ 
			let collection: &Collection = getAccount(projectOwner).capabilities.get<&Collection>(Vevent.CollectionPublicPath).borrow<&Collection>() ?? panic("This project owner does not have a collection set up or linked properly.")
			let project: &Project = collection.getProjectPublic(projectId: projectId) ?? panic("Project with this id does not exist.")
			project.purchase(user: (self.owner!).address, vault: <-payment)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectIds(): [UInt64]{ 
			return self.projects.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProject(projectId: UInt64): &Project?{ 
			return &self.projects[projectId] as &Project?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectPublic(projectId: UInt64): &Project?{ 
			return &self.projects[projectId] as &Project?
		}
		
		init(){ 
			self.projects <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/VeventCollection
		self.CollectionPublicPath = /public/VeventCollection
	}
}
