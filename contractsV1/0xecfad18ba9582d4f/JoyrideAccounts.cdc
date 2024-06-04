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

import JoyrideMultiToken from "./JoyrideMultiToken.cdc"

access(all)
contract JoyrideAccounts{ 
	access(contract)
	var gameToDeveloperAccount:{ String: Address}
	
	access(contract)
	var playerIDToPlayer:{ String: Address}
	
	access(contract)
	var treasuryCapability: Capability<&JoyrideMultiToken.PlatformAdmin>?
	
	access(contract)
	var playerAccounts: @{String: PlayerAccount}
	
	access(contract)
	var playerIdByAddress:{ Address: String}
	
	access(all)
	event AccountCreated(playerID: String, referralID: String?, accountAddress: Address)
	
	access(all)
	event LinkDeveloperAccount(accountAddress: Address, gameID: String)
	
	access(all)
	event AccountAlreadyExists(playerID: String, accountAddress: Address)
	
	access(all)
	event InsufficientBalance(
		playerID: String,
		txID: String,
		amount: UFix64,
		currentBalance: UFix64
	)
	
	init(){ 
		self.playerIDToPlayer ={} 
		self.gameToDeveloperAccount ={} 
		self.playerAccounts <-{} 
		self.treasuryCapability = nil
		self.playerIdByAddress ={} 
		self.account.storage.save(
			<-create JoyrideAccountsAdmin(),
			to: /storage/JoyrideAccountsAdmin
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&JoyrideAccountsAdmin>(
				/storage/JoyrideAccountsAdmin
			)
		self.account.capabilities.publish(capability_1, at: /private/JoyrideAccountsAdmin)
		let cap = capability_1
	}
	
	//Pretty sure this is safe to be public, since a valid Capability<&{JRXToken.Treasury}> can only be created by the JRXToken contract account.
	access(TMP_ENTITLEMENT_OWNER)
	fun linkTreasuryCapability(treasuryCapability: Capability<&JoyrideMultiToken.PlatformAdmin>){ 
		if !treasuryCapability.check(){ 
			panic("Capability from Invalid Source")
		}
		self.treasuryCapability = treasuryCapability
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun PlayerRegisterCapability(capability: Capability<&JoyrideMultiToken.Vault>){ 
		let playerID =
			JoyrideAccounts.playerIdByAddress[capability.address]
			?? panic("PlayerID not Found by Address")
		let playerAccount <-
			JoyrideAccounts.playerAccounts.remove(key: playerID)
			?? panic("PlayerID not found in JoyrideAccounts")
		playerAccount.RegisterVaultCapability(capability: capability)
		destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-playerAccount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayerAccount(playerID: String): &Account{ 
		if self.playerIDToPlayer[playerID] == nil{ 
			panic("Player not found for playerID: ".concat(playerID))
		}
		return getAccount(self.playerIDToPlayer[playerID]!)
	}
	
	access(all)
	resource interface ReceivesPlayerRewards{ 
		access(contract)
		fun ReceiveRewards(totalRewards: UFix64, rewardID: String, tokenContext: String): Bool
	}
	
	access(all)
	resource PlayerAccount: ReceivesPlayerRewards{ 
		access(all)
		let playerID: String
		
		access(all)
		var accountAddress: Address?
		
		access(self)
		var vaultCapability: Capability<&JoyrideMultiToken.Vault>?
		
		init(playerID: String, referralID: String?){ 
			self.playerID = playerID
			self.accountAddress = nil
			self.vaultCapability = nil
		}
		
		access(contract)
		fun ReceiveRewards(totalRewards: UFix64, rewardID: String, tokenContext: String): Bool{ 
			if self.vaultCapability == nil || JoyrideAccounts.treasuryCapability == nil{ 
				return false
			}
			let playerVault = (self.vaultCapability!).borrow()
			let treasury = (JoyrideAccounts.treasuryCapability!).borrow()
			if playerVault == nil || treasury == nil{ 
				return false
			}
			let rewardVault <- (treasury!).withdraw(vault: JoyrideMultiToken.Vaults.treasury, tokenContext: tokenContext, amount: totalRewards, purpose: rewardID)
			if rewardVault == nil{ 
				destroy rewardVault
				return false
			} else{ 
				(playerVault!).depositToken(from: <-rewardVault!)
				return true
			}
		}
		
		//This must be called if the resource is ever transfered to another account.
		access(contract)
		fun AssociatePaymentAddress(address: Address){ 
			JoyrideAccounts.playerIDToPlayer[self.playerID] = address
			self.accountAddress = address
			JoyrideAccounts.playerIdByAddress[address] = self.playerID
		}
		
		access(contract)
		fun WithdrawTokensForPayment(playerID: String, txID: String, amount: UFix64, tokenContext: String): @{FungibleToken.Vault}?{ 
			if self.vaultCapability == nil{ 
				return nil
			}
			let vault = (self.vaultCapability!).borrow()
			if vault == nil{ 
				return nil
			}
			let currentBalance: UFix64 = vault?.balanceOf(tokenContext: tokenContext) ?? 0.0
			if currentBalance < amount{ 
				emit InsufficientBalance(playerID: playerID, txID: txID, amount: amount, currentBalance: currentBalance)
				return nil
			}
			let withdrawal <- vault?.withdrawToken(tokenContext: tokenContext, amount: amount)
			if withdrawal?.balance != amount{ 
				destroy <-withdrawal!
				return nil
			} else{ 
				return <-withdrawal
			}
		}
		
		access(contract)
		fun DepositTokens(vault: @{FungibleToken.Vault}){ 
			let playerVault = (self.vaultCapability ?? panic("No Capability Registered")).borrow() ?? panic("Capability could not be borrowed!")
			playerVault.depositToken(from: <-vault)
		}
		
		access(contract)
		fun RegisterVaultCapability(capability: Capability<&JoyrideMultiToken.Vault>){ 
			if capability.address != self.accountAddress{ 
				panic("Cannot register capability to incorrect address")
			}
			self.vaultCapability = capability
		}
	}
	
	//Rewards and Payments Interfaces
	//
	//
	//
	access(all)
	resource interface GrantsTokenRewards{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun GrantTokenRewards(
			playerID: String,
			amount: UFix64,
			tokenContext: String,
			rewardID: String
		): Bool
	}
	
	access(all)
	resource interface SharesProfits{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun ShareProfits(
			profits: @{FungibleToken.Vault},
			inGameID: String,
			fromPlayerID: String
		): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ShareProfitsWithDevPercentage(
			profits: @{FungibleToken.Vault},
			inGameID: String,
			fromPlayerID: String,
			devPercentage: UFix64
		): @{FungibleToken.Vault}
	}
	
	access(all)
	resource interface PlayerAccounts{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun GetPlayerJRXAccount(playerID: String): &JoyrideAccounts.PlayerAccount?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun AddPlayerAccount(playerID: String, referralID: String?, account: &Account)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun EscrowWithdraw(playerID: String, amount: UFix64, tokenContext: String): @{
			FungibleToken.Vault
		}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun PlayerDeposit(playerID: String, vault: @{FungibleToken.Vault}): @{FungibleToken.Vault}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun AddDeveloperAccount(address: Address, gameID: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun TransferPlayerAccount(playerID: String, to: &Account)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun EscrowWithdrawWithTnxId(
			playerID: String,
			txID: String,
			amount: UFix64,
			tokenContext: String
		): @{FungibleToken.Vault}?
	}
	
	access(all)
	resource JoyrideAccountsAdmin: GrantsTokenRewards, SharesProfits, PlayerAccounts{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun GrantTokenRewards(playerID: String, amount: UFix64, tokenContext: String, rewardID: String): Bool{ 
			let playerAccount <- JoyrideAccounts.playerAccounts.remove(key: playerID)
			if playerAccount == nil{ 
				destroy playerAccount
				return false
			} else{ 
				playerAccount?.ReceiveRewards(totalRewards: amount, rewardID: rewardID, tokenContext: tokenContext)
				destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-playerAccount!)
				return true
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun AddPlayerAccount(playerID: String, referralID: String?, account: &Account){ 
			var checkAccount <- JoyrideAccounts.playerAccounts.remove(key: playerID)
			if checkAccount == nil{ 
				destroy checkAccount
				var playerAccount <- create PlayerAccount(playerID: playerID, referralID: referralID)
				playerAccount.AssociatePaymentAddress(address: account.address)
				destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-playerAccount)
				emit AccountCreated(playerID: playerID, referralID: referralID, accountAddress: account.address)
			} else{ 
				checkAccount?.AssociatePaymentAddress(address: account.address)
				destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-checkAccount!)
				emit AccountAlreadyExists(playerID: playerID, accountAddress: account.address)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun AddDeveloperAccount(address: Address, gameID: String){ 
			JoyrideAccounts.gameToDeveloperAccount[gameID] = address
			emit LinkDeveloperAccount(accountAddress: address, gameID: gameID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun TransferPlayerAccount(playerID: String, to: &Account){ 
			let checkAccount <- JoyrideAccounts.playerAccounts.remove(key: playerID) ?? panic("PlayerID not found!")
			checkAccount.AssociatePaymentAddress(address: to.address)
			destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-checkAccount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun GetPlayerJRXAccount(playerID: String): &PlayerAccount?{ 
			if JoyrideAccounts.playerAccounts.containsKey(playerID){ 
				let playerAccount <- JoyrideAccounts.playerAccounts.remove(key: playerID)!
				let reference = &playerAccount as &PlayerAccount
				destroy JoyrideAccounts.playerAccounts.insert(key: playerID, <-playerAccount)
				return reference
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ShareProfits(profits: @{FungibleToken.Vault}, inGameID: String, fromPlayerID: String): @{FungibleToken.Vault}{ 
			return <-self.ShareProfitsWithDevPercentage(profits: <-profits, inGameID: inGameID, fromPlayerID: fromPlayerID, devPercentage: 0.0)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ShareProfitsWithDevPercentage(profits: @{FungibleToken.Vault}, inGameID: String, fromPlayerID: String, devPercentage: UFix64): @{FungibleToken.Vault}{ 
			let playerAddress = JoyrideAccounts.playerIDToPlayer[fromPlayerID]
			let playerAccount = self.GetPlayerJRXAccount(playerID: fromPlayerID)
			let developerStaking = JoyrideAccounts.gameToDeveloperAccount[inGameID]
			if developerStaking == nil{ 
				return <-profits
			} else{ 
				let vaultCapability = getAccount(developerStaking!).capabilities.get<&{JoyrideMultiToken.Receiver}>(JoyrideMultiToken.UserPublicPath).borrow()
				if vaultCapability == nil{ 
					return <-profits
				} else{ 
					let devShare <- profits.withdraw(amount: profits.balance * devPercentage)
					(vaultCapability!).depositToken(from: <-devShare)
					return <-profits
				}
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun EscrowWithdraw(playerID: String, amount: UFix64, tokenContext: String): @{FungibleToken.Vault}?{ 
			let playerAccount = self.GetPlayerJRXAccount(playerID: playerID)
			if playerAccount == nil{ 
				return nil
			}
			return <-(playerAccount!).WithdrawTokensForPayment(playerID: playerID, txID: "", amount: amount, tokenContext: tokenContext)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun EscrowWithdrawWithTnxId(playerID: String, txID: String, amount: UFix64, tokenContext: String): @{FungibleToken.Vault}?{ 
			let playerAccount = self.GetPlayerJRXAccount(playerID: playerID)
			if playerAccount == nil{ 
				return nil
			}
			return <-(playerAccount!).WithdrawTokensForPayment(playerID: playerID, txID: txID, amount: amount, tokenContext: tokenContext)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun PlayerDeposit(playerID: String, vault: @{FungibleToken.Vault}): @{FungibleToken.Vault}?{ 
			let playerAccount = self.GetPlayerJRXAccount(playerID: playerID)
			if playerAccount != nil{ 
				(playerAccount!).DepositTokens(vault: <-vault)
				return nil
			} else{ 
				return <-vault
			}
		}
	}
	
	access(all)
	struct CreateAccountTransactionData{ 
		access(all)
		var playerID: String
		
		access(all)
		var referralID: String
		
		init(playerID: String, referralID: String){ 
			self.playerID = playerID
			self.referralID = referralID
		}
	}
}
