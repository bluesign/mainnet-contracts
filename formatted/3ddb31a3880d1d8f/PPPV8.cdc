/**

# This smart contract is designed for a comprehensive on-chain points system within the Increment.Fi ecosystem.
# It integrates various DeFi infrastructures including Lending, Swap, Liquid Staking, and Farming.

# Author: Increment Labs

*/

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

// Lending
import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

import LendingConfig from "../0x2df970b6cdee5735/LendingConfig.cdc"

// Swap
import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

// Liquid Staking
import LiquidStaking from "../0xd6f80565193ad727/LiquidStaking.cdc"

// Farm
import Staking from "../0x1b77ba4b414de352/Staking.cdc"

import StakingNFT from "../0x1b77ba4b414de352/StakingNFT.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

// Oracle
import PublicPriceOracle from "../0xec67451f8a58216a/PublicPriceOracle.cdc"

// Referral System
import RV3 from "./RV3.cdc"

pub contract PPPV8{ 
    
    // Total supply of points in existence
    pub var _totalSupply: UFix64
    
    // Mapping of user addresses to their base points amount.
    priv let _pointsBase:{ Address: UFix64}
    
    // Snapshot of points for each user at a specific historical moment.
    priv let _pointsHistorySnapshot:{ Address: UFix64}
    
    // Mapping from referrer addresses to the total points they've earned from their referees.
    // {Referrer: TotalPointsFromReferees}
    priv let _totalPointsAsReferrer:{ Address: UFix64}
    
    // {Referrer: {Referee: PointsFrom}}
    priv let _pointsFromReferees:{ Address:{ Address: UFix64}}
    
    // Mapping of user addresses to the points they've boosted as referees.
    priv let _pointsAsReferee:{ Address: UFix64}
    
    // Mapping of user addresses to the points they've boosted as core members of the Increment.
    priv let _pointsAsCoreMember:{ Address: UFix64}
    
    // A blacklist of user addresses that are excluded from earning points.
    priv let _userBlacklist:{ Address: Bool}
    
    // A whitelist of swap pool addresses that are eligible for point earnings.
    priv let _swapPoolWhitelist:{ Address: Bool}
    
    // Configuration for points earning rates based on various criteria such as lending supply, etc.
    /*
            {
                "LendingSupply": {
                    0.0         : 0.001,  //  supply usd amount: 0.0     ~ 1000.0  -> 0.001
                    1000.0      : 0.002,  //  supply usd amount: 1000.0  ~ 10000.0 -> 0.002
                    10000.0     : 0.003   //  supply usd amount: 10000.0 ~ Max     -> 0.003
                }
            }
        */
    
    priv let _pointsRate:{ String: AnyStruct}
    
    // The duration in seconds for each points rate session, affecting how points accumulate over time.
    priv let _secondsPerPointsRateSession: UFix64
    
    // Mapping of user states, storing various metrics such as last update timestamp for points calculation.
    priv let _userStates:{ Address:{ String: UFix64}}
    
    // Indicates whether a user has claimed their points from the historical snapshot.
    priv let _ifClaimHistorySnapshot:{ Address: Bool}
    
    priv var _claimEndTimestamp: UFix64
    
    priv var _pointsMintEndTimestamp: UFix64
    
    // A list of user addresses ranked by their total points, representing the top users.
    priv var _topUsers: [Address]
    
    priv var _lastVolumeAndRefereePointsUpdateTimestamp: UFix64
    
    //
    priv let _reservedFields:{ String: AnyStruct}
    
    /// Events
    pub event PointsMinted(
        userAddr: Address,
        amount: UFix64,
        source: String,
        param:{ 
            String: String
        }
    )
    
    pub event PointsBurned(
        userAddr: Address,
        amount: UFix64,
        source: String,
        param:{ 
            String: String
        }
    )
    
    pub event StateUpdated(userAddr: Address, state:{ String: UFix64})
    
    pub event PointsRateChanged(source: String, ori: UFix64, new: UFix64)
    
    pub event PointsTierRateChanged(
        source: String,
        ori:{ 
            UFix64: UFix64
        },
        new:{ 
            UFix64: UFix64
        }
    )
    
    pub event ClaimSnapshotPoints(userAddr: Address, amount: UFix64)
    
    pub event TopUsersChanged(ori: [Address], new: [Address])
    
    pub event SetSnapshotPoints(userAddr: Address, pre: UFix64, new: UFix64)
    
    // Method to calculate a user's total balance of points.
    pub fun balanceOf(_ userAddr: Address): UFix64{ 
        // Base points plus any unclaimed historical snapshot points, points as referrer, referee, core member,
        // and newly accrued points since the last update.
        return self.getBasePoints(userAddr)
        + (
            self.ifClaimHistorySnapshot(userAddr)
                ? self.getHistorySnapshotPoints(userAddr)
                : 0.0
        )
        + self.getPointsAsReferrer(userAddr)
        + self.getPointsAsReferee(userAddr)
        + self.getPointsAsCoreMember(userAddr)
        + self.calculateNewPointsSinceLastUpdate(userAddr: userAddr)
        * (1.0 + self.getBasePointsBoostRate(userAddr)) // accured points
    }
    
    // Mint Points
    priv fun _mint(targetAddr: Address, amount: UFix64){ 
        if self._userBlacklist.containsKey(targetAddr){ 
            return
        }
        
        // mint points
        if self._pointsBase.containsKey(targetAddr) == false{ 
            self._pointsBase[targetAddr] = 0.0
        }
        self._pointsBase[targetAddr] = self._pointsBase[targetAddr]! + amount
        
        // Attempt to retrieve the referrer address for the target address. If a referrer exists...
        let referrerAddr: Address? =
            RV3.getReferrerByReferee(referee: targetAddr)
        if referrerAddr != nil{ 
            // Calculate and mint referee boost points.
            let boostAmountAsReferee = amount * self.getPointsRate_RefereeUp()
            if boostAmountAsReferee > 0.0{ 
                if self._pointsAsReferee.containsKey(targetAddr) == false{ 
                    self._pointsAsReferee[targetAddr] = boostAmountAsReferee
                } else{ 
                    self._pointsAsReferee[targetAddr] = self._pointsAsReferee[targetAddr]! + boostAmountAsReferee
                }
                emit PointsMinted(userAddr: targetAddr, amount: boostAmountAsReferee, source: "AsReferee", param:{} )
                self._totalSupply = self._totalSupply + boostAmountAsReferee
            }
            
            // Calculate and mint referrer boost points.
            let boostAmountForReferrer = amount * self.getPointsRate_ReferrerUp()
            if boostAmountForReferrer > 0.0 && self._userBlacklist.containsKey(referrerAddr!) == false{ 
                if self._totalPointsAsReferrer.containsKey(referrerAddr!) == false{ 
                    self._totalPointsAsReferrer[referrerAddr!] = boostAmountForReferrer
                } else{ 
                    self._totalPointsAsReferrer[referrerAddr!] = self._totalPointsAsReferrer[referrerAddr!]! + boostAmountForReferrer
                }
                if self._pointsFromReferees.containsKey(referrerAddr!) == false{ 
                    self._pointsFromReferees[referrerAddr!] ={} 
                }
                if (self._pointsFromReferees[referrerAddr!]!).containsKey(targetAddr) == false{ 
                    (self._pointsFromReferees[referrerAddr!]!).insert(key: targetAddr, boostAmountForReferrer)
                } else{ 
                    (self._pointsFromReferees[referrerAddr!]!).insert(key: targetAddr, (self._pointsFromReferees[referrerAddr!]!)[targetAddr]! + boostAmountForReferrer)
                }
                if self._pointsBase.containsKey(referrerAddr!) == false{ 
                    self._pointsBase[referrerAddr!] = 0.0
                }
                emit PointsMinted(userAddr: referrerAddr!, amount: boostAmountForReferrer, source: "AsReferrer", param:{} )
                self._totalSupply = self._totalSupply + boostAmountForReferrer
            }
        }
        
        // Calculate and mint core member boost points if the target address is a core member.
        if self.isCoreMember(targetAddr){ 
            let boostAmountAsCoreMember = amount * self.getPointsRate_CoreMember()
            if boostAmountAsCoreMember > 0.0{ 
                if self._pointsAsCoreMember.containsKey(targetAddr) == false{ 
                    self._pointsAsCoreMember[targetAddr] = boostAmountAsCoreMember
                } else{ 
                    self._pointsAsCoreMember[targetAddr] = self._pointsAsCoreMember[targetAddr]! + boostAmountAsCoreMember
                }
                emit PointsMinted(userAddr: targetAddr, amount: boostAmountAsCoreMember, source: "AsCoreMember", param:{} )
                self._totalSupply = self._totalSupply + boostAmountAsCoreMember
            }
        }
        
        // Update the total supply of points by adding the minted amount.
        self._totalSupply = self._totalSupply + amount
    }
    
    // Function to calculate new points earned by a user since their last update.
    pub fun calculateNewPointsSinceLastUpdate(userAddr: Address): UFix64{ 
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        if lastUpdateTimestamp == 0.0{ 
            return 0.0
        }
        if self._userBlacklist.containsKey(userAddr){ 
            return 0.0
        }
        
        // Lending Supply
        let accuredLendingSupplyPoints =
            self.calculateNewPointsSinceLastUpdate_LendingSupply(
                userAddr: userAddr
            )
        // Lending Borrow
        let accuredLendingBorrowPoints =
            self.calculateNewPointsSinceLastUpdate_LendingBorrow(
                userAddr: userAddr
            )
        // stFlow Holdings
        let accuredStFlowHoldingPoints =
            self.calculateNewPointsSinceLastUpdate_stFlowHolding(
                userAddr: userAddr
            )
        // Swap LP
        let accuredSwapLPPoints =
            self.calculateNewPointsSinceLastUpdate_SwapLP(userAddr: userAddr)
        
        // Sums up the accrued points from all activities, adjusting for any base points boost rate applicable to the user.
        return accuredLendingSupplyPoints + accuredLendingBorrowPoints
        + accuredStFlowHoldingPoints
        + accuredSwapLPPoints
    }
    
    // Updates the state of a user, including their related balance based on DeFi activities.
    pub fun updateUserState(userAddr: Address){ 
        if self._userBlacklist.containsKey(userAddr){ 
            return
        }
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        var curTimestamp =
            getCurrentBlock().timestamp < self._pointsMintEndTimestamp
                ? getCurrentBlock().timestamp
                : self._pointsMintEndTimestamp
        if lastUpdateTimestamp > curTimestamp{ 
            return
        }
        let duration = curTimestamp - lastUpdateTimestamp
        let durationStr = duration.toString()
        if duration > 0.0{ 
            // Calculate new points accrued from lending supply activities.
            let accuredLendingSupplyPoints = self.calculateNewPointsSinceLastUpdate_LendingSupply(userAddr: userAddr)
            if accuredLendingSupplyPoints > 0.0{ 
                emit PointsMinted(userAddr: userAddr, amount: accuredLendingSupplyPoints, source: "LendingSupply", param:{ "SupplyUsdValue": self.getUserState_LendingSupply(userAddr: userAddr).toString(), "Duration": durationStr})
            }
            
            // Similar calculations and event emissions for lending borrow, stFlow holding, and Swap LP activities.
            // Lending Borrow
            let accuredLendingBorrowPoints = self.calculateNewPointsSinceLastUpdate_LendingBorrow(userAddr: userAddr)
            if accuredLendingBorrowPoints > 0.0{ 
                emit PointsMinted(userAddr: userAddr, amount: accuredLendingBorrowPoints, source: "LendingBorrow", param:{ "BorrowUsdValue": self.getUserState_LendingBorrow(userAddr: userAddr).toString(), "Duration": durationStr})
            }
            
            // stFlow Holding
            let accuredStFlowHoldingPoints = self.calculateNewPointsSinceLastUpdate_stFlowHolding(userAddr: userAddr)
            if accuredStFlowHoldingPoints > 0.0{ 
                emit PointsMinted(userAddr: userAddr, amount: accuredStFlowHoldingPoints, source: "stFlowHolding", param:{ "stFlowHoldingBalance": self.getUserState_stFlowHolding(userAddr: userAddr).toString(), "Duration": durationStr})
            }
            
            // Swap LP
            let accuredSwapLPPoints = self.calculateNewPointsSinceLastUpdate_SwapLP(userAddr: userAddr)
            if accuredSwapLPPoints > 0.0{ 
                emit PointsMinted(userAddr: userAddr, amount: accuredSwapLPPoints, source: "SwapLP", param:{ "SwapLPUsdValue": self.getUserState_SwapLPUsd(userAddr: userAddr).toString(), "Duration": durationStr})
            }
            
            // Mint points for the total accrued from all activities.
            let accuredPointsToMint = accuredLendingSupplyPoints + accuredLendingBorrowPoints + accuredStFlowHoldingPoints + accuredSwapLPPoints
            if accuredPointsToMint > 0.0{ 
                self._mint(targetAddr: userAddr, amount: accuredPointsToMint)
            }
        }
        
        // Fetch updated on-chain user states for various DeFi activities.
        let states = self.fetchOnchainUserStates(userAddr: userAddr)
        let totalSupplyAmountInUsd = states[0]
        let totalBorrowAmountInUsd = states[1]
        let stFlowTotalBalance = states[2]
        let totalLpBalanceUsd = states[3]
        let totalLpAmount = states[4]
        
        // Update user states with the latest data.
        if self._userStates.containsKey(userAddr)
        || totalSupplyAmountInUsd > 0.0
        || totalBorrowAmountInUsd > 0.0
        || stFlowTotalBalance > 0.0
        || totalLpBalanceUsd > 0.0{ 
            if self._userStates.containsKey(userAddr) == false{ 
                self._userStates[userAddr] ={} 
            }
            self.setUserState_LendingSupply(
                userAddr: userAddr,
                supplyAmount: totalSupplyAmountInUsd
            )
            self.setUserState_LendingBorrow(
                userAddr: userAddr,
                borrowAmount: totalBorrowAmountInUsd
            )
            self.setUserState_stFlowHolding(
                userAddr: userAddr,
                stFlowBalance: stFlowTotalBalance
            )
            self.setUserState_SwapLPUsd(
                userAddr: userAddr,
                lpUsd: totalLpBalanceUsd
            )
            self.setUserState_SwapLPAmount(
                userAddr: userAddr,
                lpAmount: totalLpAmount
            )
            self.setUserState_LastUpdateTimestamp(
                userAddr: userAddr,
                timestamp: getCurrentBlock().timestamp
            )
            
            //
            emit StateUpdated(
                userAddr: userAddr,
                state: self._userStates[userAddr]!
            )
        }
    }
    
    // Function to fetch and calculate a user's state across different DeFi protocols.
    pub fun fetchOnchainUserStates(userAddr: Address): [UFix64]{ 
        // Oracle Price
        let oraclePrices:{ String: UFix64} ={ // OracleAddress -> Token Price
            
                "Flow":
                PublicPriceOracle.getLatestPrice(
                    oracleAddr: 0xe385412159992e11
                ),
                "stFlow":
                PublicPriceOracle.getLatestPrice(
                    oracleAddr: 0x031dabc5ba1d2932
                ),
                "USDC":
                PublicPriceOracle.getLatestPrice(oracleAddr: 0xf5d12412c09d2470)
            }
        
        // Access the lending comptroller to fetch market addresses and calculate the user's supply and borrow in USD.
        let lendingComptrollerRef =
            getAccount(0xf80cb737bfe7c792).getCapability<
                &{LendingInterfaces.ComptrollerPublic}
            >(LendingConfig.ComptrollerPublicPath).borrow()!
        let marketAddrs: [Address] = lendingComptrollerRef.getAllMarkets()
        let lendingOracleRef =
            getAccount(0x72d3a05910b6ffa3).getCapability<
                &{LendingInterfaces.OraclePublic}
            >(LendingConfig.OraclePublicPath).borrow()!
        var totalSupplyAmountInUsd = 0.0
        var totalBorrowAmountInUsd = 0.0
        for poolAddr in marketAddrs{ 
            let poolRef = lendingComptrollerRef.getPoolPublicRef(poolAddr: poolAddr)
            let poolOraclePrice = lendingOracleRef.getUnderlyingPrice(pool: poolAddr)
            let res: [UInt256; 5] = poolRef.getAccountRealtimeScaled(account: userAddr)
            let supplyAmount = SwapConfig.ScaledUInt256ToUFix64(res[0] * res[1] / SwapConfig.scaleFactor)
            let borrowAmount = SwapConfig.ScaledUInt256ToUFix64(res[2])
            totalSupplyAmountInUsd = totalSupplyAmountInUsd + supplyAmount * poolOraclePrice
            totalBorrowAmountInUsd = totalBorrowAmountInUsd + borrowAmount * poolOraclePrice
        }
        
        // Liquid Staking State
        // Calculate the user's stFlow token balance by checking their vault capability.
        var stFlowTotalBalance = 0.0
        let stFlowVaultCap =
            getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(
                /public/stFlowTokenBalance
            )
        if stFlowVaultCap.check(){ 
            // Prevent fake stFlow token vault
            if (stFlowVaultCap.borrow()!).getType().identifier == "A.d6f80565193ad727.stFlowToken.Vault"{ 
                stFlowTotalBalance = (stFlowVaultCap.borrow()!).balance
            }
        }
        
        // Calculate the user's total LP balance in USD and total LP amount.
        let lpPrices:{ Address: UFix64} ={} 
        var totalLpBalanceUsd = 0.0
        var totalLpAmount = 0.0
        // let lpTokenCollectionCap = getAccount(userAddr).getCapability<&{SwapInterfaces.LpTokenCollectionPublic}>(SwapConfig.LpTokenCollectionPublicPath)
        // if lpTokenCollectionCap.check() {
        //     // Prevent fake lp token vault
        //     if lpTokenCollectionCap.borrow()!.getType().identifier == "A.b063c16cac85dbd1.SwapFactory.LpTokenCollection" {
        //         let lpTokenCollectionRef = lpTokenCollectionCap.borrow()!
        //         let liquidityPairAddrs = lpTokenCollectionRef.getAllLPTokens()
        //         for pairAddr in liquidityPairAddrs {
        //             // 
        //             if self._swapPoolWhitelist.containsKey(pairAddr) == false {
        //                 continue
        //             }
        
        
        //             var lpTokenAmount = lpTokenCollectionRef.getLpTokenBalance(pairAddr: pairAddr)
        //             let pairInfo = getAccount(pairAddr).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!.getPairInfo()
        //             // Cal lp price
        //             var lpPrice = 0.0
        //             if lpPrices.containsKey(pairAddr) {
        //                 lpPrice = lpPrices[pairAddr]!
        //             } else {
        //                 lpPrice = self.calValidLpPrice(pairInfo: pairInfo, oraclePrices: oraclePrices)
        //                 lpPrices[pairAddr] = lpPrice
        //             }
        //             if lpPrice == 0.0 || lpTokenAmount == 0.0 { continue }
        //             totalLpBalanceUsd = totalLpBalanceUsd + lpPrice * lpTokenAmount
        //             totalLpAmount = totalLpAmount + lpTokenAmount
        //         }
        //     }
        // }
        
        
        // Swap LP in Farm & stFlow in Farm
        let farmCollectionRef =
            getAccount(0x1b77ba4b414de352).getCapability<
                &{Staking.PoolCollectionPublic}
            >(Staking.CollectionPublicPath).borrow()!
        let userFarmIds = Staking.getUserStakingIds(address: userAddr)
        for farmPoolId in userFarmIds{ 
            let farmPool = farmCollectionRef.getPool(pid: farmPoolId)
            let farmPoolInfo = farmPool.getPoolInfo()
            let userInfo = farmPool.getUserInfo(address: userAddr)!
            if farmPoolInfo.status == "0" || farmPoolInfo.status == "1" || farmPoolInfo.status == "2"{ 
                let acceptTokenKey = farmPoolInfo.acceptTokenKey
                let acceptTokenName = acceptTokenKey.slice(from: 19, upTo: acceptTokenKey.length)
                let userFarmAmount = userInfo.stakingAmount
                // add stFlow holding balance
                if acceptTokenKey == "A.d6f80565193ad727.stFlowToken"{ 
                    stFlowTotalBalance = stFlowTotalBalance + userFarmAmount
                    continue
                }
                if userFarmAmount == 0.0{ 
                    continue
                }
                // add lp holding balance
                let swapPoolAddress = self.type2address(acceptTokenKey)
                if self._swapPoolWhitelist.containsKey(swapPoolAddress) == false{ 
                    continue
                }
                if acceptTokenName == "SwapPair"{ 
                    let swapPoolInfo = (getAccount(swapPoolAddress).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!).getPairInfo()
                    var lpPrice = 0.0
                    if lpPrices.containsKey(swapPoolAddress){ 
                        lpPrice = lpPrices[swapPoolAddress]!
                    } else{ 
                        lpPrice = self.calValidLpPrice(pairInfo: swapPoolInfo, oraclePrices: oraclePrices)
                        lpPrices[swapPoolAddress] = lpPrice
                    }
                    totalLpBalanceUsd = totalLpBalanceUsd + userFarmAmount * lpPrice
                    totalLpAmount = totalLpAmount + userFarmAmount
                }
            }
        }
        return [
            totalSupplyAmountInUsd,
            totalBorrowAmountInUsd,
            stFlowTotalBalance,
            totalLpBalanceUsd,
            totalLpAmount
        ]
    }
    
    pub fun claimSnapshotPoints(
        userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>
    ){ 
        pre{ 
            self._claimEndTimestamp > getCurrentBlock().timestamp:
                "The claim period has concluded."
        }
        let userAddr: Address = ((userCertificateCap.borrow()!).owner!).address
        assert(
            self.getHistorySnapshotPoints(userAddr) > 0.0,
            message: "Nothing to claim"
        )
        self._ifClaimHistorySnapshot[userAddr] = true
        emit ClaimSnapshotPoints(
            userAddr: userAddr,
            amount: self.getHistorySnapshotPoints(userAddr)
        )
    }
    
    pub fun getBasePointsLength(): Int{ 
        return self._pointsBase.length
    }
    
    pub fun getSlicedBasePointsAddrs(from: Int, to: Int): [Address]{ 
        let len = self._userStates.length
        let endIndex = to > len ? len : to
        var curIndex = from
        return self._pointsBase.keys.slice(from: from, upTo: to)
    }
    
    pub fun getBasePoints(_ userAddr: Address): UFix64{ 
        return self._pointsBase.containsKey(userAddr)
            ? self._pointsBase[userAddr]!
            : 0.0
    }
    
    pub fun getHistorySnapshotPoints(_ userAddr: Address): UFix64{ 
        return self._pointsHistorySnapshot.containsKey(userAddr)
            ? self._pointsHistorySnapshot[userAddr]!
            : 0.0
    }
    
    pub fun getPointsAsReferrer(_ userAddr: Address): UFix64{ 
        return self._totalPointsAsReferrer.containsKey(userAddr)
            ? self._totalPointsAsReferrer[userAddr]!
            : 0.0
    }
    
    pub fun getPointsAsReferee(_ userAddr: Address): UFix64{ 
        return self._pointsAsReferee.containsKey(userAddr)
            ? self._pointsAsReferee[userAddr]!
            : 0.0
    }
    
    pub fun getLastestPointsAsReferee(_ userAddr: Address): UFix64{ 
        let referrerAddr = RV3.getReferrerByReferee(referee: userAddr)
        let lastUpdatePointsAsReferee = self.getPointsAsReferee(userAddr)
        let latestPointsAsReferee =
            (referrerAddr != nil ? self.getPointsRate_RefereeUp() : 0.0)
            * self.calculateNewPointsSinceLastUpdate(userAddr: userAddr)
        return lastUpdatePointsAsReferee + latestPointsAsReferee
    }
    
    pub fun getPointsAsCoreMember(_ userAddr: Address): UFix64{ 
        return self._pointsAsCoreMember.containsKey(userAddr)
            ? self._pointsAsCoreMember[userAddr]!
            : 0.0
    }
    
    pub fun getLastestPointsAsCoreMember(_ userAddr: Address): UFix64{ 
        let lastUpdatePointsAsCoreMember = self.getPointsAsCoreMember(userAddr)
        let latestPointsAsCoreMember =
            (
                self.isCoreMember(userAddr)
                    ? self.getPointsRate_CoreMember()
                    : 0.0
            )
            * self.calculateNewPointsSinceLastUpdate(userAddr: userAddr)
        return lastUpdatePointsAsCoreMember + latestPointsAsCoreMember
    }
    
    pub fun getPointsAndTimestamp(_ userAddr: Address): [UFix64; 3]{ 
        return [
            self.balanceOf(userAddr),
            self.getPointsAsReferrer(userAddr),
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        ]
    }
    
    pub fun getUserInfo(_ userAddr: Address): [UFix64]{ 
        return [
            self.balanceOf(userAddr),
            self.getPointsAsReferrer(userAddr),
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr),
            self.getUserState_LendingSupply(userAddr: userAddr),
            self.getUserState_LendingBorrow(userAddr: userAddr),
            self.getUserState_stFlowHolding(userAddr: userAddr),
            self.getUserState_SwapLPUsd(userAddr: userAddr),
            self.getUserState_SwapVolume(userAddr: userAddr)
        ]
    }
    
    pub fun getUserInfosLength(): Int{ 
        return self._userStates.length
    }
    
    pub fun getSlicedUserInfos(from: Int, to: Int):{ Address: [UFix64]}{ 
        let len = self._userStates.length
        let endIndex = to > len ? len : to
        var curIndex = from
        let res:{ Address: [UFix64]} ={} 
        while curIndex < endIndex{ 
            let userAddr: Address = self._userStates.keys[curIndex]
            res[userAddr] = self.getUserInfo(userAddr)
            curIndex = curIndex + 1
        }
        return res
    }
    
    pub fun isCoreMember(_ userAddr: Address): Bool{ 
        let coreMemberEventID: UInt64 = 326723707
        let floatCollection =
            getAccount(userAddr).getCapability(FLOAT.FLOATCollectionPublicPath)
                .borrow<&FLOAT.Collection{FLOAT.CollectionPublic}>()
        if floatCollection == nil{ 
            return false
        }
        let nftID: [UInt64] =
            (floatCollection!).ownedIdsFromEvent(eventId: coreMemberEventID)
        if (floatCollection!).getType().identifier
        == "A.2d4c3caffbeab845.FLOAT.Collection"
        && nftID.length > 0{ 
            return true
        }
        let poolCollectionCap =
            getAccount(StakingNFT.address).getCapability<
                &{StakingNFT.PoolCollectionPublic}
            >(StakingNFT.CollectionPublicPath).borrow()!
        let count = StakingNFT.poolCount
        var idx: UInt64 = 0
        while idx < count{ 
            let pool = poolCollectionCap.getPool(pid: idx)
            let poolExtraParams = pool.getExtraParams()
            if poolExtraParams.containsKey("eventId") && poolExtraParams["eventId"]! as! UInt64 == coreMemberEventID{ 
                let userInfo = pool.getUserInfo(address: userAddr)
                if userInfo != nil && (userInfo!).stakedNftIds.length > 0{ 
                    return true
                }
            }
            idx = idx + 1
        }
        return false
    }
    
    pub fun ifClaimHistorySnapshot(_ userAddr: Address): Bool{ 
        if self._ifClaimHistorySnapshot.containsKey(userAddr) == true{ 
            return self._ifClaimHistorySnapshot[userAddr]!
        }
        return false
    }
    
    pub fun getBasePointsBoostRate(_ userAddr: Address): UFix64{ 
        let referrerAddr = RV3.getReferrerByReferee(referee: userAddr)
        return (
            self.isCoreMember(userAddr) ? self.getPointsRate_CoreMember() : 0.0
        )
        + (referrerAddr != nil ? self.getPointsRate_RefereeUp() : 0.0)
    }
    
    // Accure Lending Supply
    pub fun calculateNewPointsSinceLastUpdate_LendingSupply(
        userAddr: Address
    ): UFix64{ 
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        var accuredPoints = 0.0
        if lastUpdateTimestamp == 0.0{ 
            return 0.0
        }
        let currUpdateTimestamp =
            getCurrentBlock().timestamp < self._pointsMintEndTimestamp
                ? getCurrentBlock().timestamp
                : self._pointsMintEndTimestamp
        let duration = currUpdateTimestamp - lastUpdateTimestamp
        if duration > 0.0{ 
            let supplyAmountUsd = self.getUserState_LendingSupply(userAddr: userAddr)
            accuredPoints = supplyAmountUsd * self.getPointsRate_LendingSupply(amount: supplyAmountUsd) / self._secondsPerPointsRateSession * duration
        }
        return accuredPoints
    }
    
    // Accure Lending Borrow
    pub fun calculateNewPointsSinceLastUpdate_LendingBorrow(
        userAddr: Address
    ): UFix64{ 
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        var accuredPoints = 0.0
        if lastUpdateTimestamp == 0.0{ 
            return 0.0
        }
        let currUpdateTimestamp =
            getCurrentBlock().timestamp < self._pointsMintEndTimestamp
                ? getCurrentBlock().timestamp
                : self._pointsMintEndTimestamp
        let duration = currUpdateTimestamp - lastUpdateTimestamp
        if duration > 0.0{ 
            let borrowAmountUsd = self.getUserState_LendingBorrow(userAddr: userAddr)
            accuredPoints = borrowAmountUsd * self.getPointsRate_LendingBorrow(amount: borrowAmountUsd) / self._secondsPerPointsRateSession * duration
        }
        return accuredPoints
    }
    
    // Accure Liquid Staking - stFlowHolding
    priv fun calculateNewPointsSinceLastUpdate_stFlowHolding(
        userAddr: Address
    ): UFix64{ 
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        var accuredPoints = 0.0
        if lastUpdateTimestamp == 0.0{ 
            return 0.0
        }
        let currUpdateTimestamp =
            getCurrentBlock().timestamp < self._pointsMintEndTimestamp
                ? getCurrentBlock().timestamp
                : self._pointsMintEndTimestamp
        let duration = currUpdateTimestamp - lastUpdateTimestamp
        if duration > 0.0{ 
            let stFlowHolding = self.getUserState_stFlowHolding(userAddr: userAddr)
            accuredPoints = stFlowHolding * self.getPointsRate_stFlowHolding(amount: stFlowHolding) / self._secondsPerPointsRateSession * duration
        }
        return accuredPoints
    }
    
    // Accure Swap LP
    priv fun calculateNewPointsSinceLastUpdate_SwapLP(
        userAddr: Address
    ): UFix64{ 
        let lastUpdateTimestamp =
            self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
        var accuredPoints = 0.0
        if lastUpdateTimestamp == 0.0{ 
            return 0.0
        }
        let currUpdateTimestamp =
            getCurrentBlock().timestamp < self._pointsMintEndTimestamp
                ? getCurrentBlock().timestamp
                : self._pointsMintEndTimestamp
        let duration = currUpdateTimestamp - lastUpdateTimestamp
        if duration > 0.0{ 
            let swapLP = self.getUserState_SwapLPUsd(userAddr: userAddr)
            accuredPoints = swapLP * self.getPointsRate_SwapLP(amount: swapLP) / self._secondsPerPointsRateSession * duration
        }
        return accuredPoints
    }
    
    pub fun getTopUsers(): [Address]{ 
        return self._topUsers
    }
    
    pub fun getSwapPoolWhiltlist():{ Address: Bool}{ 
        return self._swapPoolWhitelist
    }
    
    pub fun getUserBlacklist():{ Address: Bool}{ 
        return self._userBlacklist
    }
    
    // Get Points Rate
    pub fun getPointsRate():{ String: AnyStruct}{ 
        return self._pointsRate
    }
    
    pub fun getPointsRate_LendingSupply(amount: UFix64): UFix64{ 
        return self.calculateTierRateByAmount(
            amount: amount,
            tier: self._pointsRate["LendingSupply"]! as!{ UFix64: UFix64}
        )
    }
    
    pub fun getPointsRate_LendingBorrow(amount: UFix64): UFix64{ 
        return self.calculateTierRateByAmount(
            amount: amount,
            tier: self._pointsRate["LendingBorrow"]! as!{ UFix64: UFix64}
        )
    }
    
    pub fun getPointsRate_stFlowHolding(amount: UFix64): UFix64{ 
        return self.calculateTierRateByAmount(
            amount: amount,
            tier: self._pointsRate["stFlowHolding"]! as!{ UFix64: UFix64}
        )
    }
    
    pub fun getPointsRate_SwapLP(amount: UFix64): UFix64{ 
        return self.calculateTierRateByAmount(
            amount: amount,
            tier: self._pointsRate["SwapLP"]! as!{ UFix64: UFix64}
        )
    }
    
    pub fun getPointsRate_SwapVolume(amount: UFix64): UFix64{ 
        return self.calculateTierRateByAmount(
            amount: amount,
            tier: self._pointsRate["SwapVolume"]! as!{ UFix64: UFix64}
        )
    }
    
    pub fun getPointsRate_ReferrerUp(): UFix64{ 
        return self._pointsRate["ReferrerUp"]! as! UFix64
    }
    
    pub fun getPointsRate_RefereeUp(): UFix64{ 
        return self._pointsRate["RefereeUp"]! as! UFix64
    }
    
    pub fun getPointsRate_CoreMember(): UFix64{ 
        return self._pointsRate["CoreMember"]! as! UFix64
    }
    
    // Get User State
    pub fun getUserState(userAddr: Address):{ String: UFix64}{ 
        return self._userStates.containsKey(userAddr)
            ? self._userStates[userAddr]!
            :{} 
    }
    
    pub fun getUserState_LastUpdateTimestamp(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey(
                        "LastUpdateTimestamp"
                    )
                        ? (self._userStates[userAddr]!)["LastUpdateTimestamp"]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_LendingSupply(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey(
                        "LendingTotalSupplyUsd"
                    )
                        ? (self._userStates[userAddr]!)[
                                "LendingTotalSupplyUsd"
                            ]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_LendingBorrow(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey(
                        "LendingTotalBorrowUsd"
                    )
                        ? (self._userStates[userAddr]!)[
                                "LendingTotalBorrowUsd"
                            ]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_stFlowHolding(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey("stFlowHolding")
                        ? (self._userStates[userAddr]!)["stFlowHolding"]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_SwapLPUsd(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey("SwapLpUsd")
                        ? (self._userStates[userAddr]!)["SwapLpUsd"]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_SwapLPAmount(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey("SwapLpAmount")
                        ? (self._userStates[userAddr]!)["SwapLpAmount"]!
                        : 0.0
                )
            : 0.0
    }
    
    pub fun getUserState_SwapVolume(userAddr: Address): UFix64{ 
        return self._userStates.containsKey(userAddr)
            ? (
                    (self._userStates[userAddr]!).containsKey("SwapVolumeUsd")
                        ? (self._userStates[userAddr]!)["SwapVolumeUsd"]!
                        : 0.0
                )
            : 0.0
    }
    
    priv fun setUserState_LastUpdateTimestamp(
        userAddr: Address,
        timestamp: UFix64
    ){ 
        (self._userStates[userAddr]!).insert(
            key: "LastUpdateTimestamp",
            timestamp
        )
    }
    
    priv fun setUserState_LendingSupply(
        userAddr: Address,
        supplyAmount: UFix64
    ){ 
        (self._userStates[userAddr]!).insert(
            key: "LendingTotalSupplyUsd",
            supplyAmount
        )
    }
    
    priv fun setUserState_LendingBorrow(
        userAddr: Address,
        borrowAmount: UFix64
    ){ 
        (self._userStates[userAddr]!).insert(
            key: "LendingTotalBorrowUsd",
            borrowAmount
        )
    }
    
    priv fun setUserState_stFlowHolding(
        userAddr: Address,
        stFlowBalance: UFix64
    ){ 
        (self._userStates[userAddr]!).insert(
            key: "stFlowHolding",
            stFlowBalance
        )
    }
    
    priv fun setUserState_SwapLPUsd(userAddr: Address, lpUsd: UFix64){ 
        (self._userStates[userAddr]!).insert(key: "SwapLpUsd", lpUsd)
    }
    
    priv fun setUserState_SwapLPAmount(userAddr: Address, lpAmount: UFix64){ 
        (self._userStates[userAddr]!).insert(key: "SwapLpAmount", lpAmount)
    }
    
    priv fun setUserState_SwapVolume(userAddr: Address, volume: UFix64){ 
        (self._userStates[userAddr]!).insert(key: "SwapVolumeUsd", volume)
    }
    
    pub fun calculateTierRateByAmount(
        amount: UFix64,
        tier:{ 
            UFix64: UFix64
        }
    ): UFix64{ 
        var rate = 0.0
        var maxThreshold = 0.0
        for threshold in tier.keys{ 
            if amount >= threshold && threshold >= maxThreshold{ 
                rate = tier[threshold]!
                maxThreshold = threshold
            }
        }
        return rate
    }
    
    // Calculates the price of an LP token based on the reserves of the pair and the current prices of the underlying tokens.
    pub fun calValidLpPrice(
        pairInfo: [
            AnyStruct
        ],
        oraclePrices:{ 
            String: UFix64
        }
    ): UFix64{ 
        var reserveAmount = 0.0
        var reservePrice = 0.0
        var lpPrice = 0.0
        if pairInfo[0] as! String == "A.b19436aae4d94622.FiatToken"{ 
            reserveAmount = pairInfo[2] as! UFix64
            reservePrice = oraclePrices["USDC"]!
        } else if pairInfo[1] as! String == "A.b19436aae4d94622.FiatToken"{ 
            reserveAmount = pairInfo[3] as! UFix64
            reservePrice = oraclePrices["USDC"]!
        } else if pairInfo[0] as! String == "A.1654653399040a61.FlowToken"{ 
            reserveAmount = pairInfo[2] as! UFix64
            reservePrice = oraclePrices["Flow"]!
        } else if pairInfo[1] as! String == "A.1654653399040a61.FlowToken"{ 
            reserveAmount = pairInfo[3] as! UFix64
            reservePrice = oraclePrices["Flow"]!
        } else if pairInfo[0] as! String == "A.d6f80565193ad727.stFlowToken"{ 
            reserveAmount = pairInfo[2] as! UFix64
            reservePrice = oraclePrices["stFlow"]!
        } else if pairInfo[1] as! String == "A.d6f80565193ad727.stFlowToken"{ 
            reserveAmount = pairInfo[3] as! UFix64
            reservePrice = oraclePrices["stFlow"]!
        }
        if reservePrice > 0.0 && reserveAmount > 1000.0{ 
            lpPrice = reserveAmount * reservePrice * 2.0 / pairInfo[5] as! UFix64
        }
        return lpPrice
    }
    
    // A.0xabc.Toke -> 0xabc
    pub fun type2address(_ type: String): Address{ 
        let address = type.slice(from: 2, upTo: 18)
        var r: UInt64 = 0
        var bytes = address.decodeHex()
        while bytes.length > 0{ 
            r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
        }
        return Address(r)
    }
    
    pub fun getClaimEndTimestamp(): UFix64{ 
        return self._claimEndTimestamp
    }
    
    pub fun getPointsMintEndTimestamp(): UFix64{ 
        return self._pointsMintEndTimestamp
    }
    
    pub fun getLastVolumeAndRefereePointsUpdateTimestamp(): UFix64{ 
        return self._lastVolumeAndRefereePointsUpdateTimestamp
    }
    
    /// Admin
    ///
    pub resource Admin{ 
        pub            // Set Points Rate
            fun setPointsRate_stFlowHoldingTier(tierRate:{ UFix64: UFix64}){ 
            emit PointsTierRateChanged(
                source: "stFlowHolding",
                ori: PPPV8._pointsRate["stFlowHolding"]! as!{ UFix64: UFix64},
                new: tierRate
            )
            PPPV8._pointsRate["stFlowHolding"] = tierRate
        }
        
        pub fun setPointsRate_LendingSupplyTier(tierRate:{ UFix64: UFix64}){ 
            emit PointsTierRateChanged(
                source: "LendingSupply",
                ori: PPPV8._pointsRate["LendingSupply"]! as!{ UFix64: UFix64},
                new: tierRate
            )
            PPPV8._pointsRate["LendingSupply"] = tierRate
        }
        
        pub fun setPointsRate_LendingBorrowTier(tierRate:{ UFix64: UFix64}){ 
            emit PointsTierRateChanged(
                source: "LendingBorrow",
                ori: PPPV8._pointsRate["LendingBorrow"]! as!{ UFix64: UFix64},
                new: tierRate
            )
            PPPV8._pointsRate["LendingBorrow"] = tierRate
        }
        
        pub fun setPointsRate_SwapLPTier(tierRate:{ UFix64: UFix64}){ 
            emit PointsTierRateChanged(
                source: "SwapLP",
                ori: PPPV8._pointsRate["SwapLP"]! as!{ UFix64: UFix64},
                new: tierRate
            )
            PPPV8._pointsRate["SwapLP"] = tierRate
        }
        
        pub fun setPointsRate_SwapVolumeTier(tierRate:{ UFix64: UFix64}){ 
            emit PointsTierRateChanged(
                source: "SwapVolume",
                ori: PPPV8._pointsRate["SwapVolume"]! as!{ UFix64: UFix64},
                new: tierRate
            )
            PPPV8._pointsRate["SwapVolume"] = tierRate
        }
        
        pub fun setPointsRate_ReferrerUp(rate: UFix64){ 
            emit PointsRateChanged(
                source: "ReferrerUp",
                ori: PPPV8._pointsRate["ReferrerUp"]! as! UFix64,
                new: rate
            )
            PPPV8._pointsRate["ReferrerUp"] = rate
        }
        
        pub fun setPointsRate_RefereeUp(rate: UFix64){ 
            emit PointsRateChanged(
                source: "RefereeUp",
                ori: PPPV8._pointsRate["RefereeUp"]! as! UFix64,
                new: rate
            )
            PPPV8._pointsRate["RefereeUp"] = rate
        }
        
        pub fun setPointsRate_CoreMember(rate: UFix64){ 
            emit PointsRateChanged(
                source: "CoreMember",
                ori: PPPV8._pointsRate["CoreMember"]! as! UFix64,
                new: rate
            )
            PPPV8._pointsRate["CoreMember"] = rate
        }
        
        // Add Swap Pool in Whiltelist
        pub fun addSwapPoolInWhiltelist(poolAddr: Address){ 
            PPPV8._swapPoolWhitelist[poolAddr] = true
        }
        
        // Remove Swap Pool in Whitelist
        pub fun removeSwapPoolInWhiltelist(poolAddr: Address){ 
            PPPV8._swapPoolWhitelist.remove(key: poolAddr)
        }
        
        // Set history snapshot points
        pub fun setHistorySnapshotPoints(
            userAddr: Address,
            newSnapshotBalance: UFix64
        ){ 
            if PPPV8._pointsHistorySnapshot.containsKey(userAddr) == false{ 
                PPPV8._pointsHistorySnapshot[userAddr] = 0.0
            }
            if PPPV8._pointsBase.containsKey(userAddr) == false{ 
                PPPV8._pointsBase[userAddr] = 0.0
            }
            let preSnapshotBalance = PPPV8._pointsHistorySnapshot[userAddr]!
            emit SetSnapshotPoints(
                userAddr: userAddr,
                pre: preSnapshotBalance,
                new: newSnapshotBalance
            )
            if preSnapshotBalance == newSnapshotBalance{ 
                return
            }
            if preSnapshotBalance < newSnapshotBalance{ 
                emit PointsMinted(userAddr: userAddr, amount: newSnapshotBalance - preSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
            } else{ 
                emit PointsBurned(userAddr: userAddr, amount: preSnapshotBalance - newSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
            }
            PPPV8._totalSupply = PPPV8._totalSupply - preSnapshotBalance
                + newSnapshotBalance
            PPPV8._pointsHistorySnapshot[userAddr] = newSnapshotBalance
        }
        
        pub fun setClaimEndTimestamp(endTime: UFix64){ 
            PPPV8._claimEndTimestamp = endTime
        }
        
        pub fun setPointsMintEndTimestamp(endTime: UFix64){ 
            PPPV8._pointsMintEndTimestamp = endTime
        }
        
        // Ban user
        pub fun addUserBlackList(userAddr: Address){ 
            PPPV8._userBlacklist[userAddr] = true
        }
        
        pub fun removeUserBlackList(userAddr: Address){ 
            PPPV8._userBlacklist.remove(key: userAddr)
        }
        
        pub fun addVolumePoints(
            userAddr: Address,
            volumePoints: UFix64,
            volumeUsd: UFix64
        ){ 
            PPPV8._mint(targetAddr: userAddr, amount: volumePoints)
            if PPPV8._userStates.containsKey(userAddr) == false{ 
                PPPV8._userStates[userAddr] ={} 
            }
            PPPV8.setUserState_SwapVolume(
                userAddr: userAddr,
                volume: PPPV8.getUserState_SwapVolume(userAddr: userAddr)
                + volumeUsd
            )
            emit PointsMinted(
                userAddr: userAddr,
                amount: volumePoints,
                source: "SwapVolume",
                param:{ "VolumeUsd": volumeUsd.toString()}
            )
            emit StateUpdated(
                userAddr: userAddr,
                state: PPPV8._userStates[userAddr]!
            )
        }
        
        pub fun setLastVolumeAndRefereePointsUpdateTimestamp(
            timestamp: UFix64
        ){ 
            PPPV8._lastVolumeAndRefereePointsUpdateTimestamp = timestamp
        }
        
        pub fun reconcileBasePoints(userAddr: Address, newBasePoints: UFix64){ 
            if PPPV8._pointsBase.containsKey(userAddr) == false{ 
                PPPV8._pointsBase[userAddr] = 0.0
            }
            let preBasePoints = PPPV8._pointsBase[userAddr]!
            if preBasePoints == newBasePoints{ 
                return
            }
            if preBasePoints < newBasePoints{ 
                emit PointsMinted(userAddr: userAddr, amount: newBasePoints - preBasePoints, source: "Reconcile", param:{ "PreBaseBalance": preBasePoints.toString(), "NewBaseBalance": newBasePoints.toString()})
            } else{ 
                emit PointsBurned(userAddr: userAddr, amount: preBasePoints - newBasePoints, source: "Reconcile", param:{ "PreBaseBalance": preBasePoints.toString(), "NewBaseBalance": newBasePoints.toString()})
            }
            PPPV8._totalSupply = PPPV8._totalSupply - preBasePoints
                + newBasePoints
            PPPV8._pointsBase[userAddr] = newBasePoints
        }
        
        pub fun updateTopUsers(addrs: [Address]){ 
            emit TopUsersChanged(ori: PPPV8._topUsers, new: addrs)
            PPPV8._topUsers = addrs
        }
    }
    
    init(){ 
        self._totalSupply = 0.0
        self._secondsPerPointsRateSession = 3600.0
        self._pointsBase ={} 
        self._pointsHistorySnapshot ={} 
        self._totalPointsAsReferrer ={} 
        self._pointsFromReferees ={} 
        self._pointsAsReferee ={} 
        self._pointsAsCoreMember ={} 
        self._topUsers = []
        self._pointsRate ={ 
                "stFlowHolding":{ 0.0: 0.0, 1.0: 0.001},
                "LendingSupply":{ 0.0: 0.0, 1.0: 0.0001},
                "LendingBorrow":{ 0.0: 0.0, 1.0: 0.0005},
                "SwapLP":{ 0.0: 0.0, 1.0: 0.00125},
                "SwapVolume":{ 0.0: 0.0, 1.0: 0.001},
                "ReferrerUp": 0.05,
                "RefereeUp": 0.05,
                "CoreMember": 0.2
            }
        self._swapPoolWhitelist ={ 
                0xfa82796435e15832: true, // Flow-USDC
                0xc353b9d685ec427d: true, // FLOW-stFLOW stable
                0xa06c38beec9cf0e8: true, // FLOW-DUST
                0xbfb26bb8adf90399: true // FLOW-SLOPPY
            }
        self._userStates ={} 
        self._userBlacklist ={} 
        self._ifClaimHistorySnapshot ={} 
        self._claimEndTimestamp = getCurrentBlock().timestamp + 86400.0 * 60.0
        self._pointsMintEndTimestamp = getCurrentBlock().timestamp
            + 86400.0 * 365.0
        self._lastVolumeAndRefereePointsUpdateTimestamp = getCurrentBlock()
                .timestamp
            + 1.0
        self._reservedFields ={} 
        destroy <-self.account.load<@AnyResource>(from: /storage/pointsAdmin)
        self.account.save(<-create Admin(), to: /storage/pointsAdmin)
    }
}
