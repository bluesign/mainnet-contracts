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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyToken from "./MoxyToken.cdc"

access(all)
contract PlayAndEarn{ 
	access(all)
	event PlayAndEarnEventCreated(eventCode: String, feeCost: UFix64)
	
	access(all)
	event PlayAndEarnEventParticipantAdded(
		eventCode: String,
		addressAdded: Address,
		feePaid: UFix64
	)
	
	access(all)
	event PlayAndEarnEventPaymentToAddress(eventCode: String, receiver: Address, amount: UFix64)
	
	access(all)
	event PlayAndEarnEventTokensDeposited(eventCode: String, amount: UFix64)
	
	access(all)
	resource PlayAndEarnEcosystem: PlayAndEarnEcosystemInfoInterface{ 
		access(contract)
		var events: @{String: PlayAndEarnEvent}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMOXYBalanceFor(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getMOXYBalance()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFeeAmountFor(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getFeeAmount()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getParticipantsFor(eventCode: String): [Address]{ 
			return self.events[eventCode]?.getParticipants()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPaymentsFor(eventCode: String):{ Address: UFix64}{ 
			return self.events[eventCode]?.getPayments()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCreatedAt(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getCreatedAt()!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllEvents(): [String]{ 
			return self.events.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addParticipantTo(eventCode: String, address: Address, feeVault: @{FungibleToken.Vault}){ 
			self.events[eventCode]?.addParticipant(address: address, feeVault: <-feeVault.withdraw(amount: feeVault.balance))
			destroy feeVault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositTo(eventCode: String, vault: @{FungibleToken.Vault}){ 
			self.events[eventCode]?.deposit(vault: <-vault.withdraw(amount: vault.balance))
			destroy vault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun payToAddressFor(eventCode: String, address: Address, amount: UFix64){ 
			self.events[eventCode]?.payToAddress(address: address, amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addEvent(code: String, feeAmount: UFix64){ 
			if self.events[code] != nil{ 
				panic("Event already exists")
			}
			self.events[code] <-! create PlayAndEarnEvent(code: code, fee: feeAmount)
			emit PlayAndEarnEventCreated(eventCode: code, feeCost: feeAmount)
		}
		
		init(){ 
			self.events <-{} 
		}
	}
	
	access(all)
	resource PlayAndEarnEvent{ 
		access(all)
		var code: String
		
		access(all)
		var fee: UFix64
		
		access(all)
		var vault: @{FungibleToken.Vault}
		
		access(contract)
		var participants:{ Address: UFix64}
		
		access(contract)
		var payments:{ Address: UFix64}
		
		access(all)
		var createdAt: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFeeAmount(): UFix64{ 
			return self.fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMOXYBalance(): UFix64{ 
			return self.vault.balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getParticipants(): [Address]{ 
			return self.participants.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPayments():{ Address: UFix64}{ 
			return self.payments
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCreatedAt(): UFix64{ 
			return self.createdAt
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasParticipant(address: Address): Bool{ 
			return self.participants[address] != nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addParticipant(address: Address, feeVault: @{FungibleToken.Vault}){ 
			let feePaid = feeVault.balance
			self.participants[address] = feePaid
			self.vault.deposit(from: <-feeVault)
			emit PlayAndEarnEventParticipantAdded(
				eventCode: self.code,
				addressAdded: address,
				feePaid: feePaid
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(vault: @{FungibleToken.Vault}){ 
			let amount = vault.balance
			self.vault.deposit(from: <-vault)
			emit PlayAndEarnEventTokensDeposited(eventCode: self.code, amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun payToAddress(address: Address, amount: UFix64){ 
			// Get the amount from the event vault
			let vault <- self.vault.withdraw(amount: amount)
			
			// Get the recipient's public account object
			let recipient = getAccount(address)
			
			// Get a reference to the recipient's Receiver
			let receiverRef =
				recipient.capabilities.get<&{FungibleToken.Receiver}>(
					MoxyToken.moxyTokenReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic("Could not borrow receiver reference to the recipient's Vault")
			
			// Deposit the withdrawn tokens in the recipient's receiver
			receiverRef.deposit(from: <-vault)
			
			// Register address as payment recipient
			if self.payments[address] == nil{ 
				self.payments[address] = amount
			} else{ 
				self.payments[address] = self.payments[address]! + amount
			}
			emit PlayAndEarnEventPaymentToAddress(
				eventCode: self.code,
				receiver: address,
				amount: amount
			)
		}
		
		init(code: String, fee: UFix64){ 
			self.code = code
			self.fee = fee
			self.vault <- MoxyToken.createEmptyVault(vaultType: Type<@MoxyToken.Vault>())
			self.participants ={} 
			self.payments ={} 
			self.createdAt = getCurrentBlock().timestamp
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayAndEarnEcosystemPublicCapability(): &PlayAndEarnEcosystem{ 
		return self.account.capabilities.get<&PlayAndEarn.PlayAndEarnEcosystem>(
			PlayAndEarn.playAndEarnEcosystemPublic
		).borrow<&PlayAndEarn.PlayAndEarnEcosystem>()!
	}
	
	access(all)
	resource interface PlayAndEarnEcosystemInfoInterface{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getMOXYBalanceFor(eventCode: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFeeAmountFor(eventCode: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getParticipantsFor(eventCode: String): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPaymentsFor(eventCode: String):{ Address: UFix64}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCreatedAt(eventCode: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllEvents(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositTo(eventCode: String, vault: @{FungibleToken.Vault})
	}
	
	access(all)
	let playAndEarnEcosystemStorage: StoragePath
	
	access(all)
	let playAndEarnEcosystemPrivate: PrivatePath
	
	access(all)
	let playAndEarnEcosystemPublic: PublicPath
	
	init(){ 
		self.playAndEarnEcosystemStorage = /storage/playAndEarnEcosystem
		self.playAndEarnEcosystemPrivate = /private/playAndEarnEcosystem
		self.playAndEarnEcosystemPublic = /public/playAndEarnEcosystem
		let playAndEarnEcosystem <- create PlayAndEarnEcosystem()
		self.account.storage.save(<-playAndEarnEcosystem, to: self.playAndEarnEcosystemStorage)
		var capability_1 =
			self.account.capabilities.storage.issue<&PlayAndEarnEcosystem>(
				self.playAndEarnEcosystemStorage
			)
		self.account.capabilities.publish(capability_1, at: self.playAndEarnEcosystemPrivate)
		var capability_2 =
			self.account.capabilities.storage.issue<&PlayAndEarnEcosystem>(
				self.playAndEarnEcosystemStorage
			)
		self.account.capabilities.publish(capability_2, at: self.playAndEarnEcosystemPublic)
	}
}
