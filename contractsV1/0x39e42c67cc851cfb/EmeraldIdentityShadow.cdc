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

	// Welcome to the EmeraldIdentity contract!
//
// This contract is a service that maps a user's on-chain 
// SHADOW address to their DiscordID. 
//
// A user cannot configure their own EmeraldID. It must be done 
// by someone who has access to the Administrator resource.
//
// A user can only ever have 1 address mapped to 1 DiscordID, and
// 1 DiscordID mapped to 1 address. This means you cannot configure
// multiple addresses to your DiscordID, and you cannot configure
// multiple DiscordIDs to your address. 1-1.
access(all)
contract EmeraldIdentityShadow{ 
	
	//
	// Paths
	//
	access(all)
	let AdministratorStoragePath: StoragePath
	
	access(all)
	let AdministratorPrivatePath: PrivatePath
	
	//
	// Events
	//
	access(all)
	event EmeraldIDCreated(account: Address, discordID: String)
	
	access(all)
	event EmeraldIDRemoved(account: Address, discordID: String)
	
	//
	// Administrator
	//
	access(all)
	resource Administrator{ 
		// 1-to-1
		access(account)
		var accountToDiscord:{ Address: String}
		
		// 1-to-1
		access(account)
		var discordToAccount:{ String: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createEmeraldID(account: Address, discordID: String){ 
			pre{ 
				EmeraldIdentityShadow.getAccountFromDiscord(discordID: discordID) == nil:
					"The old discordID must remove their EmeraldID first."
				EmeraldIdentityShadow.getDiscordFromAccount(account: account) == nil:
					"The old account must remove their EmeraldID first."
			}
			self.accountToDiscord[account] = discordID
			self.discordToAccount[discordID] = account
			emit EmeraldIDCreated(account: account, discordID: discordID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeByAccount(account: Address){ 
			let discordID =
				EmeraldIdentityShadow.getDiscordFromAccount(account: account)
				?? panic("This EmeraldID does not exist!")
			self.remove(account: account, discordID: discordID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeByDiscord(discordID: String){ 
			let account =
				EmeraldIdentityShadow.getAccountFromDiscord(discordID: discordID)
				?? panic("This EmeraldID does not exist!")
			self.remove(account: account, discordID: discordID)
		}
		
		access(self)
		fun remove(account: Address, discordID: String){ 
			self.discordToAccount.remove(key: discordID)
			self.accountToDiscord.remove(key: account)
			emit EmeraldIDRemoved(account: account, discordID: discordID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdministrator(): Capability<&Administrator>{ 
			return EmeraldIdentityShadow.account.capabilities.get<&Administrator>(
				EmeraldIdentityShadow.AdministratorPrivatePath
			)!
		}
		
		init(){ 
			self.accountToDiscord ={} 
			self.discordToAccount ={} 
		}
	}
	
	/*** USE THE BELOW FUNCTIONS FOR SECURE VERIFICATION OF ID ***/
	access(TMP_ENTITLEMENT_OWNER)
	view fun getDiscordFromAccount(account: Address): String?{ 
		let admin =
			EmeraldIdentityShadow.account.storage.borrow<&Administrator>(
				from: EmeraldIdentityShadow.AdministratorStoragePath
			)!
		return admin.accountToDiscord[account]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getAccountFromDiscord(discordID: String): Address?{ 
		let admin =
			EmeraldIdentityShadow.account.storage.borrow<&Administrator>(
				from: EmeraldIdentityShadow.AdministratorStoragePath
			)!
		return admin.discordToAccount[discordID]
	}
	
	init(){ 
		self.AdministratorStoragePath = /storage/EmeraldIDShadowAdministrator
		self.AdministratorPrivatePath = /private/EmeraldIDShadowAdministrator
		self.account.storage.save(
			<-create Administrator(),
			to: EmeraldIdentityShadow.AdministratorStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&Administrator>(
				EmeraldIdentityShadow.AdministratorStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: EmeraldIdentityShadow.AdministratorPrivatePath
		)
	}
}
