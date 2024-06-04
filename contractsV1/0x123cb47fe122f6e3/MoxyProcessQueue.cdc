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

	import MoxyData from "./MoxyData.cdc"

access(all)
contract MoxyProcessQueue{ 
	access(all)
	event MoxyQueueSelected(queueNumber: Int)
	
	access(all)
	event RunCompleted(processed: Int)
	
	access(all)
	resource Run{ 
		access(all)
		var runId: Int
		
		access(all)
		var indexStart: Int
		
		access(all)
		var indexEnd: Int
		
		access(all)
		var index: Int
		
		access(all)
		var currentAddresses: [Address]
		
		access(all)
		var isFinished: Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isAtBeginning(): Bool{ 
			return self.index == self.indexStart
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentAddresses(): [Address]{ 
			return self.currentAddresses
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBounds(): [Int]{ 
			return [self.index, self.indexEnd]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCurrentAddresses(addresses: [Address]){ 
			self.currentAddresses = addresses
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIndex(index: Int){ 
			self.index = index
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun complete(): Int{ 
			let processed = self.currentAddresses.length
			emit RunCompleted(processed: processed)
			self.index = self.index + processed
			if self.index > self.indexEnd{ 
				self.isFinished = true
			}
			self.currentAddresses = []
			return processed
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRemainings(): Int{ 
			return self.indexEnd - self.index + 1
		}
		
		init(runId: Int, indexStart: Int, indexEnd: Int){ 
			self.runId = runId
			self.indexStart = indexStart
			self.indexEnd = indexEnd
			self.index = indexStart
			self.currentAddresses = []
			self.isFinished = false
		}
	}
	
	access(all)
	struct CurrentRunStatus{ 
		access(all)
		var totalAccounts: Int
		
		access(all)
		var startTime: UFix64
		
		access(all)
		var lastUpdated: UFix64
		
		access(all)
		var accountsProcessed: Int
		
		access(all)
		var accountsRemaining: Int
		
		access(all)
		var hasFinished: Bool
		
		init(
			totalAccounts: Int,
			startTime: UFix64,
			lastUpdated: UFix64,
			accountsProcessed: Int,
			accountsRemaining: Int,
			hasFinished: Bool
		){ 
			self.totalAccounts = totalAccounts
			self.startTime = startTime
			self.lastUpdated = lastUpdated
			self.accountsProcessed = accountsProcessed
			self.accountsRemaining = accountsRemaining
			self.hasFinished = hasFinished
		}
	}
	
	access(all)
	resource QueueBatch{ 
		access(contract)
		var currentRuns: @[Run?]
		
		access(all)
		var startTime: UFix64
		
		access(all)
		var startTime0000: UFix64
		
		access(all)
		var lastUpdateTime: UFix64
		
		access(all)
		var endTime: UFix64
		
		access(all)
		var executions: Int
		
		access(all)
		var runSize: Int
		
		access(all)
		var accountsToProcess: Int
		
		access(all)
		var accountsProcessed: Int
		
		access(all)
		var isStarted: Bool
		
		access(contract)
		fun start(accounts: Int){ 
			pre{ 
				!self.isStarted:
					"Queues is already started."
			}
			if accounts == 0{ 
				self.startTime = 0.0
				self.startTime0000 = 0.0
				self.accountsToProcess = 0
				self.accountsProcessed = 0
				return
			}
			self.accountsToProcess = accounts
			var i = 0
			var incrFl = UFix64(accounts) / UFix64(self.currentRuns.length)
			if incrFl - UFix64(Int(incrFl)) > 0.0{ 
				incrFl = incrFl + 1.0
			}
			var incr = Int(incrFl)
			if incr < 1{ 
				incr = 1
			}
			var indexStart = 0
			var indexEnd = 0
			while i < self.currentRuns.length && indexStart < accounts{ 
				indexEnd = indexStart + incr
				let rem = accounts - indexEnd
				if rem < incr{ 
					indexEnd = accounts - 1
				}
				let run <- self.currentRuns[i] <- create Run(runId: i, indexStart: indexStart, indexEnd: indexEnd)
				destroy run
				i = i + 1
				indexStart = indexEnd + 1
			}
			self.isStarted = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRunSize(quantity: Int){ 
			pre{ 
				quantity > 0:
					"Run size must be greater than 0"
				quantity < 2:
					"Run size must be lower than 2"
			}
			var i = 0
			var temp: @[Run?] <- []
			while i < quantity{ 
				temp.append(nil)
				i = i + 1
			}
			self.currentRuns <-> temp
			
			// Elements on temp will be nil as the queue is not running
			destroy temp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isAtBeginning(): Bool{ 
			var isBeginning = true
			var i = 0
			while i < self.currentRuns.length && self.currentRuns[i] != nil
			&& self.currentRuns[i]?.isAtBeginning()!{ 
				i = i + 1
			}
			return i > self.currentRuns.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasFinished(): Bool{ 
			return self.accountsToProcess > 0 && self.accountsProcessed == self.accountsToProcess
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFreeRun(): @Run?{ 
			var tries = 0
			var i = 0
			var run: @Run? <- nil
			while i < self.currentRuns.length && run == nil{ 
				if self.currentRuns[i] != nil && !self.currentRuns[i]?.isFinished!{ 
					run <-! create Run(runId: i, indexStart: self.currentRuns[i]?.indexStart!, indexEnd: self.currentRuns[i]?.indexEnd!)
					run?.setIndex(index: self.currentRuns[i]?.index!)
				} else{ 
					i = i + 1
				}
			}
			if run != nil{ 
				emit MoxyQueueSelected(queueNumber: i)
			}
			return <-run
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun completeNextAddresses(run: @Run){ 
			self.currentRuns[run.runId]?.setCurrentAddresses(addresses: run.getCurrentAddresses())
			self.accountsProcessed = self.accountsProcessed
				+ self.currentRuns[run.runId]?.complete()!
			self.lastUpdateTime = getCurrentBlock().timestamp
			destroy run
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRemainings(): Int{ 
			var total = 0
			var i = 0
			while i < self.currentRuns.length{ 
				if self.currentRuns[i] != nil{ 
					total = total + self.currentRuns[i]?.getRemainings()!
				}
				i = i + 1
			}
			return total
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRunBounds(): [[Int]]{ 
			var bounds: [[Int]] = []
			var i = 0
			while i < self.currentRuns.length{ 
				if self.currentRuns[i] != nil{ 
					bounds.append(self.currentRuns[i]?.getBounds()!)
				}
				i = i + 1
			}
			return bounds
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentRunStatus(): CurrentRunStatus{ 
			return CurrentRunStatus(
				totalAccounts: self.accountsToProcess,
				startTime: self.startTime,
				lastUpdated: self.lastUpdateTime,
				accountsProcessed: self.accountsProcessed,
				accountsRemaining: self.getRemainings(),
				hasFinished: self.hasFinished()
			)
		}
		
		init(runSize: Int, accounts: Int){ 
			self.startTime = getCurrentBlock().timestamp
			self.startTime0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
			self.lastUpdateTime = getCurrentBlock().timestamp
			self.endTime = 0.0
			self.executions = 0
			self.currentRuns <- [nil]
			self.runSize = 1
			self.isStarted = false
			self.accountsToProcess = 0
			self.accountsProcessed = 0
			self.setRunSize(quantity: runSize)
			self.start(accounts: accounts)
		}
	}
	
	access(all)
	resource Queue: QueueInfo{ 
		access(contract)
		var accounts: [Address]
		
		access(contract)
		var accountsDict:{ Address: Int}
		
		access(all)
		var accountsQuantity: Int
		
		access(contract)
		var batchs: @[QueueBatch]
		
		access(contract)
		var currentBatch: @QueueBatch
		
		access(all)
		var runSize: Int
		
		access(all)
		var isStarted: Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccount(address: Address){ 
			if self.accountsDict[address] != nil{ 
				log("Account already added to queue")
				return
			}
			self.accounts.append(address)
			self.accountsDict[address] = self.accounts.length - 1
			self.accountsQuantity = self.accountsQuantity + 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccount(address: Address){ 
			self.accounts[self.accountsDict[address]!] = 0x0
			self.accountsQuantity = self.accountsQuantity - 1
		}
		
		access(contract)
		fun createNewBatch(){ 
			if self.accounts.length < 1{ 
				log("No accoutns to process.")
				return
			}
			let b <- self.currentBatch <- create QueueBatch(runSize: self.runSize, accounts: self.accounts.length)
			self.batchs.append(<-b)
			
			// Keep only the last 30 runs
			if self.batchs.length > 30{ 
				let r <- self.batchs.removeFirst()
				destroy r
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRunSize(): Int{ 
			return self.runSize
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRunSize(quantity: Int){ 
			pre{ 
				quantity > 0:
					"Run size must be greater than 0"
				quantity < 2:
					"Run size must be lower than 2"
			}
			self.runSize = quantity
		}
		
		/* Returns true if the current batch is at the beginning */
		access(TMP_ENTITLEMENT_OWNER)
		fun isAtBeginning(): Bool{ 
			return self.currentBatch.isAtBeginning()
		}
		
		/* Returns true if the current batch has finished */
		access(TMP_ENTITLEMENT_OWNER)
		fun hasFinished(): Bool{ 
			return self.currentBatch.hasFinished()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isEmptyQueue(): Bool{ 
			return self.accountsQuantity < 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountsQuantity(): Int{ 
			return self.accountsQuantity
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRemainingAddresses(): [Address]{ 
			var addrs: [Address] = []
			var bounds = self.currentBatch.getRunBounds()
			var i = 0
			while i < bounds.length{ 
				let fr = bounds[i][0]
				var to = bounds[i][1] + 1
				addrs = addrs.concat(self.accounts.slice(from: fr, upTo: to))
				i = i + 1
			}
			return addrs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockRunWith(quantity: Int): @Run?{ 
			let time0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
			if self.currentBatch.hasFinished() && self.currentBatch.startTime0000 < time0000 || self.currentBatch.accountsToProcess == 0{ 
				self.createNewBatch()
			}
			let run <- self.currentBatch.getFreeRun()
			if run != nil{ 
				let fr = run?.index!
				var to = fr + quantity
				if to > run?.indexEnd!{ 
					to = run?.indexEnd! + 1
				}
				let addrs = self.accounts.slice(from: fr, upTo: to)
				run?.setCurrentAddresses(addresses: addrs)
				return <-run
			}
			destroy run
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun completeNextAddresses(run: @Run){ 
			self.currentBatch.completeNextAddresses(run: <-run)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRemainings(): Int{ 
			if self.currentBatch.hasFinished() || self.currentBatch.accountsToProcess < 1{ 
				if self.currentBatch.startTime0000 < MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp){ 
					return self.accounts.length
				}
				return 0
			}
			return self.currentBatch.getRemainings()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentRunStatus(): CurrentRunStatus{ 
			return self.currentBatch.getCurrentRunStatus()
		}
		
		init(){ 
			self.accounts = []
			self.accountsDict ={} 
			self.accountsQuantity = 0
			self.batchs <- []
			self.runSize = 1
			self.currentBatch <- create QueueBatch(runSize: 1, accounts: 0)
			self.isStarted = false
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createNewQueue(): @Queue{ 
		return <-create Queue()
	}
	
	access(all)
	resource interface QueueInfo{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentRunStatus(): MoxyProcessQueue.CurrentRunStatus
	}
}
