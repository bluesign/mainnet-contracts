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

import BNU from "../0xae508a21ec3017f9;/BNU.cdc"

access(all)
contract ByteNextStaking{ 
	access(all)
	var rewardPerBlock: UFix64
	
	access(all)
	var startBlock: UInt64
	
	access(all)
	var endBlock: UInt64 // Block number which pool is end
	
	
	access(all)
	var lastRewardBlock: UInt64
	
	access(all)
	var accTokenPerShare: UFix64
	
	access(self)
	let lpVault: @{FungibleToken.Vault}
	
	access(self)
	let rewardVault: @{FungibleToken.Vault}
	
	access(self)
	let userInfo:{ Address: UserInfo}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let StakingProxyStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Deposit(user: Address, amount: UFix64)
	
	access(all)
	event Withdraw(user: Address, amount: UFix64)
	
	access(all)
	struct UserInfo{ 
		access(all)
		var amount: UFix64
		
		access(all)
		var rewardDebt: UFix64 // Reward debt
		
		
		// We do some fancy math here. Basically, any point in time, the amount of CAKEs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
		//   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
		init(amount: UFix64, rewardDebt: UFix64){ 
			self.amount = amount
			self.rewardDebt = rewardDebt
		}
		
		access(contract)
		fun setAmount(amount: UFix64){ 
			self.amount = amount
		}
		
		access(contract)
		fun setRewardDebt(rewardDebt: UFix64){ 
			self.rewardDebt = rewardDebt
		}
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun stopReward(){ 
			ByteNextStaking.endBlock = getCurrentBlock().height
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositToRewardPool(vault: @BNU.Vault){ 
			ByteNextStaking.rewardVault.deposit(from: <-vault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawRewardPool(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-ByteNextStaking.rewardVault.withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateRewardPerBlock(_ newValue: UFix64){ 
			pre{ 
				getCurrentBlock().height < ByteNextStaking.startBlock:
					"admin: cannot update when pool has started"
			}
			ByteNextStaking.rewardPerBlock = newValue
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateStartAndEndBlock(start: UInt64, end: UInt64){ 
			pre{ 
				getCurrentBlock().height < ByteNextStaking.startBlock:
					"admin: cannot update when pool start"
				start < end:
					"admin: should start block less than end block"
				getCurrentBlock().height < start:
					"admin: new start block should be greater than current block"
			}
			ByteNextStaking.startBlock = start
			ByteNextStaking.endBlock = end
			ByteNextStaking.lastRewardBlock = start
		}
	}
	
	access(all)
	resource StakingProxy{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(vault: @BNU.Vault): @{FungibleToken.Vault}?{ 
			pre{ 
				self.owner?.address != nil:
					"Owner should not be nil"
			}
			return <-ByteNextStaking.deposit(user: (self.owner!).address, vault: <-vault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				self.owner?.address != nil:
					"Owner should not be nil"
			}
			return <-ByteNextStaking.withdraw(user: (self.owner!).address, amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun emergencyWithdraw(user: Address): @{FungibleToken.Vault}{ 
			pre{ 
				self.owner?.address != nil:
					"Owner should not be nil"
			}
			return <-ByteNextStaking.emergencyWithdraw(user: (self.owner!).address)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createStakingProxy(): @StakingProxy{ 
		return <-create StakingProxy()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun totalStaked(): UFix64{ 
		return self.lpVault.balance
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBalances():{ String: UFix64}{ 
		return{ 
			"rewardVault": ByteNextStaking.rewardVault.balance,
			"lpVault": ByteNextStaking.lpVault.balance
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStakingUsers(): [Address]{ 
		return self.userInfo.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStakingAmount(user: Address): UFix64{ 
		return self.userInfo[user]?.amount ?? 0.0
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun pendingRewards(user: Address): UFix64{ 
		let lpSupply = self.lpVault.balance
		if lpSupply == 0.0{ 
			return 0.0
		}
		if !self.userInfo.containsKey(user){ 
			return 0.0
		}
		let user = self.userInfo[user]!
		let currentBlock = getCurrentBlock().height
		var accTokenPerShare = self.accTokenPerShare
		if currentBlock > self.lastRewardBlock{ 
			let multiplier = self.getMultiplier(_from: self.lastRewardBlock, _to: currentBlock)
			let reward = UFix64(multiplier) * self.rewardPerBlock
			accTokenPerShare = accTokenPerShare + reward / lpSupply
		}
		return user.amount * accTokenPerShare - user.rewardDebt
	}
	
	access(self)
	fun deposit(user: Address, vault: @{FungibleToken.Vault}): @{FungibleToken.Vault}?{ 
		let userInfo = self.userInfo[user] ?? UserInfo(amount: 0.0, rewardDebt: 0.0)
		self.updatePool()
		var reward: @{FungibleToken.Vault}? <- nil
		if userInfo.amount > 0.0{ 
			let pending = userInfo.amount * self.accTokenPerShare - userInfo.rewardDebt
			if pending > 0.0{ 
				reward <-! self.rewardVault.withdraw(amount: pending)
			}
		}
		let amount = vault.balance
		if vault.balance > 0.0{ 
			self.lpVault.deposit(from: <-vault)
			userInfo.setAmount(amount: userInfo.amount + amount)
		} else{ 
			destroy vault
		}
		userInfo.setRewardDebt(rewardDebt: userInfo.amount * self.accTokenPerShare)
		self.userInfo[user] = userInfo
		emit Deposit(user: user, amount: amount)
		return <-reward
	}
	
	access(self)
	fun withdraw(user: Address, amount: UFix64): @{FungibleToken.Vault}{ 
		pre{ 
			self.userInfo[user] != nil:
				"withdraw: Should stake before withdraw"
			(self.userInfo[user]!).amount >= amount:
				"withdraw: Amount invalid"
		}
		let info = self.userInfo[user]!
		self.updatePool()
		var vault <- BNU.createEmptyVault()
		let pending = info.amount * self.accTokenPerShare - info.rewardDebt
		if pending > 0.0{ 
			vault.deposit(from: <-self.rewardVault.withdraw(amount: pending))
		}
		if amount > 0.0{ 
			info.setAmount(amount: info.amount - amount)
			vault.deposit(from: <-self.lpVault.withdraw(amount: amount))
		}
		info.setRewardDebt(rewardDebt: info.amount * self.accTokenPerShare)
		self.userInfo[user] = info
		emit Withdraw(user: user, amount: amount)
		return <-vault
	}
	
	access(self)
	fun updatePool(){ 
		let currentBlock = getCurrentBlock().height
		if currentBlock < self.lastRewardBlock{ 
			return
		}
		let lpSupply = self.lpVault.balance
		if lpSupply == 0.0{ 
			self.lastRewardBlock = currentBlock
			return
		}
		let multiplier = self.getMultiplier(_from: self.lastRewardBlock, _to: currentBlock)
		let reward = UFix64(multiplier) * self.rewardPerBlock
		
		// TODO: REVIEW THIS
		self.accTokenPerShare = self.accTokenPerShare + reward / lpSupply
		self.lastRewardBlock = currentBlock
	}
	
	access(self)
	fun getMultiplier(_from: UInt64, _to: UInt64): UInt64{ 
		if _to <= self.endBlock{ 
			return _to - _from
		}
		if _from >= self.endBlock{ 
			return 0
		}
		return self.endBlock - _from
	}
	
	access(self)
	fun emergencyWithdraw(user: Address): @{FungibleToken.Vault}{ 
		let info = self.userInfo[user]!
		let amount = info.amount
		info.setAmount(amount: 0.0)
		info.setRewardDebt(rewardDebt: 0.0)
		self.userInfo[user] = info
		return <-self.lpVault.withdraw(amount: amount)
	}
	
	init(rewardPerBlock: UFix64, startBlock: UInt64, bonusEndBlock: UInt64){ 
		pre{ 
			startBlock < bonusEndBlock:
				"start block should less than end block"
		}
		self.lpVault <- BNU.createEmptyVault()
		self.rewardVault <- BNU.createEmptyVault()
		self.userInfo ={} 
		self.rewardPerBlock = rewardPerBlock
		self.startBlock = startBlock
		self.endBlock = bonusEndBlock
		self.lastRewardBlock = startBlock
		self.accTokenPerShare = 0.0
		
		// TODO: REMOVE SUFFIX WHEN MAINNET
		self.AdminStoragePath = /storage/bnuStakingAdmin
		self.StakingProxyStoragePath = /storage/bnuStakingProxy
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// apr = 5% = 10000 / 86400 / 365
		emit ContractInitialized()
	}
}
