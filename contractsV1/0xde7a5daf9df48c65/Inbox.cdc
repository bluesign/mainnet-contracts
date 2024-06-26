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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Pack from "./Pack.cdc"

// Purpose: This Inbox contract allows the admin to send pack NFTs to a centralized inbox held by the admin.
// This allows the recipients to claim their packs at any time.
access(all)
contract Inbox{ 
	
	// -----------------------------------------------------------------------
	// Inbox Events
	// -----------------------------------------------------------------------
	access(all)
	event MailClaimed(address: Address, packID: UInt64)
	
	access(all)
	event PackMailCreated(address: Address, packIDs: [UInt64])
	
	access(all)
	event MailAdminClaimed(wallet: Address, packID: UInt64)
	
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
	// Inbox Fields
	// -----------------------------------------------------------------------
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddresses(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(wallet: Address): [UInt64]?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(wallet: Address, id: UInt64): &Pack.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimMail(recipient: &{NonFungibleToken.Receiver}, id: UInt64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMailsLength(): Int
	}
	
	access(all)
	resource CentralizedInbox: Public{ 
		access(self)
		var mails: @{Address: Pack.Collection}
		
		init(){ 
			self.mails <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddresses(): [Address]{ 
			return self.mails.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(wallet: Address): [UInt64]?{ 
			if self.mails[wallet] != nil{ 
				let collectionRef = (&self.mails[wallet] as &Pack.Collection?)!
				return collectionRef.getIDs()
			} else{ 
				return nil
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(wallet: Address, id: UInt64): &Pack.NFT?{ 
			let collectionRef = (&self.mails[wallet] as &Pack.Collection?)!
			return collectionRef.borrowPack(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claimMail(recipient: &{NonFungibleToken.Receiver}, id: UInt64){ 
			let wallet = (recipient.owner!).address
			if self.mails[wallet] != nil{ 
				let collectionRef = (&self.mails[wallet] as &Pack.Collection?)!
				recipient.deposit(token: <-collectionRef.withdraw(withdrawID: id))
			}
			emit MailClaimed(address: wallet, packID: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMailsLength(): Int{ 
			return self.mails.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createPackMail(wallet: Address, packs: @Pack.Collection){ 
			let IDs = packs.getIDs()
			if self.mails[wallet] == nil{ 
				self.mails[wallet] <-! Pack.createEmptyCollection(nftType: Type<@Pack.Collection>()) as! @Pack.Collection
			}
			let collectionRef = (&self.mails[wallet] as &Pack.Collection?)!
			for id in IDs{ 
				collectionRef.deposit(token: <-packs.withdraw(withdrawID: id))
			}
			destroy packs
			emit PackMailCreated(address: wallet, packIDs: IDs)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun adminClaimMail(wallet: Address, recipient: &{NonFungibleToken.Receiver}, id: UInt64){ 
			if self.mails[wallet] != nil{ 
				let collectionRef = (&self.mails[wallet] as &Pack.Collection?)!
				recipient.deposit(token: <-collectionRef.withdraw(withdrawID: id))
			}
			emit MailAdminClaimed(wallet: wallet, packID: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewCentralizedInbox(): @CentralizedInbox{ 
			return <-create CentralizedInbox()
		}
	}
	
	init(){ 
		// Set named paths
		self.CentralizedInboxStoragePath = /storage/BasicBeastsCentralizedInbox
		self.CentralizedInboxPrivatePath = /private/BasicBeastsCentralizedInboxUpgrade
		self.CentralizedInboxPublicPath = /public/BasicBeastsCentralizedInbox
		
		// Put CentralizedInbox in storage
		self.account.storage.save(<-create CentralizedInbox(), to: self.CentralizedInboxStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Inbox.CentralizedInbox>(
				self.CentralizedInboxStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.CentralizedInboxPrivatePath)
		?? panic("Could not get a capability to the Centralized Inbox")
		var capability_2 =
			self.account.capabilities.storage.issue<&Inbox.CentralizedInbox>(
				self.CentralizedInboxStoragePath
			)
		self.account.capabilities.publish(capability_2, at: self.CentralizedInboxPublicPath)
		?? panic("Could not get a capability to the Centralized Inbox")
	}
}
