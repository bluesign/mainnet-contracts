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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import StarVaultInterfaces from "./StarVaultInterfaces.cdc"

import StarVaultConfig from "./StarVaultConfig.cdc"

import StarVaultFactory from "./StarVaultFactory.cdc"

import LPStaking from "./LPStaking.cdc"

access(all)
contract RewardPool{ 
	access(all)
	let pid: Int
	
	access(all)
	let stakeToken: Address
	
	access(all)
	let duration: UFix64
	
	access(all)
	var periodFinish: UFix64
	
	access(all)
	var rewardRate: UFix64
	
	access(all)
	var lastUpdateTime: UFix64
	
	access(all)
	var rewardPerTokenStored: UFix64
	
	access(all)
	var queuedRewards: UFix64
	
	access(all)
	var currentRewards: UFix64
	
	access(all)
	var historicalRewards: UFix64
	
	access(all)
	var totalSupply: UFix64
	
	access(all)
	var userRewardPerTokenPaid:{ Address: UFix64}
	
	access(all)
	var rewards:{ Address: UFix64}
	
	access(self)
	var balances:{ Address: UFix64}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBalance(account: Address): UFix64{ 
		let collectionRef =
			getAccount(account).capabilities.get<&LPStaking.LPStakingCollection>(
				StarVaultConfig.LPStakingCollectionPublicPath
			).borrow()
		if collectionRef != nil{ 
			return (collectionRef!).getTokenBalance(tokenAddress: self.stakeToken)
		} else{ 
			return 0.0
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun balanceOf(account: Address): UFix64{ 
		var balance: UFix64 = 0.0
		if self.balances.containsKey(account){ 
			balance = self.balances[account]!
		}
		return balance
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun updateReward(account: Address?){ 
		self.rewardPerTokenStored = self.rewardPerToken()
		self.lastUpdateTime = self.lastTimeRewardApplicable()
		if account != nil{ 
			let _account = account!
			self.rewards[_account] = self.earned(account: _account)
			self.userRewardPerTokenPaid[_account] = self.rewardPerTokenStored
			let balance = self.balanceOf(account: _account)
			let newBalance = self.getBalance(account: _account)
			self.totalSupply = self.totalSupply - balance + newBalance
			self.balances[_account] = newBalance
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun lastTimeRewardApplicable(): UFix64{ 
		let now = getCurrentBlock().timestamp
		if now >= self.periodFinish{ 
			return self.periodFinish
		} else{ 
			return now
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun rewardPerToken(): UFix64{ 
		if self.totalSupply == 0.0{ 
			return self.rewardPerTokenStored
		}
		return self.rewardPerTokenStored
		+ (self.lastTimeRewardApplicable() - self.lastUpdateTime) * self.rewardRate
		/ self.totalSupply
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun earned(account: Address): UFix64{ 
		var userRewardPerTokenPaid: UFix64 = 0.0
		if self.userRewardPerTokenPaid.containsKey(account){ 
			userRewardPerTokenPaid = self.userRewardPerTokenPaid[account]!
		}
		var rewards: UFix64 = 0.0
		if self.rewards.containsKey(account){ 
			rewards = self.rewards[account]!
		}
		let balance = self.balanceOf(account: account)
		return balance * (self.rewardPerToken() - userRewardPerTokenPaid) + rewards
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getReward(account: Address){ 
		self.updateReward(account: account)
		let reward = self.earned(account: account)
		if reward > 0.0{ 
			self.rewards[account] = 0.0
			let provider = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
			let vault <- provider.withdraw(amount: reward)
			let receiver = getAccount(account).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
			receiver.deposit(from: <-vault)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun queueNewRewards(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"RewardPool: queueNewRewards empty vault"
		}
		let balance = vault.balance
		let receiver =
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow()!
		receiver.deposit(from: <-vault)
		self.notifyRewardAmount(rewards: balance)
	}
	
	access(self)
	fun notifyRewardAmount(rewards: UFix64){ 
		self.updateReward(account: nil)
		self.historicalRewards = self.historicalRewards + rewards
		let now = getCurrentBlock().timestamp
		var _rewards = rewards
		if now >= self.periodFinish{ 
			self.rewardRate = _rewards / self.duration
		} else{ 
			let remaining = self.periodFinish - now
			let leftover = remaining * self.rewardRate
			_rewards = _rewards + leftover
			self.rewardRate = _rewards / self.duration
		}
		self.currentRewards = _rewards
		self.lastUpdateTime = now
		self.periodFinish = now + self.duration
	}
	
	access(all)
	resource PoolPublic: StarVaultInterfaces.PoolPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun pid(): Int{ 
			return RewardPool.pid
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stakeToken(): Address{ 
			return RewardPool.stakeToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun duration(): UFix64{ 
			return RewardPool.duration
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun periodFinish(): UFix64{ 
			return RewardPool.periodFinish
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardRate(): UFix64{ 
			return RewardPool.rewardRate
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lastUpdateTime(): UFix64{ 
			return RewardPool.lastUpdateTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardPerTokenStored(): UFix64{ 
			return RewardPool.rewardPerTokenStored
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun queuedRewards(): UFix64{ 
			return RewardPool.queuedRewards
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun currentRewards(): UFix64{ 
			return RewardPool.currentRewards
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun historicalRewards(): UFix64{ 
			return RewardPool.historicalRewards
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun totalSupply(): UFix64{ 
			return RewardPool.totalSupply
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun balanceOf(account: Address): UFix64{ 
			return RewardPool.balanceOf(account: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateReward(account: Address?){ 
			return RewardPool.updateReward(account: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lastTimeRewardApplicable(): UFix64{ 
			return RewardPool.lastTimeRewardApplicable()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardPerToken(): UFix64{ 
			return RewardPool.rewardPerToken()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun earned(account: Address): UFix64{ 
			return RewardPool.earned(account: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReward(account: Address){ 
			return RewardPool.getReward(account: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun queueNewRewards(vault: @{FungibleToken.Vault}){ 
			return RewardPool.queueNewRewards(vault: <-vault)
		}
	}
	
	init(pid: Int, stakeToken: Address){ 
		self.pid = pid
		self.stakeToken = stakeToken
		self.duration = 3600.0
		self.periodFinish = 0.0
		self.rewardRate = 0.0
		self.lastUpdateTime = 0.0
		self.rewardPerTokenStored = 0.0
		self.queuedRewards = 0.0
		self.currentRewards = 0.0
		self.historicalRewards = 0.0
		self.totalSupply = 0.0
		self.userRewardPerTokenPaid ={} 
		self.rewards ={} 
		self.balances ={} 
		let poolStoragePath = StarVaultConfig.PoolStoragePath
		destroy <-self.account.storage.load<@AnyResource>(from: poolStoragePath)
		self.account.storage.save(<-create PoolPublic(), to: poolStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{StarVaultInterfaces.PoolPublic}>(
				poolStoragePath
			)
		self.account.capabilities.publish(capability_1, at: StarVaultConfig.PoolPublicPath)
		let collectionStoragePath = StarVaultConfig.LPStakingCollectionStoragePath
		destroy <-self.account.storage.load<@AnyResource>(from: collectionStoragePath)
		self.account.storage.save(
			<-LPStaking.createEmptyLPStakingCollection(),
			to: collectionStoragePath
		)
		var capability_2 =
			self.account.capabilities.storage.issue<
				&{StarVaultInterfaces.LPStakingCollectionPublic}
			>(collectionStoragePath)
		self.account.capabilities.publish(
			capability_2,
			at: StarVaultConfig.LPStakingCollectionPublicPath
		)
	}
}
