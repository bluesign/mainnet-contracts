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

	/**

# Staking NFTs to farm
# Multi-farming, staking seed `NFT` to get multiple ft rewards from a pool.
# Anyone can add reward during farming to extend the farming period; but only
# admin or poolAdmin can add a new type of reward token to a pool.
# Author: Increment Labs

**/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StakingError from "./StakingError.cdc"

import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"

access(all)
contract StakingNFT{ 
	access(all)
	let address: Address
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	// Staking admin resource path
	access(all)
	let StakingAdminStoragePath: StoragePath
	
	// path for pool admin resource
	access(all)
	let PoolAdminStoragePath: StoragePath
	
	// Resource path for user stake pass resource
	access(all)
	let UserCertificateStoragePath: StoragePath
	
	access(all)
	let UserCertificatePrivatePath: PrivatePath
	
	// pool status for Pool life cycle
	access(all)
	enum PoolStatus: UInt8{ 
		access(all)
		case CREATED
		
		access(all)
		case RUNNING
		
		access(all)
		case ENDED
		
		access(all)
		case CLEARED
	}
	
	// if true only Admin can create staking pool; otherwise everyone can create
	access(all)
	var isPermissionless: Bool
	
	// global pause: true will stop pool creation
	access(all)
	var pause: Bool
	
	access(all)
	var poolCount: UInt64
	
	// User participated pool: { userAddress => { pid => true } }
	access(self)
	let userStakingIds:{ Address:{ UInt64: Bool}}
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	init(){ 
		self.address = self.account.address
		self.isPermissionless = false
		self.pause = false
		self.userStakingIds ={} 
		self._reservedFields ={} 
		self.CollectionStoragePath = /storage/increment_nft_stakingCollectionStorage
		self.CollectionPublicPath = /public/increment_nft_stakingCollectionPublic
		self.CollectionPrivatePath = /private/increment_nft_stakingCollectionPrivate
		self.StakingAdminStoragePath = /storage/increment_nft_stakingAdmin
		self.PoolAdminStoragePath = /storage/increment_nft_stakingPoolAdmin
		self.UserCertificateStoragePath = /storage/increment_nft_stakingUserCertificate
		self.UserCertificatePrivatePath = /private/increment_nft_stakingUserCertificate
		self.poolCount = 0
		self.account.storage.save(<-create Admin(), to: self.StakingAdminStoragePath)
		self.account.storage.save(<-create StakingPoolCollection(), to: self.CollectionStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{PoolCollectionPublic}>(
				self.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		self.account.storage.save(<-create PoolAdmin(), to: self.PoolAdminStoragePath)
	}
	
	// Per-pool RewardInfo struct
	// One pool can have multiple reward tokens with {String: RewardInfo}
	access(all)
	struct RewardInfo{ 
		access(all)
		var startTimestamp: UFix64
		
		// start timestamp with Block.timestamp
		access(all)
		var endTimestamp: UFix64
		
		// token reward amount per session
		access(all)
		var rewardPerSession: UFix64
		
		// interval of session
		access(all)
		var sessionInterval: UFix64
		
		// token type of reward token
		access(all)
		let rewardTokenKey: String
		
		// total reward amount
		access(all)
		var totalReward: UFix64
		
		// last update reward round 
		access(all)
		var lastRound: UInt64
		
		// total round
		access(all)
		var totalRound: UInt64
		
		// token reward per staking token 
		access(all)
		var rewardPerSeed: UFix64
		
		init(
			rewardPerSession: UFix64,
			sessionInterval: UFix64,
			rewardTokenKey: String,
			startTimestamp: UFix64
		){ 
			pre{ 
				sessionInterval % 1.0 == 0.0:
					StakingError.errorEncode(msg: "sessionInterval must be integer", err: StakingError.ErrorCode.INVALID_PARAMETERS)
				rewardPerSession > 0.0:
					StakingError.errorEncode(msg: "rewardPerSession must be non-zero", err: StakingError.ErrorCode.INVALID_PARAMETERS)
			}
			self.startTimestamp = startTimestamp
			self.endTimestamp = 0.0
			self.rewardPerSession = rewardPerSession
			self.sessionInterval = sessionInterval
			self.rewardTokenKey = rewardTokenKey
			self.totalReward = 0.0
			self.lastRound = 0
			self.totalRound = 0
			self.rewardPerSeed = 0.0
		}
		
		// update pool reward info with staking seed balance and timestamp
		access(contract)
		fun updateRewardInfo(currentTimestamp: UFix64, stakingBalance: UFix64){ 
			let sessionInterval = self.sessionInterval
			let startTimestamp = self.startTimestamp
			let lastRound = self.lastRound
			let totalRound = self.totalRound
			
			// not start yet
			if currentTimestamp < self.startTimestamp{ 
				return
			}
			
			// get current round
			let timeCliff = currentTimestamp - startTimestamp
			let remainder = timeCliff % sessionInterval
			var currentRound = UInt64((timeCliff - remainder) / sessionInterval)
			if currentRound > totalRound{ 
				currentRound = totalRound
			}
			if currentRound <= lastRound{ 
				return
			}
			if stakingBalance == 0.0{ 
				// just update last round
				self.lastRound = currentRound
				return
			}
			let toBeDistributeReward = self.rewardPerSession * UFix64(currentRound - lastRound)
			let toBeDistributeRewardScaled = SwapConfig.UFix64ToScaledUInt256(toBeDistributeReward)
			let stakingBalanceScaled = SwapConfig.UFix64ToScaledUInt256(stakingBalance)
			// update pool's reward per seed index
			self.rewardPerSeed = self.rewardPerSeed
				+ SwapConfig.ScaledUInt256ToUFix64(
					toBeDistributeRewardScaled * SwapConfig.scaleFactor / stakingBalanceScaled
				)
			emit RPSUpdated(
				timestamp: currentTimestamp,
				toBeDistributeReward: toBeDistributeReward,
				stakingBalance: stakingBalance,
				rewardPerSeed: self.rewardPerSeed
			)
			// update last round
			self.lastRound = currentRound
		}
		
		// update reward info after pool add reward token
		// Note: caller ensures addRewardAmount to be multiples of rewardPerSession
		access(contract)
		fun appendReward(addRewardAmount: UFix64){ 
			self.totalReward = self.totalReward + addRewardAmount
			let appendRound = addRewardAmount / self.rewardPerSession
			self.totalRound = self.totalRound + UInt64(appendRound)
			let appendDuration = self.sessionInterval * appendRound
			if self.startTimestamp == 0.0{ 
				self.startTimestamp = getCurrentBlock().timestamp
				self.endTimestamp = self.startTimestamp + appendDuration
			} else if self.endTimestamp == 0.0{ 
				self.endTimestamp = self.startTimestamp + appendDuration
			} else{ 
				self.endTimestamp = self.endTimestamp + appendDuration
			}
		}
		
		// increase reward per session without delaying the end timestamp
		// Note: caller ensures addRewardAmount to be multiples of rounds left
		access(contract)
		fun appendRewardPerSession(addRewardAmount: UFix64){ 
			self.totalReward = self.totalReward + addRewardAmount
			let leftRound = self.totalRound - self.lastRound
			self.rewardPerSession = self.rewardPerSession + addRewardAmount / UFix64(leftRound)
		}
	}
	
	// Pool info for script query
	access(all)
	struct PoolInfo{ 
		access(all)
		let pid: UInt64
		
		access(all)
		let status: String
		
		access(all)
		let rewardsInfo:{ String: RewardInfo}
		
		access(all)
		let limitAmount: UInt64
		
		access(all)
		let totalStaking: UInt64
		
		access(all)
		let acceptedNFTKey: String
		
		access(all)
		let creator: Address
		
		access(all)
		let stringTypedVerifiers: [String]
		
		init(
			pid: UInt64,
			status: String,
			rewardsInfo:{ 
				String: RewardInfo
			},
			limitAmount: UInt64,
			totalStaking: UInt64,
			acceptedNFTKey: String,
			creator: Address,
			verifiers: [{
				INFTVerifier}
			]
		){ 
			self.pid = pid
			self.status = status
			self.rewardsInfo = rewardsInfo
			self.limitAmount = limitAmount
			self.totalStaking = totalStaking
			self.acceptedNFTKey = acceptedNFTKey
			self.creator = creator
			self.stringTypedVerifiers = []
			for verifier in verifiers{ 
				self.stringTypedVerifiers.append(verifier.getType().identifier)
			}
		}
	}
	
	// user info for each pool record user's reward and staking stats
	access(all)
	struct UserInfo{ 
		access(all)
		let pid: UInt64
		
		access(all)
		let addr: Address
		
		// Mapping of nft.tokenId staked into a specific pool. All nfts should belong to the same pool.acceptedNFTKey collection.
		access(all)
		let stakedNftIds:{ UInt64: Bool}
		
		// is blocked by staking and claim reward
		access(all)
		var isBlocked: Bool
		
		// user claimed rewards per seed token, update after claim 
		access(all)
		let rewardPerSeed:{ String: UFix64}
		
		// user claimed token amount
		access(all)
		let claimedRewards:{ String: UFix64}
		
		access(all)
		let unclaimedRewards:{ String: UFix64}
		
		init(
			pid: UInt64,
			addr: Address,
			isBlocked: Bool,
			rewardPerSeed:{ 
				String: UFix64
			},
			claimedRewards:{ 
				String: UFix64
			},
			unclaimedRewards:{ 
				String: UFix64
			}
		){ 
			self.pid = pid
			self.addr = addr
			self.stakedNftIds ={} 
			self.isBlocked = isBlocked
			self.rewardPerSeed = rewardPerSeed
			self.claimedRewards = claimedRewards
			self.unclaimedRewards = unclaimedRewards
		}
		
		access(contract)
		fun updateRewardPerSeed(tokenKey: String, rps: UFix64){ 
			if self.rewardPerSeed.containsKey(tokenKey){ 
				self.rewardPerSeed[tokenKey] = rps
			} else{ 
				self.rewardPerSeed.insert(key: tokenKey, rps)
			}
		}
		
		access(contract)
		fun addClaimedReward(tokenKey: String, amount: UFix64){ 
			if self.claimedRewards.containsKey(tokenKey){ 
				self.claimedRewards[tokenKey] = self.claimedRewards[tokenKey]! + amount
			} else{ 
				self.claimedRewards.insert(key: tokenKey, amount)
			}
		}
		
		access(contract)
		fun updateUnclaimedReward(tokenKey: String, newValue: UFix64){ 
			if self.unclaimedRewards.containsKey(tokenKey){ 
				self.unclaimedRewards[tokenKey] = newValue
			} else{ 
				self.unclaimedRewards.insert(key: tokenKey, newValue)
			}
		}
		
		// Return true if insert happenes, otherwise return false
		access(contract)
		fun addTokenId(tokenId: UInt64): Bool{ 
			if self.stakedNftIds.containsKey(tokenId){ 
				return false
			} else{ 
				self.stakedNftIds.insert(key: tokenId, true)
				return true
			}
		}
		
		// Return true if remove happenes, otherwise return false
		access(contract)
		fun removeTokenId(tokenId: UInt64): Bool{ 
			if self.stakedNftIds.containsKey(tokenId){ 
				self.stakedNftIds.remove(key: tokenId)
				return true
			} else{ 
				return false
			}
		}
		
		access(contract)
		fun setBlockStatus(_ flag: Bool){ 
			pre{ 
				flag != self.isBlocked:
					StakingError.errorEncode(msg: "UserInfo: status is same", err: StakingError.ErrorCode.SAME_BOOL_STATE)
			}
			self.isBlocked = flag
		}
	}
	
	// interfaces
	// Verifies eligible NFT from the collection a staking pool supports
	access(all)
	struct interface INFTVerifier{ 
		// Returns true if valid, otherwise false
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(nftRef: &{NonFungibleToken.NFT}, extraParams:{ String: AnyStruct}): Bool
	}
	
	// store pools in collection 
	access(all)
	resource interface PoolCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createStakingPool(
			adminRef: &StakingNFT.Admin?,
			poolAdminAddr: Address,
			limitAmount: UInt64,
			collection: @{NonFungibleToken.Collection},
			rewards: [
				StakingNFT.RewardInfo
			],
			verifiers: [{
				StakingNFT.INFTVerifier}
			],
			extraParams:{ 
				String: AnyStruct
			}
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPool(pid: UInt64): &{PoolPublic}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedPoolInfo(from: UInt64, to: UInt64): [PoolInfo]
	}
	
	// Pool interfaces verify PoolAdmin resource's pid as auth
	// use userCertificateCap to verify user and record user's address
	access(all)
	resource interface PoolPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addNewReward(
			adminRef: &StakingNFT.Admin?,
			poolAdminRef: &StakingNFT.PoolAdmin,
			newRewardToken: @{FungibleToken.Vault},
			rewardPerSession: UFix64,
			sessionInterval: UFix64,
			startTimestamp: UFix64?
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun extendReward(rewardTokenVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun boostReward(rewardPerSessionToAdd: UFix64, rewardToken: @{FungibleToken.Vault}): @{
			FungibleToken.Vault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stake(staker: Address, nft: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(userCertificateCap: Capability<&UserCertificate>, tokenId: UInt64): @{
			NonFungibleToken.NFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimRewards(userCertificateCap: Capability<&UserCertificate>): @{
			String:{ FungibleToken.Vault}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolInfo(): PoolInfo
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRewardInfo():{ String: RewardInfo}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserInfo(address: Address): UserInfo?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedUserInfo(from: UInt64, to: UInt64): [UserInfo]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVerifiers(): [{INFTVerifier}]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtraParams():{ String: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setClear(adminRef: &Admin?, poolAdminRef: &PoolAdmin): @{String:{ FungibleToken.Vault}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUserBlockedStatus(
			adminRef: &Admin?,
			poolAdminRef: &PoolAdmin,
			address: Address,
			flag: Bool
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePool()
	}
	
	// events
	access(all)
	event PoolRewardAdded(pid: UInt64, tokenKey: String, amount: UFix64)
	
	access(all)
	event PoolRewardBoosted(
		pid: UInt64,
		tokenKey: String,
		amount: UFix64,
		newRewardPerSession: UFix64
	)
	
	access(all)
	event PoolOpened(pid: UInt64, timestamp: UFix64)
	
	access(all)
	event TokenStaked(pid: UInt64, tokenKey: String, tokenId: UInt64, operator: Address)
	
	access(all)
	event TokenUnstaked(pid: UInt64, tokenKey: String, tokenId: UInt64, operator: Address)
	
	access(all)
	event RewardClaimed(
		pid: UInt64,
		tokenKey: String,
		amount: UFix64,
		userAddr: Address,
		userRPSAfter: UFix64
	)
	
	access(all)
	event PoolCreated(
		pid: UInt64,
		acceptedNFTKey: String,
		rewardsInfo:{ 
			String: RewardInfo
		},
		operator: Address
	)
	
	access(all)
	event PoolStatusChanged(pid: UInt64, status: String)
	
	access(all)
	event PoolUpdated(pid: UInt64, timestamp: UFix64, poolInfo: PoolInfo)
	
	access(all)
	event RPSUpdated(
		timestamp: UFix64,
		toBeDistributeReward: UFix64,
		stakingBalance: UFix64,
		rewardPerSeed: UFix64
	)
	
	// Staking admin events
	access(all)
	event PauseStateChanged(pauseFlag: Bool, operator: Address)
	
	access(all)
	event PermissionlessStateChanged(permissionless: Bool, operator: Address)
	
	// Pool admin events
	access(all)
	event UserBlockedStateChanged(
		pid: UInt64,
		address: Address,
		blockedFlag: Bool,
		operator: Address
	)
	
	// resources
	// staking admin resource for manage staking contract
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setPause(_ flag: Bool){ 
			pre{ 
				StakingNFT.pause != flag:
					StakingError.errorEncode(msg: "Set pause state faild, the state is same", err: StakingError.ErrorCode.SAME_BOOL_STATE)
			}
			StakingNFT.pause = flag
			emit PauseStateChanged(pauseFlag: flag, operator: (self.owner!).address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIsPermissionless(_ flag: Bool){ 
			pre{ 
				StakingNFT.isPermissionless != flag:
					StakingError.errorEncode(msg: "Set permissionless state faild, the state is same", err: StakingError.ErrorCode.SAME_BOOL_STATE)
			}
			StakingNFT.isPermissionless = flag
			emit PermissionlessStateChanged(permissionless: flag, operator: (self.owner!).address)
		}
	}
	
	// Pool creator / mananger should mint one and stores under PoolAdminStoragePath
	access(all)
	resource PoolAdmin{} 
	
	// UserCertificate store in user's storage path for Pool function to verify user's address
	access(all)
	resource UserCertificate{} 
	
	access(all)
	resource Pool: PoolPublic{ 
		// pid
		access(all)
		let pid: UInt64
		
		// Uplimit a user is allowed to stake up to
		access(all)
		let limitAmount: UInt64
		
		// Staking pool rewards
		access(all)
		let rewardsInfo:{ String: RewardInfo}
		
		access(all)
		var status: PoolStatus
		
		access(all)
		let creator: Address
		
		// supported NFT type: e.g. "A.2d4c3caffbeab845.FLOAT"
		access(all)
		let acceptedNFTKey: String
		
		// Extra verifiers to check if a given nft is eligible to stake into this pool
		access(self)
		let verifiers: [{INFTVerifier}]
		
		// Collection for NFT staking
		access(self)
		let stakingNFTCollection: @{NonFungibleToken.Collection}
		
		// Vaults for reward tokens
		access(self)
		let rewardVaults: @{String:{ FungibleToken.Vault}}
		
		// maps for userInfo
		access(self)
		let usersInfo:{ Address: UserInfo}
		
		// Any nft-relaated extra parameters the admin would provide in pool creation
		access(self)
		let extraParams:{ String: AnyStruct}
		
		init(limitAmount: UInt64, collection: @{NonFungibleToken.Collection}, rewardsInfo:{ String: RewardInfo}, creator: Address, verifiers: [{INFTVerifier}], extraParams:{ String: AnyStruct}){ 
			pre{ 
				collection.getIDs().length == 0:
					StakingError.errorEncode(msg: "nonempty seed collection", err: StakingError.ErrorCode.INVALID_PARAMETERS)
			}
			let newPid = StakingNFT.poolCount
			StakingNFT.poolCount = StakingNFT.poolCount + 1
			let acceptedNFTKey = StakingNFT.getNFTType(collectionIdentifier: collection.getType().identifier)
			self.pid = newPid
			self.limitAmount = limitAmount
			self.acceptedNFTKey = acceptedNFTKey
			self.rewardsInfo = rewardsInfo
			self.status = PoolStatus.CREATED
			self.stakingNFTCollection <- collection
			self.rewardVaults <-{} 
			self.usersInfo ={} 
			self.verifiers = verifiers
			self.extraParams = extraParams
			self.creator = creator
			emit PoolCreated(pid: newPid, acceptedNFTKey: acceptedNFTKey, rewardsInfo: rewardsInfo, operator: creator)
		}
		
		// update pool rewards info before any user action
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePool(){ 
			if self.rewardsInfo.length == 0{ 
				return
			}
			let stakingBalance = self.stakingNFTCollection.getIDs().length
			let currentTimestamp = getCurrentBlock().timestamp
			var numClosed = 0
			// update multiple reward info
			for key in self.rewardsInfo.keys{ 
				let rewardInfoRef = (&self.rewardsInfo[key] as &RewardInfo?)!
				if rewardInfoRef.endTimestamp > 0.0 && currentTimestamp >= rewardInfoRef.endTimestamp{ 
					numClosed = numClosed + 1
				}
				// update pool reward info
				rewardInfoRef.updateRewardInfo(currentTimestamp: currentTimestamp, stakingBalance: UFix64(stakingBalance))
			}
			
			// when all rewards ended change the pool status
			if numClosed == self.rewardsInfo.length && self.status.rawValue < PoolStatus.ENDED.rawValue{ 
				self.status = PoolStatus.ENDED
				emit PoolStatusChanged(pid: self.pid, status: self.status.rawValue.toString())
			}
			emit PoolUpdated(pid: self.pid, timestamp: currentTimestamp, poolInfo: self.getPoolInfo())
		}
		
		// claim and return pending rewards, if any
		// @Param harvestMode - if true, claim and return; otherwise, just compute and update userInfo.unclaimedRewards
		access(self)
		fun harvest(harvester: Address, harvestMode: Bool): @{String:{ FungibleToken.Vault}}{ 
			pre{ 
				self.status != PoolStatus.CLEARED:
					StakingError.errorEncode(msg: "Pool: pool already cleaned", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
				self.usersInfo.containsKey(harvester):
					StakingError.errorEncode(msg: "Pool: no UserInfo", err: StakingError.ErrorCode.INVALID_PARAMETERS)
				!harvestMode || (self.usersInfo[harvester]!).isBlocked == false:
					StakingError.errorEncode(msg: "Pool: user is blocked", err: StakingError.ErrorCode.ACCESS_DENY)
			}
			let vaults: @{String:{ FungibleToken.Vault}} <-{} 
			let userInfoRef = (&self.usersInfo[harvester] as &UserInfo?)!
			for key in self.rewardsInfo.keys{ 
				let rewardTokenKey = (self.rewardsInfo[key]!).rewardTokenKey
				let poolRPS = (self.rewardsInfo[key]!).rewardPerSeed
				// new reward added after user last stake
				if !userInfoRef.rewardPerSeed.containsKey(key){ 
					userInfoRef.updateRewardPerSeed(tokenKey: key, rps: 0.0)
				}
				let userRPS = userInfoRef.rewardPerSeed[key]!
				let stakingAmount = UFix64(userInfoRef.stakedNftIds.length)
				let stakingAmountScaled = SwapConfig.UFix64ToScaledUInt256(stakingAmount)
				let poolRPSScaled = SwapConfig.UFix64ToScaledUInt256(poolRPS)
				let userRPSScaled = SwapConfig.UFix64ToScaledUInt256(userRPS)
				
				// Update UserInfo with pool RewardInfo RPS index
				userInfoRef.updateRewardPerSeed(tokenKey: rewardTokenKey, rps: poolRPS)
				
				// newly generated pending reward to be claimed
				let newPendingClaim = SwapConfig.ScaledUInt256ToUFix64((poolRPSScaled - userRPSScaled) * stakingAmountScaled / SwapConfig.scaleFactor)
				let pendingClaimAll = newPendingClaim + (userInfoRef.unclaimedRewards[rewardTokenKey] ?? 0.0)
				if pendingClaimAll > 0.0{ 
					if !harvestMode{ 
						// No real harvest, just compute and update userInfo.unclaimedRewards
						userInfoRef.updateUnclaimedReward(tokenKey: rewardTokenKey, newValue: pendingClaimAll)
					} else{ 
						userInfoRef.updateUnclaimedReward(tokenKey: rewardTokenKey, newValue: 0.0)
						userInfoRef.addClaimedReward(tokenKey: rewardTokenKey, amount: pendingClaimAll)
						emit RewardClaimed(pid: self.pid, tokenKey: rewardTokenKey, amount: pendingClaimAll, userAddr: harvester, userRPSAfter: poolRPS)
						let rewardVault = (&self.rewardVaults[rewardTokenKey] as &{FungibleToken.Vault}?)!
						let claimVault <- rewardVault.withdraw(amount: pendingClaimAll)
						vaults[rewardTokenKey] <-! claimVault as @{FungibleToken.Vault}
					}
				}
			}
			return <-vaults
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimRewards(userCertificateCap: Capability<&UserCertificate>): @{String:{ FungibleToken.Vault}}{ 
			pre{ 
				userCertificateCap.check() && (userCertificateCap.borrow()!).owner != nil:
					StakingError.errorEncode(msg: "Cannot borrow reference to UserCertificate", err: StakingError.ErrorCode.INVALID_USER_CERTIFICATE)
			}
			self.updatePool()
			let userAddress = ((userCertificateCap.borrow()!).owner!).address
			return <-self.harvest(harvester: userAddress, harvestMode: true)
		}
		
		// Add a new type of reward to the pool.
		// Reward starts immediately if no starttime is given.
		access(TMP_ENTITLEMENT_OWNER)
		fun addNewReward(adminRef: &Admin?, poolAdminRef: &PoolAdmin, newRewardToken: @{FungibleToken.Vault}, rewardPerSession: UFix64, sessionInterval: UFix64, startTimestamp: UFix64?){ 
			pre{ 
				adminRef != nil || (poolAdminRef.owner!).address == self.creator:
					StakingError.errorEncode(msg: "Pool: no access to add pool rewards", err: StakingError.ErrorCode.ACCESS_DENY)
				newRewardToken.balance > 0.0:
					StakingError.errorEncode(msg: "Pool: not allowed to add zero reward", err: StakingError.ErrorCode.INVALID_PARAMETERS)
				self.status == PoolStatus.CREATED || self.status == PoolStatus.RUNNING:
					StakingError.errorEncode(msg: "Pool: not allowed to add reward after end", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
			}
			self.updatePool()
			let newRewardTokenKey = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: newRewardToken.getType().identifier)
			if !self.rewardsInfo.containsKey(newRewardTokenKey){ 
				self.rewardsInfo.insert(key: newRewardTokenKey, RewardInfo(rewardPerSession: rewardPerSession, sessionInterval: sessionInterval, rewardTokenKey: newRewardTokenKey, startTimestamp: startTimestamp ?? 0.0))
			}
			return self.extendReward(rewardTokenVault: <-newRewardToken)
		}
		
		// Extend the end time of an existing type of reward.
		// Note: Caller ensures rewardInfo of the added token has been setup already
		access(TMP_ENTITLEMENT_OWNER)
		fun extendReward(rewardTokenVault: @{FungibleToken.Vault}){ 
			pre{ 
				rewardTokenVault.balance > 0.0:
					StakingError.errorEncode(msg: "Pool: not allowed to add zero reward", err: StakingError.ErrorCode.INVALID_PARAMETERS)
				self.status == PoolStatus.CREATED || self.status == PoolStatus.RUNNING:
					StakingError.errorEncode(msg: "Pool: not allowed to add reward after end", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
			}
			self.updatePool()
			let rewardTokenKey = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: rewardTokenVault.getType().identifier)
			assert(self.rewardsInfo.containsKey(rewardTokenKey), message: StakingError.errorEncode(msg: "Pool: rewards type not support", err: StakingError.ErrorCode.MISMATCH_VAULT_TYPE))
			let rewardInfoRef = (&self.rewardsInfo[rewardTokenKey] as &RewardInfo?)!
			assert(rewardInfoRef.rewardTokenKey == rewardTokenKey, message: StakingError.errorEncode(msg: "Pool: reward type not match", err: StakingError.ErrorCode.MISMATCH_VAULT_TYPE))
			let rewardBalance = rewardTokenVault.balance
			assert(rewardBalance >= rewardInfoRef.rewardPerSession, message: StakingError.errorEncode(msg: "Pool: reward balance not enough", err: StakingError.ErrorCode.INSUFFICIENT_REWARD_BALANCE))
			assert(rewardBalance % rewardInfoRef.rewardPerSession == 0.0, message: StakingError.errorEncode(msg: "Pool: reward balance not valid ".concat(rewardTokenKey), err: StakingError.ErrorCode.INVALID_BALANCE_AMOUNT))
			// update reward info 
			rewardInfoRef.appendReward(addRewardAmount: rewardBalance)
			
			// add reward vault to pool resource
			if self.rewardVaults.containsKey(rewardTokenKey){ 
				let vault = (&self.rewardVaults[rewardTokenKey] as &{FungibleToken.Vault}?)!
				vault.deposit(from: <-rewardTokenVault)
			} else{ 
				self.rewardVaults[rewardTokenKey] <-! rewardTokenVault
			}
			emit PoolRewardAdded(pid: self.pid, tokenKey: rewardTokenKey, amount: rewardBalance)
			if self.status == PoolStatus.CREATED{ 
				self.status = PoolStatus.RUNNING
				emit PoolOpened(pid: self.pid, timestamp: getCurrentBlock().timestamp)
				emit PoolStatusChanged(pid: self.pid, status: self.status.rawValue.toString())
			}
		}
		
		// Boost the apr of an existing type of reward token by increasing rewardPerSession. This doesn't extend the reward window.
		// Return: any remaining reward token not added in.
		// Note: Caller ensures rewardInfo of the added token has been setup already.
		access(TMP_ENTITLEMENT_OWNER)
		fun boostReward(rewardPerSessionToAdd: UFix64, rewardToken: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
			pre{ 
				rewardToken.balance > 0.0:
					StakingError.errorEncode(msg: "Pool: not allowed to add zero reward", err: StakingError.ErrorCode.INVALID_PARAMETERS)
				self.status == PoolStatus.CREATED || self.status == PoolStatus.RUNNING:
					StakingError.errorEncode(msg: "Pool: not allowed to add reward after end", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
			}
			self.updatePool()
			let rewardTokenKey = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: rewardToken.getType().identifier)
			assert(self.rewardsInfo.containsKey(rewardTokenKey), message: StakingError.errorEncode(msg: "Pool: rewards type not support", err: StakingError.ErrorCode.MISMATCH_VAULT_TYPE))
			let rewardInfoRef = (&self.rewardsInfo[rewardTokenKey] as &RewardInfo?)!
			assert(rewardInfoRef.rewardTokenKey == rewardTokenKey, message: StakingError.errorEncode(msg: "Pool: reward type not match", err: StakingError.ErrorCode.MISMATCH_VAULT_TYPE))
			let leftRound = rewardInfoRef.totalRound - rewardInfoRef.lastRound
			assert(leftRound >= 1, message: StakingError.errorEncode(msg: "Pool: either no reward added or no time left to boost reward", err: StakingError.ErrorCode.INVALID_PARAMETERS))
			let boostedRewardAmount = rewardPerSessionToAdd * UFix64(leftRound)
			// update reward info 
			rewardInfoRef.appendRewardPerSession(addRewardAmount: boostedRewardAmount)
			// add reward vault to pool resource
			let vault = (&self.rewardVaults[rewardTokenKey] as &{FungibleToken.Vault}?)!
			vault.deposit(from: <-rewardToken.withdraw(amount: boostedRewardAmount))
			emit PoolRewardBoosted(pid: self.pid, tokenKey: rewardTokenKey, amount: boostedRewardAmount, newRewardPerSession: rewardInfoRef.rewardPerSession)
			return <-rewardToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun eligibilityCheck(nftRef: &{NonFungibleToken.NFT}, extraParams:{ String: AnyStruct}): Bool{ 
			for verifier in self.verifiers{ 
				if verifier.verify(nftRef: nftRef, extraParams: extraParams) == false{ 
					return false
				}
			}
			return true
		}
		
		// Deposit staking token on behalf of staker
		access(TMP_ENTITLEMENT_OWNER)
		fun stake(staker: Address, nft: @{NonFungibleToken.NFT}){ 
			pre{ 
				self.status == PoolStatus.RUNNING || self.status == PoolStatus.CREATED:
					StakingError.errorEncode(msg: "Pool: not open staking yet", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
			}
			self.updatePool()
			
			// Here has to use auth reference, as verifiers may need to downcast to get extra info 
			let nftRef = &nft as &{NonFungibleToken.NFT}
			// This nft must pass eligibility check before staking, with extraParams setup by the pool creator / admin.
			assert(self.eligibilityCheck(nftRef: nftRef, extraParams: self.extraParams), message: StakingError.errorEncode(msg: "Pool: nft ineligible to stake", err: StakingError.ErrorCode.NOT_ELIGIBLE))
			let userAddress = staker
			if !self.usersInfo.containsKey(userAddress){ 
				// create user info
				let userRPS:{ String: UFix64} ={} 
				for key in self.rewardsInfo.keys{ 
					let poolRewardInfo = self.rewardsInfo[key]!
					userRPS[key] = poolRewardInfo.rewardPerSeed
				}
				if StakingNFT.userStakingIds.containsKey(userAddress) == false{ 
					StakingNFT.userStakingIds.insert(key: userAddress,{ self.pid: true})
				} else if (StakingNFT.userStakingIds[userAddress]!).containsKey(self.pid) == false{ 
					(StakingNFT.userStakingIds[userAddress]!).insert(key: self.pid, true)
				}
				self.usersInfo[userAddress] = UserInfo(pid: self.pid, addr: userAddress, isBlocked: false, rewardPerSeed: userRPS, claimedRewards:{} , unclaimedRewards:{} )
				(self.usersInfo[userAddress]!).addTokenId(tokenId: nft.id)
			} else{ 
				let userInfoRef = (&self.usersInfo[userAddress] as &UserInfo?)!
				assert(userInfoRef.isBlocked == false, message: StakingError.errorEncode(msg: "Pool: user is blocked", err: StakingError.ErrorCode.ACCESS_DENY))
				assert(UInt64(userInfoRef.stakedNftIds.length) + 1 <= self.limitAmount, message: StakingError.errorEncode(msg: "Staking: staking amount exceeds limit: ".concat(self.limitAmount.toString()), err: StakingError.ErrorCode.EXCEEDED_AMOUNT_LIMIT))
				// 1. Update userInfo rewards index and unclaimedRewards but don't do real claim
				let anyClaimedRewards <- self.harvest(harvester: userAddress, harvestMode: false)
				assert(anyClaimedRewards.length == 0, message: "panic: something wrong, shouldn't be here")
				destroy anyClaimedRewards
				// 2. Insert nft tokenId
				userInfoRef.addTokenId(tokenId: nft.id)
			}
			emit TokenStaked(pid: self.pid, tokenKey: self.acceptedNFTKey, tokenId: nft.id, operator: userAddress)
			self.stakingNFTCollection.deposit(token: <-nft)
		}
		
		// Withdraw and return seed staking token
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(userCertificateCap: Capability<&UserCertificate>, tokenId: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.stakingNFTCollection.getIDs().contains(tokenId):
					StakingError.errorEncode(msg: "Unstake: nonexistent tokenId in staked Collection", err: StakingError.ErrorCode.NOT_FOUND)
				self.status != PoolStatus.CLEARED:
					StakingError.errorEncode(msg: "Unstake: Pool already cleared", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
				userCertificateCap.check() && (userCertificateCap.borrow()!).owner != nil:
					StakingError.errorEncode(msg: "Cannot borrow reference to UserCertificate", err: StakingError.ErrorCode.INVALID_USER_CERTIFICATE)
			}
			self.updatePool()
			let userAddress = ((userCertificateCap.borrow()!).owner!).address
			let userInfoRef = (&self.usersInfo[userAddress] as &UserInfo?)!
			assert(userInfoRef.stakedNftIds.containsKey(tokenId), message: StakingError.errorEncode(msg: "Unstake: cannot unstake nft doesn't belong to the user", err: StakingError.ErrorCode.NOT_FOUND))
			// 1. Update userInfo rewards index and unclaimedRewards but don't do real claim
			let anyClaimedRewards <- self.harvest(harvester: userAddress, harvestMode: false)
			assert(anyClaimedRewards.length == 0, message: "panic: something wrong, shouldn't be here")
			destroy anyClaimedRewards
			// 2. Remove unstaked nft tokenId
			userInfoRef.removeTokenId(tokenId: tokenId)
			emit TokenUnstaked(pid: self.pid, tokenKey: self.acceptedNFTKey, tokenId: tokenId, operator: userAddress)
			return <-self.stakingNFTCollection.withdraw(withdrawID: tokenId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolInfo(): PoolInfo{ 
			let poolInfo = PoolInfo(pid: self.pid, status: self.status.rawValue.toString(), rewardsInfo: self.rewardsInfo, limitAmount: self.limitAmount, totalStaking: UInt64(self.stakingNFTCollection.getIDs().length), acceptedNFTKey: self.acceptedNFTKey, creator: self.creator, verifiers: self.verifiers)
			return poolInfo
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRewardInfo():{ String: RewardInfo}{ 
			return self.rewardsInfo
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserInfo(address: Address): UserInfo?{ 
			return self.usersInfo[address]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedUserInfo(from: UInt64, to: UInt64): [UserInfo]{ 
			pre{ 
				from <= to && from < UInt64(self.usersInfo.length):
					StakingError.errorEncode(msg: "from index out of range", err: StakingError.ErrorCode.INVALID_PARAMETERS)
			}
			let userLen = UInt64(self.usersInfo.length)
			let endIndex = to >= userLen ? userLen - 1 : to
			var curIndex = from
			// Array.slice() is not supported yet.
			let list: [UserInfo] = []
			while curIndex <= endIndex{ 
				let address = self.usersInfo.keys[curIndex]
				list.append(self.usersInfo[address]!)
				curIndex = curIndex + 1
			}
			return list
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVerifiers(): [{INFTVerifier}]{ 
			return self.verifiers
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtraParams():{ String: AnyStruct}{ 
			return self.extraParams
		}
		
		// Mark ENDED pool as CLEARED after all staking tokens are withdrawn, and reclaim remaining rewards if any.
		access(TMP_ENTITLEMENT_OWNER)
		fun setClear(adminRef: &Admin?, poolAdminRef: &PoolAdmin): @{String:{ FungibleToken.Vault}}{ 
			pre{ 
				adminRef != nil || (poolAdminRef.owner!).address == self.creator:
					StakingError.errorEncode(msg: "Pool: no access to clear pool status", err: StakingError.ErrorCode.ACCESS_DENY)
				self.status == PoolStatus.ENDED:
					StakingError.errorEncode(msg: "Pool not end yet", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
				self.stakingNFTCollection.getIDs().length == 0:
					StakingError.errorEncode(msg: "Pool not clear yet", err: StakingError.ErrorCode.POOL_LIFECYCLE_ERROR)
			}
			self.updatePool()
			let vaults: @{String:{ FungibleToken.Vault}} <-{} 
			let keys = self.rewardsInfo.keys
			for key in keys{ 
				let vaultRef = &self.rewardVaults[key] as &{FungibleToken.Vault}?
				if vaultRef != nil{ 
					vaults[key] <-! (vaultRef!).withdraw(amount: (vaultRef!).balance)
				}
			}
			self.status = PoolStatus.CLEARED
			emit PoolStatusChanged(pid: self.pid, status: self.status.rawValue.toString())
			return <-vaults
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUserBlockedStatus(adminRef: &Admin?, poolAdminRef: &PoolAdmin, address: Address, flag: Bool){ 
			pre{ 
				adminRef != nil || (poolAdminRef.owner!).address == self.creator:
					StakingError.errorEncode(msg: "Pool: no access to block users", err: StakingError.ErrorCode.ACCESS_DENY)
			}
			self.updatePool()
			let userInfoRef = &self.usersInfo[address] as &UserInfo?
			if userInfoRef == nil{ 
				self.usersInfo[address] = UserInfo(pid: self.pid, addr: address, isBlocked: flag, rewardPerSeed:{} , claimedRewards:{} , unclaimedRewards:{} )
			} else{ 
				(userInfoRef!).setBlockStatus(flag)
			}
			emit UserBlockedStateChanged(pid: self.pid, address: address, blockedFlag: flag, operator: adminRef != nil ? ((adminRef!).owner!).address : (poolAdminRef.owner!).address)
		}
	}
	
	access(all)
	resource StakingPoolCollection: PoolCollectionPublic{ 
		access(self)
		let pools: @{UInt64: Pool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createStakingPool(adminRef: &Admin?, poolAdminAddr: Address, limitAmount: UInt64, collection: @{NonFungibleToken.Collection}, rewards: [RewardInfo], verifiers: [{INFTVerifier}], extraParams:{ String: AnyStruct}){ 
			pre{ 
				StakingNFT.isPermissionless || adminRef != nil:
					StakingError.errorEncode(msg: "Staking: no access to create pool", err: StakingError.ErrorCode.ACCESS_DENY)
				StakingNFT.pause != true:
					StakingError.errorEncode(msg: "Staking: pool creation paused", err: StakingError.ErrorCode.ACCESS_DENY)
			}
			let rewardsInfo:{ String: RewardInfo} ={} 
			for reward in rewards{ 
				let tokenKey = reward.rewardTokenKey
				rewardsInfo[tokenKey] = reward
			}
			let pool <- create Pool(limitAmount: limitAmount, collection: <-collection, rewardsInfo: rewardsInfo, creator: poolAdminAddr, verifiers: verifiers, extraParams: extraParams)
			let newPid = pool.pid
			self.pools[newPid] <-! pool
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int{ 
			return self.pools.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPool(pid: UInt64): &{PoolPublic}{ 
			pre{ 
				self.pools[pid] != nil:
					StakingError.errorEncode(msg: "PoolCollection: cannot find pool by pid", err: StakingError.ErrorCode.INVALID_PARAMETERS)
			}
			let poolRef = (&self.pools[pid] as &Pool?)!
			return poolRef as &{PoolPublic}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedPoolInfo(from: UInt64, to: UInt64): [PoolInfo]{ 
			pre{ 
				from <= to && from < UInt64(self.pools.length):
					StakingError.errorEncode(msg: "from index out of range", err: StakingError.ErrorCode.INVALID_PARAMETERS)
			}
			let poolLen = UInt64(self.pools.length)
			let endIndex = to >= poolLen ? poolLen - 1 : to
			var curIndex = from
			// Array.slice() is not supported yet.
			let list: [PoolInfo] = []
			while curIndex <= endIndex{ 
				let pid = self.pools.keys[curIndex]
				let pool = self.getPool(pid: pid)
				list.append(pool.getPoolInfo())
				curIndex = curIndex + 1
			}
			return list
		}
		
		init(){ 
			self.pools <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun updatePool(pid: UInt64){ 
		let collectionCap =
			StakingNFT.account.capabilities.get<&{StakingNFT.PoolCollectionPublic}>(
				StakingNFT.CollectionPublicPath
			).borrow()
		let pool = (collectionCap!).getPool(pid: pid)
		pool.updatePool()
	}
	
	// setup poolAdmin resource
	access(TMP_ENTITLEMENT_OWNER)
	fun setupPoolAdmin(): @PoolAdmin{ 
		let poolAdmin <- create PoolAdmin()
		return <-poolAdmin
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun setupUser(): @UserCertificate{ 
		let certificate <- create UserCertificate()
		return <-certificate
	}
	
	// get [id] of pools that given user participates
	access(TMP_ENTITLEMENT_OWNER)
	fun getUserStakingIds(address: Address): [UInt64]{ 
		let ids = self.userStakingIds[address]
		if ids == nil{ 
			return []
		} else{ 
			return (ids!).keys
		}
	}
	
	/// "A.2d4c3caffbeab845.FLOAT.Collection" -> "A.2d4c3caffbeab845.FLOAT"
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTType(collectionIdentifier: String): String{ 
		return collectionIdentifier.slice(from: 0, upTo: collectionIdentifier.length - 11)
	}
}
