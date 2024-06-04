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

	import GomokuType from "./GomokuType.cdc"

access(all)
contract GomokuResult{ 
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Events
	access(all)
	event TokenCreated(winner: Address?, losser: Address?, gain: Fix64)
	
	access(all)
	event CollectionCreated()
	
	access(all)
	event Withdraw(id: UInt32, from: Address?)
	
	access(all)
	event Deposit(id: UInt32, to: Address?)
	
	init(){ 
		self.CollectionStoragePath = /storage/gomokuResultCollection
		self.CollectionPublicPath = /public/gomokuResultCollection
	}
	
	access(all)
	resource ResultToken{ 
		access(all)
		let id: UInt32
		
		access(all)
		let winner: Address?
		
		access(all)
		let losser: Address?
		
		access(all)
		let isDraw: Bool
		
		access(all)
		let roundWinners: [GomokuType.Result]
		
		access(all)
		let gain: Fix64
		
		access(account)
		let steps: [[{GomokuType.StoneDataing}]]
		
		access(self)
		var destroyable: Bool
		
		init(
			id: UInt32,
			winner: Address?,
			losser: Address?,
			gain: Fix64,
			roundWinners: [
				GomokuType.Result
			],
			steps: [
				[{
					GomokuType.StoneDataing}
				]
			]
		){ 
			self.id = id
			self.winner = winner
			self.losser = losser
			if winner == nil && losser == nil{ 
				self.isDraw = true
			} else{ 
				self.isDraw = false
			}
			self.gain = gain
			self.roundWinners = roundWinners
			self.destroyable = false
			self.steps = steps
			emit TokenCreated(winner: winner, losser: losser, gain: gain)
		}
		
		access(account)
		fun setDestroyable(_ value: Bool){ 
			self.destroyable = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSteps(round: UInt32): [{GomokuType.StoneDataing}]{ 
			pre{ 
				round < UInt32(self.steps.length):
					"Invalid round index."
			}
			return self.steps[round]
		}
	}
	
	access(account)
	fun createResult(
		id: UInt32,
		winner: Address?,
		losser: Address?,
		gain: Fix64,
		roundWinners: [
			GomokuType.Result
		],
		steps: [
			[{
				GomokuType.StoneDataing}
			]
		]
	): @GomokuResult.ResultToken{ 
		return <-create ResultToken(
			id: id,
			winner: winner,
			losser: losser,
			gain: gain,
			roundWinners: roundWinners,
			steps: steps
		)
	}
	
	access(all)
	resource ResultCollection{ 
		access(all)
		let StoragePath: StoragePath
		
		access(all)
		let PublicPath: PublicPath
		
		access(self)
		var ownedResultTokenMap: @{UInt32: GomokuResult.ResultToken}
		
		access(self)
		var destroyable: Bool
		
		init(){ 
			self.ownedResultTokenMap <-{} 
			self.destroyable = false
			self.StoragePath = /storage/gomokuResultCollection
			self.PublicPath = /public/gomokuResultCollection
		}
		
		access(account)
		fun withdraw(by id: UInt32): @GomokuResult.ResultToken?{ 
			if let token <- self.ownedResultTokenMap.remove(key: id){ 
				emit Withdraw(id: token.id, from: self.owner?.address)
				if self.ownedResultTokenMap.keys.length == 0{ 
					self.destroyable = true
				}
				return <-token
			} else{ 
				return nil
			}
		}
		
		access(account)
		fun deposit(token: @GomokuResult.ResultToken){ 
			let token <- token
			let id: UInt32 = token.id
			let oldToken <- self.ownedResultTokenMap[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			self.destroyable = false
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt32]{ 
			return self.ownedResultTokenMap.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(id: UInt32): &GomokuResult.ResultToken?{ 
			return &self.ownedResultTokenMap[id] as &GomokuResult.ResultToken?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): Int{ 
			return self.ownedResultTokenMap.keys.length
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyVault(): @GomokuResult.ResultCollection{ 
		emit CollectionCreated()
		return <-create ResultCollection()
	}
}
