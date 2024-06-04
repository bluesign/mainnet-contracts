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

	// Starly staking.
//
// Main features:
//   * compound interests, periodic compounding with 1 second period
//   * APY 15%, configurable
//   * users can stake/unstake anytime
//   * stakes can have min staking time in seconds
//   * stake is basically a NFT that is stored in user's wallet
//
// Admin:
//   * create custom stakes
//   * ability to refund
//
// Configurable precautions:
//   * master switches to enable/disable staking and unstaking
//   * unstaking fees (flat and percent)
//   * unstaking penalty (if fees > interest)
//   * no unstaking fees after certain staking period
//   * timestamp until unstaking is disabled
import CompoundInterest from "./CompoundInterest.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract StarlyTokenStaking: NonFungibleToken{ 
	access(all)
	event TokensStaked(id: UInt64, address: Address?, principal: UFix64, stakeTimestamp: UFix64, minStakingSeconds: UFix64, k: UFix64)
	
	access(all)
	event TokensUnstaked(id: UInt64, address: Address?, amount: UFix64, principal: UFix64, interest: UFix64, unstakingFees: UFix64, stakeTimestamp: UFix64, unstakeTimestamp: UFix64, k: UFix64)
	
	access(all)
	event TokensBurned(id: UInt64, principal: UFix64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalPrincipalStaked: UFix64
	
	access(all)
	var totalInterestPaid: UFix64
	
	access(all)
	var stakingEnabled: Bool
	
	access(all)
	var unstakingEnabled: Bool
	
	// the unstaking fees to unstake X tokens = unstakingFlatFee + unstakingFee * X
	access(all)
	var unstakingFee: UFix64
	
	access(all)
	var unstakingFlatFee: UFix64
	
	// unstake without fees if staked for this amount of seconds
	access(all)
	var unstakingFeesNotAppliedAfterSeconds: UFix64
	
	// cannot unstake if not staked for this amount of seconds
	access(all)
	var minStakingSeconds: UFix64
	
	// minimal principal for stake
	access(all)
	var minStakePrincipal: UFix64
	
	// cannot unstake until this timestamp
	access(all)
	var unstakingDisabledUntilTimestamp: UFix64
	
	// k = log10(1+r), where r is per-second interest ratio, taken from CompoundInterest contract
	access(all)
	var k: UFix64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let BurnerStoragePath: StoragePath
	
	access(all)
	enum Tier: UInt8{ 
		access(all)
		case NoTier
		
		access(all)
		case Silver
		
		access(all)
		case Gold
		
		access(all)
		case Platinum
	}
	
	access(all)
	resource interface StakePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrincipal(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakeTimestamp(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMinStakingSeconds(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getK(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccumulatedAmount(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnstakingFees(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canUnstake(): Bool
	}
	
	access(all)
	struct StakeMetadataView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let principal: UFix64
		
		access(all)
		let stakeTimestamp: UFix64
		
		access(all)
		let minStakingSeconds: UFix64
		
		access(all)
		let k: UFix64
		
		access(all)
		let accumulatedAmount: UFix64
		
		access(all)
		let canUnstake: Bool
		
		access(all)
		let unstakingFees: UFix64
		
		init(id: UInt64, principal: UFix64, stakeTimestamp: UFix64, minStakingSeconds: UFix64, k: UFix64, accumulatedAmount: UFix64, canUnstake: Bool, unstakingFees: UFix64){ 
			self.id = id
			self.principal = principal
			self.stakeTimestamp = stakeTimestamp
			self.minStakingSeconds = minStakingSeconds
			self.k = k
			self.accumulatedAmount = accumulatedAmount
			self.canUnstake = canUnstake
			self.unstakingFees = unstakingFees
		}
	}
	
	// Stake (named as NFT to comply with NonFungibleToken interface) contains the vault with staked tokens
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, StakePublic{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let principalVault: @StarlyToken.Vault
		
		access(all)
		let stakeTimestamp: UFix64
		
		access(all)
		let minStakingSeconds: UFix64
		
		access(all)
		let k: UFix64
		
		init(id: UInt64, principalVault: @StarlyToken.Vault, stakeTimestamp: UFix64, minStakingSeconds: UFix64, k: UFix64){ 
			self.id = id
			self.principalVault <- principalVault
			self.stakeTimestamp = stakeTimestamp
			self.minStakingSeconds = minStakingSeconds
			self.k = k
		}
		
		// if destroyed we destroy the tokens and decrease totalPrincipalStaked
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<StakeMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "StarlyToken stake #".concat(self.id.toString()), description: "id: ".concat(self.id.toString()).concat(", principal: ").concat(self.principalVault.balance.toString()).concat(", k: ").concat(self.k.toString()).concat(", stakeTimestamp: ").concat(UInt64(self.stakeTimestamp).toString()).concat(", minStakingSeconds: ").concat(UInt64(self.minStakingSeconds).toString()), thumbnail: MetadataViews.HTTPFile(url: ""))
				case Type<StakeMetadataView>():
					return StakeMetadataView(id: self.id, principal: self.principalVault.balance, stakeTimestamp: self.stakeTimestamp, minStakingSeconds: self.minStakingSeconds, k: self.k, accumulatedAmount: self.getAccumulatedAmount(), canUnstake: self.canUnstake(), unstakingFees: self.getUnstakingFees())
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrincipal(): UFix64{ 
			return self.principalVault.balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakeTimestamp(): UFix64{ 
			return self.stakeTimestamp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMinStakingSeconds(): UFix64{ 
			return self.minStakingSeconds
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getK(): UFix64{ 
			return self.k
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccumulatedAmount(): UFix64{ 
			let timestamp = getCurrentBlock().timestamp
			let seconds = timestamp - self.stakeTimestamp
			return self.principalVault.balance * CompoundInterest.generatedCompoundInterest(seconds: seconds, k: self.k)
		}
		
		// calculate unstaking fees using current StarlyTokenStaking parameters
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnstakingFees(): UFix64{ 
			return self.getUnstakingFeesInternal(unstakingFee: StarlyTokenStaking.unstakingFee, unstakingFlatFee: StarlyTokenStaking.unstakingFlatFee, unstakingFeesNotAppliedAfterSeconds: StarlyTokenStaking.unstakingFeesNotAppliedAfterSeconds)
		}
		
		// ability to calculate unstaking fees using provided parameters
		access(contract)
		fun getUnstakingFeesInternal(unstakingFee: UFix64, unstakingFlatFee: UFix64, unstakingFeesNotAppliedAfterSeconds: UFix64): UFix64{ 
			let timestamp = getCurrentBlock().timestamp
			let seconds = timestamp - self.stakeTimestamp
			if seconds >= unstakingFeesNotAppliedAfterSeconds{ 
				return 0.0
			} else{ 
				let accumulatedAmount = self.getAccumulatedAmount()
				return unstakingFlatFee + unstakingFee * accumulatedAmount
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canUnstake(): Bool{ 
			let timestamp = getCurrentBlock().timestamp
			let seconds = timestamp - self.stakeTimestamp
			if timestamp < StarlyTokenStaking.unstakingDisabledUntilTimestamp || seconds < self.minStakingSeconds || seconds < StarlyTokenStaking.minStakingSeconds || self.stakeTimestamp >= timestamp{ 
				return false
			} else{ 
				return true
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// We put stake creation logic into minter, its job is to have checks, emit events, update counters
	access(all)
	resource NFTMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintStake(address: Address?, principalVault: @StarlyToken.Vault, stakeTimestamp: UFix64, minStakingSeconds: UFix64, k: UFix64): @StarlyTokenStaking.NFT{ 
			pre{ 
				StarlyTokenStaking.stakingEnabled:
					"Staking is disabled"
				principalVault.balance > 0.0:
					"Principal cannot be zero"
				principalVault.balance >= StarlyTokenStaking.minStakePrincipal:
					"Principal is too small"
				k <= CompoundInterest.k2000:
					"K cannot be larger than 2000% APY"
			}
			let stake <- create NFT(id: StarlyTokenStaking.totalSupply, principalVault: <-principalVault, stakeTimestamp: stakeTimestamp, minStakingSeconds: minStakingSeconds, k: k)
			let principalAmount = stake.principalVault.balance
			StarlyTokenStaking.totalSupply = StarlyTokenStaking.totalSupply + 1 as UInt64
			StarlyTokenStaking.totalPrincipalStaked = StarlyTokenStaking.totalPrincipalStaked + principalAmount
			emit TokensStaked(id: stake.id, address: address, principal: principalAmount, stakeTimestamp: stakeTimestamp, minStakingSeconds: minStakingSeconds, k: stake.k)
			return <-stake
		}
	}
	
	// We put stake unstaking logic into burner, its job is to have checks, emit events, update counters
	access(all)
	resource NFTBurner{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun burnStake(stake: @StarlyTokenStaking.NFT, k: UFix64, address: Address?, minStakingSeconds: UFix64, unstakingFee: UFix64, unstakingFlatFee: UFix64, unstakingFeesNotAppliedAfterSeconds: UFix64, unstakingDisabledUntilTimestamp: UFix64): @StarlyToken.Vault{ 
			pre{ 
				StarlyTokenStaking.unstakingEnabled:
					"Unstaking is disabled"
				k <= CompoundInterest.k2000:
					"K cannot be larger than 2000% APY"
				stake.stakeTimestamp < getCurrentBlock().timestamp:
					"Cannot unstake stake with stakeTimestamp more or equal to current timestamp"
			}
			let timestamp = getCurrentBlock().timestamp
			if timestamp < unstakingDisabledUntilTimestamp{ 
				panic("Unstaking is disabled at the moment")
			}
			let seconds = timestamp - stake.stakeTimestamp
			if seconds < minStakingSeconds || seconds < stake.minStakingSeconds{ 
				panic("Staking period is too short")
			}
			let unstakingFees = stake.getUnstakingFeesInternal(unstakingFee: unstakingFee, unstakingFlatFee: unstakingFlatFee, unstakingFeesNotAppliedAfterSeconds: unstakingFeesNotAppliedAfterSeconds)
			let principalAmount = stake.principalVault.balance
			let vault <- stake.principalVault.withdraw(amount: principalAmount) as! @StarlyToken.Vault
			let compoundInterest = CompoundInterest.generatedCompoundInterest(seconds: seconds, k: k)
			let interestAmount = principalAmount * compoundInterest - principalAmount
			let interestVaultRef = StarlyTokenStaking.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)!
			if interestAmount > unstakingFees{ 
				let interestAmountMinusFees = interestAmount - unstakingFees
				vault.deposit(from: <-interestVaultRef.withdraw(amount: interestAmountMinusFees))
				StarlyTokenStaking.totalInterestPaid = StarlyTokenStaking.totalInterestPaid + interestAmountMinusFees
			} else{ 
				// if accumulated interest do not cover unstaking fees, user will pay penalty from principal vault
				let penalty = unstakingFees - interestAmount
				interestVaultRef.deposit(from: <-vault.withdraw(amount: penalty))
			}
			StarlyTokenStaking.totalPrincipalStaked = StarlyTokenStaking.totalPrincipalStaked - principalAmount
			emit TokensUnstaked(id: stake.id, address: address, amount: vault.balance, principal: principalAmount, interest: interestAmount, unstakingFees: unstakingFees, stakeTimestamp: stake.stakeTimestamp, unstakeTimestamp: timestamp, k: k)
			destroy stake
			return <-vault
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowStakePublic(id: UInt64): &StarlyTokenStaking.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakedAmount(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakingTier(): Tier
		
		// admin has to have the ability to refund stake
		access(contract)
		fun refund(id: UInt64, k: UFix64)
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowStakePrivate(id: UInt64): &StarlyTokenStaking.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stake(principalVault: @StarlyToken.Vault)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(id: UInt64): @StarlyToken.Vault
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstakeAll(): @StarlyToken.Vault
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, CollectionPrivate, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let stake <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: stake.id, from: self.owner?.address)
			return <-stake
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @StarlyTokenStaking.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakedAmount(): UFix64{ 
			var sum: UFix64 = 0.0
			for nftId in self.ownedNFTs.keys{ 
				let nft = (&self.ownedNFTs[nftId] as &{NonFungibleToken.NFT}?)!
				let stake = nft as! &StarlyTokenStaking.NFT
				sum = sum + stake.getAccumulatedAmount()
			}
			return sum
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakingTier(): Tier{ 
			var sum = self.getStakedAmount()
			if sum >= 50000.0{ 
				return Tier.Platinum
			} else if sum >= 10000.0{ 
				return Tier.Gold
			} else if sum >= 1000.0{ 
				return Tier.Silver
			} else{ 
				return Tier.NoTier
			}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let stake = nft as! &StarlyTokenStaking.NFT
			return stake as &{ViewResolver.Resolver}
		}
		
		access(contract)
		fun refund(id: UInt64, k: UFix64){ 
			if let address = self.owner?.address{ 
				let receiverRef = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(StarlyToken.TokenPublicReceiverPath).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow StarlyToken receiver reference to the recipient's vault!")
				let stake <- self.withdraw(withdrawID: id) as! @StarlyTokenStaking.NFT
				let burner = StarlyTokenStaking.account.storage.borrow<&NFTBurner>(from: StarlyTokenStaking.BurnerStoragePath)!
				let unstakeVault <- burner.burnStake(stake: <-stake, k: k, address: address, minStakingSeconds: StarlyTokenStaking.minStakingSeconds, unstakingFee: StarlyTokenStaking.unstakingFee, unstakingFlatFee: StarlyTokenStaking.unstakingFlatFee, unstakingFeesNotAppliedAfterSeconds: StarlyTokenStaking.unstakingFeesNotAppliedAfterSeconds, unstakingDisabledUntilTimestamp: StarlyTokenStaking.unstakingDisabledUntilTimestamp)
				receiverRef.deposit(from: <-unstakeVault)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowStakePublic(id: UInt64): &StarlyTokenStaking.NFT{ 
			let stakeRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let intermediateRef = stakeRef as! &StarlyTokenStaking.NFT
			return intermediateRef as &StarlyTokenStaking.NFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stake(principalVault: @StarlyToken.Vault){ 
			let minter = StarlyTokenStaking.account.storage.borrow<&NFTMinter>(from: StarlyTokenStaking.MinterStoragePath)!
			let stake <- minter.mintStake(address: self.owner?.address, principalVault: <-principalVault, stakeTimestamp: getCurrentBlock().timestamp, minStakingSeconds: StarlyTokenStaking.minStakingSeconds, k: StarlyTokenStaking.k)
			self.deposit(token: <-stake)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(id: UInt64): @StarlyToken.Vault{ 
			let burner = StarlyTokenStaking.account.storage.borrow<&NFTBurner>(from: StarlyTokenStaking.BurnerStoragePath)!
			let stake <- self.withdraw(withdrawID: id) as! @StarlyTokenStaking.NFT
			let k = stake.k
			return <-burner.burnStake(stake: <-stake, k: k, address: self.owner?.address, minStakingSeconds: StarlyTokenStaking.minStakingSeconds, unstakingFee: StarlyTokenStaking.unstakingFee, unstakingFlatFee: StarlyTokenStaking.unstakingFlatFee, unstakingFeesNotAppliedAfterSeconds: StarlyTokenStaking.unstakingFeesNotAppliedAfterSeconds, unstakingDisabledUntilTimestamp: StarlyTokenStaking.unstakingDisabledUntilTimestamp)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstakeAll(): @StarlyToken.Vault{ 
			let burner = StarlyTokenStaking.account.storage.borrow<&NFTBurner>(from: StarlyTokenStaking.BurnerStoragePath)
			let unstakeVault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault
			let stakeIDs = self.getIDs()
			for stakeID in stakeIDs{ 
				unstakeVault.deposit(from: <-self.unstake(id: stakeID))
			}
			return <-unstakeVault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowStakePrivate(id: UInt64): &StarlyTokenStaking.NFT{ 
			let stakePassRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return stakePassRef as! &StarlyTokenStaking.NFT
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Admin resource for controlling the configuration parameters and refunding
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setStakingEnabled(_ enabled: Bool){ 
			StarlyTokenStaking.stakingEnabled = enabled
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUnstakingEnabled(_ enabled: Bool){ 
			StarlyTokenStaking.unstakingEnabled = enabled
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUnstakingFee(_ amount: UFix64){ 
			StarlyTokenStaking.unstakingFee = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUnstakingFlatFee(_ amount: UFix64){ 
			StarlyTokenStaking.unstakingFlatFee = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUnstakingFeesNotAppliedAfterSeconds(_ seconds: UFix64){ 
			StarlyTokenStaking.unstakingFeesNotAppliedAfterSeconds = seconds
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinStakingSeconds(_ seconds: UFix64){ 
			StarlyTokenStaking.minStakingSeconds = seconds
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinStakePrincipal(_ amount: UFix64){ 
			StarlyTokenStaking.minStakePrincipal = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUnstakingDisabledUntilTimestamp(_ timestamp: UFix64){ 
			StarlyTokenStaking.unstakingDisabledUntilTimestamp = timestamp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setK(_ k: UFix64){ 
			pre{ 
				k <= CompoundInterest.k200:
					"Global K cannot be large larger than 200% APY"
			}
			StarlyTokenStaking.k = k
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun refund(collection: &{StarlyTokenStaking.CollectionPublic}, id: UInt64, k: UFix64){ 
			collection.refund(id: id, k: k)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNFTBurner(): @NFTBurner{ 
			return <-create NFTBurner()
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.totalPrincipalStaked = 0.0
		self.totalInterestPaid = 0.0
		self.stakingEnabled = true
		self.unstakingEnabled = true
		self.unstakingFee = 0.0
		self.unstakingFlatFee = 0.0
		self.unstakingFeesNotAppliedAfterSeconds = 0.0
		self.minStakingSeconds = 0.0
		self.minStakePrincipal = 0.0
		self.unstakingDisabledUntilTimestamp = 0.0
		self.k = CompoundInterest.k15 // 15% APY for Starly
		
		self.CollectionStoragePath = /storage/starlyTokenStakingCollection
		self.CollectionPublicPath = /public/starlyTokenStakingCollection
		self.AdminStoragePath = /storage/starlyTokenStakingAdmin
		self.MinterStoragePath = /storage/starlyTokenStakingMinter
		self.BurnerStoragePath = /storage/starlyTokenStakingBurner
		let admin <- create Admin()
		let minter <- admin.createNFTMinter()
		let burner <- admin.createNFTBurner()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		self.account.storage.save(<-burner, to: self.BurnerStoragePath)
		// for interests we will use account's default Starly token vault
		if self.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath) == nil{ 
			self.account.storage.save(<-StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()), to: StarlyToken.TokenStoragePath)
			var capability_1 = self.account.capabilities.storage.issue<&StarlyToken.Vault>(StarlyToken.TokenStoragePath)
			self.account.capabilities.publish(capability_1, at: StarlyToken.TokenPublicReceiverPath)
			var capability_2 = self.account.capabilities.storage.issue<&StarlyToken.Vault>(StarlyToken.TokenStoragePath)
			self.account.capabilities.publish(capability_2, at: StarlyToken.TokenPublicBalancePath)
		}
		emit ContractInitialized()
	}
}
