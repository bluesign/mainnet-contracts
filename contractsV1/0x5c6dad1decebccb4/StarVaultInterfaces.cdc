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

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface StarVaultInterfaces{ 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface VaultPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun vaultId(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun base(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(nfts: @[{NonFungibleToken.NFT}], feeVault: @{FungibleToken.Vault}): @[AnyResource]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun redeem(
			amount: Int,
			vault: @{FungibleToken.Vault},
			specificIds: [
				UInt64
			],
			feeVault: @{FungibleToken.Vault}
		): @[
			AnyResource
		]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun swap(
			nfts: @[{
				NonFungibleToken.NFT}
			],
			specificIds: [
				UInt64
			],
			feeVault: @{FungibleToken.Vault}
		): @[
			AnyResource
		]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVaultTokenType(): Type
		
		access(TMP_ENTITLEMENT_OWNER)
		fun allHoldings(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun totalHoldings(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createEmptyVault(): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun vaultName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun collectionKey(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun totalSupply(): UFix64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface VaultAdmin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setVaultFeatures(
			enableMint: Bool,
			enableRandomRedeem: Bool,
			enableTargetRedeem: Bool,
			enableRandomSwap: Bool,
			enableTargetSwap: Bool
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(amount: UFix64): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setVaultName(vaultName: String)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface VaultTokenCollectionPublicv1{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(vault: Address, tokenVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTokenBalance(vault: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllTokens(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedTokens(from: UInt64, to: UInt64): [Address]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface VaultTokenCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(vault: Address, tokenVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(vault: Address, amount: UFix64): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTokenBalance(vault: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllTokens(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedTokens(from: UInt64, to: UInt64): [Address]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface PoolPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun pid(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stakeToken(): Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun duration(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun periodFinish(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardRate(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lastUpdateTime(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardPerTokenStored(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun queuedRewards(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun currentRewards(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun historicalRewards(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun totalSupply(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun balanceOf(account: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateReward(account: Address?)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lastTimeRewardApplicable(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rewardPerToken(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun earned(account: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReward(account: Address)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun queueNewRewards(vault: @{FungibleToken.Vault})
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface LPStakingCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(tokenAddress: Address, tokenVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTokenBalance(tokenAddress: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllTokens(): [Address]
	}
}
