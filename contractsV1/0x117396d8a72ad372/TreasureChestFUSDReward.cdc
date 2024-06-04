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

	// FUSD Reward for claiming The Inspected Treasure Chest
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NFTDayTreasureChest from "./NFTDayTreasureChest.cdc"

access(all)
contract TreasureChestFUSDReward{ 
	
	// -----------------------------------------------------------------------
	// TreasureChestFUSDReward Events
	// -----------------------------------------------------------------------
	access(all)
	event BonusAdded(wallet: Address, amount: UFix64, bonus: String)
	
	access(all)
	event RewardClaimed(wallet: Address, reward: UFix64)
	
	access(all)
	event AdminRewardReclaim(chestID: UInt64, rewardAmount: UFix64)
	
	access(all)
	event RewardCreated(chestID: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CentralizedInboxStoragePath: StoragePath
	
	access(all)
	let CentralizedInboxPrivatePath: PrivatePath
	
	access(all)
	let CentralizedInboxPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// TreasureChestFUSDReward Fields
	// -----------------------------------------------------------------------
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimed():{ UInt64: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getChestIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBonusRewards():{ Address: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addBonus(wallet: Address, amount: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimReward(
			recipient: &FUSD.Vault,
			chest: @NFTDayTreasureChest.NFT
		): @NFTDayTreasureChest.NFT
	}
	
	access(all)
	resource CentralizedInbox: Public{ 
		// List of claimed chests and which address claimed it
		access(self)
		var claimed:{ UInt64: Address}
		
		// The chest and the vault with the reward amount
		access(self)
		var rewards: @{UInt64: FUSD.Vault}
		
		// List of addresses and their bonus rewards
		access(self)
		var bonusRewards:{ Address: String}
		
		init(){ 
			self.claimed ={} 
			self.rewards <-{} 
			self.bonusRewards ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimed():{ UInt64: Address}{ 
			return self.claimed
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getChestIDs(): [UInt64]{ 
			return self.rewards.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBonusRewards():{ Address: String}{ 
			return self.bonusRewards
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addBonus(wallet: Address, amount: UFix64){ 
			pre{ 
				self.bonusRewards[wallet] == nil:
					"Cannot add bonus: Bonus has already been added"
			}
			var bonus = "Starter Pack"
			if amount == 6.9{ 
				bonus = "Saber Merch"
			}
			if amount == 69.00{ 
				bonus = "Cursed Black Pack"
			}
			self.bonusRewards[wallet] = bonus
			emit BonusAdded(wallet: wallet, amount: amount, bonus: bonus)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimReward(recipient: &FUSD.Vault, chest: @NFTDayTreasureChest.NFT): @NFTDayTreasureChest.NFT{ 
			pre{ 
				self.rewards[chest.id] != nil:
					"Can't claim reward: Chest doesn't have a reward to claim"
				!self.claimed.keys.contains(chest.id):
					"Can't claim reward: Reward from chest has already been claimed"
			}
			let wallet = (recipient.owner!).address
			let vaultRef: &FUSD.Vault = (&self.rewards[chest.id] as &FUSD.Vault?)!
			let amount = vaultRef.balance
			recipient.deposit(from: <-vaultRef.withdraw(amount: vaultRef.balance))
			
			// Add to claimed list
			self.claimed[chest.id] = wallet
			emit RewardClaimed(wallet: wallet, reward: amount)
			return <-chest
		}
		
		// -----------------------------------------------------------------------
		// Admin Functions
		// -----------------------------------------------------------------------
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(chestID: UInt64): UFix64?{ 
			if self.rewards[chestID] != nil{ 
				let vaultRef: &FUSD.Vault = (&self.rewards[chestID] as &FUSD.Vault?)!
				return vaultRef.balance
			} else{ 
				return nil
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun adminReclaimReward(chestID: UInt64, recipient: &FUSD.Vault){ 
			pre{ 
				self.rewards[chestID] != nil:
					"Can't reclaim reward: Chest doesn't have a reward to reclaim"
			}
			let vaultRef: &FUSD.Vault = (&self.rewards[chestID] as &FUSD.Vault?)!
			let amount = vaultRef.balance
			recipient.deposit(from: <-vaultRef.withdraw(amount: vaultRef.balance))
			emit AdminRewardReclaim(chestID: chestID, rewardAmount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createReward(chestID: UInt64, reward: @FUSD.Vault){ 
			pre{ 
				self.rewards[chestID] == nil:
					"Can't create rewards: Reward has already been created"
			}
			self.rewards[chestID] <-! reward
			emit RewardCreated(chestID: chestID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewCentralizedInbox(): @CentralizedInbox{ 
			return <-create CentralizedInbox()
		}
	}
	
	init(){ 
		// Set named paths
		self.CentralizedInboxStoragePath = /storage/BasicBeastsTreasureChestFUSDReward
		self.CentralizedInboxPrivatePath = /private/BasicBeastsTreasureChestFUSDRewardUpgrade
		self.CentralizedInboxPublicPath = /public/BasicBeastsTreasureChestFUSDReward
		
		// Put CentralizedInbox in storage
		self.account.storage.save(<-create CentralizedInbox(), to: self.CentralizedInboxStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&TreasureChestFUSDReward.CentralizedInbox>(
				self.CentralizedInboxStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.CentralizedInboxPrivatePath)
		?? panic("Could not get a capability to the Centralized Inbox")
		var capability_2 =
			self.account.capabilities.storage.issue<&TreasureChestFUSDReward.CentralizedInbox>(
				self.CentralizedInboxStoragePath
			)
		self.account.capabilities.publish(capability_2, at: self.CentralizedInboxPublicPath)
		?? panic("Could not get a capability to the Centralized Inbox")
	}
}
