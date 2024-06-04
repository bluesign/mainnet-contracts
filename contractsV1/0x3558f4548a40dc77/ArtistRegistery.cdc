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
# ArtistRegistery contract

This contract, owned by the platform admin, allows to define the artists metadata and vaults to receive their cut. 

 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract ArtistRegistery{ 
	
	// -----------------------------------------------------------------------
	// Variables 
	// -----------------------------------------------------------------------
	// Manager public path, allowing an Admin to initialize it
	access(all)
	let ManagerPublicPath: PublicPath
	
	// Manager storage path, for a manager to manager an artist
	access(all)
	let ManagerStoragePath: StoragePath
	
	// Admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	// Admin private path, allowing initialized Manager to cmanage an artist
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(self)
	var artists: @{UInt64: Artist}
	
	access(self)
	var artistTempVaults: @{UInt64: FUSD.Vault} // temporary vaults when the artists' ones are not available
	
	
	access(all)
	var numberOfArtists: UInt64
	
	// -----------------------------------------------------------------------
	// Events 
	// -----------------------------------------------------------------------
	// An artist has been created
	access(all)
	event Created(id: UInt64, name: String)
	
	// An artist has received FUSD
	access(all)
	event FUSDReceived(id: UInt64, amount: UFix64)
	
	// An artist vault has been updated
	access(all)
	event VaultUpdated(id: UInt64)
	
	// An artist name has been updated
	access(all)
	event NameUpdated(id: UInt64, name: String)
	
	// -----------------------------------------------------------------------
	// Resources 
	// -----------------------------------------------------------------------
	// Resource representing a single artist
	access(all)
	resource Artist{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(self)
		var vault: Capability<&FUSD.Vault>?
		
		init(name: String){ 
			ArtistRegistery.numberOfArtists = ArtistRegistery.numberOfArtists + 1 as UInt64
			self.id = ArtistRegistery.numberOfArtists
			self.name = name
			self.vault = nil
			emit Created(id: self.id, name: name)
		}
		
		// Update the artist name
		access(contract)
		fun updateName(name: String){ 
			self.name = name
			emit NameUpdated(id: self.id, name: name)
		}
		
		// Update the artist vault to receive their cut from sales and auctions
		access(contract)
		fun updateVault(vault: Capability<&FUSD.Vault>){ 
			self.vault = vault
			emit VaultUpdated(id: self.id)
		}
		
		// Send the artist share. If the artist vault is not available, it is put in a temporary vault
		access(TMP_ENTITLEMENT_OWNER)
		fun sendShare(deposit: @{FungibleToken.Vault}){ 
			let balance = deposit.balance
			if self.vault != nil && (self.vault!).check(){ 
				let vaultRef = (self.vault!).borrow()!
				vaultRef.deposit(from: <-deposit)
			} else{ 
				// If the artist vault is anavailable, put the tokens in a temporary vault
				let artistTempVault = &ArtistRegistery.artistTempVaults[self.id] as &FUSD.Vault?
				artistTempVault.deposit(from: <-deposit) // will fail if it is not a @FUSD.Vault
			
			}
			emit FUSDReceived(id: self.id, amount: balance)
		}
		
		// When an artist vault is not available, the tokens are put in a temporary vault
		// This function allows to release the funds to the artist's newly set vault
		access(TMP_ENTITLEMENT_OWNER)
		fun unlockArtistShare(){ 
			let artistTempVault = &ArtistRegistery.artistTempVaults[self.id] as &FUSD.Vault?
			if self.vault != nil && (self.vault!).check(){ 
				let vaultRef = (self.vault!).borrow()!
				vaultRef.deposit(from: <-artistTempVault.withdraw(amount: artistTempVault.balance))
			} else{ 
				panic("Cannot borrow artist's vault")
			}
		}
	}
	
	// ArtistModifier
	//
	// An artist modifier can update the artist info
	//
	access(all)
	resource interface ArtistModifier{ 
		// Update an artist's name
		access(TMP_ENTITLEMENT_OWNER)
		fun updateName(id: UInt64, name: String): Void
		
		// Update an artist's vault
		access(TMP_ENTITLEMENT_OWNER)
		fun updateVault(id: UInt64, vault: Capability<&FUSD.Vault>)
		
		// When an artist vault is not available, the tokens are put in a temporary vault
		// This function allows to release the funds to the artist's newly set vault
		access(TMP_ENTITLEMENT_OWNER)
		fun unlockArtistShare(id: UInt64)
	}
	
	// An admin creates artists, allowing Sale and Auction contract to send the artist share
	access(all)
	resource Admin: ArtistModifier{ 
		// Create an artist
		access(TMP_ENTITLEMENT_OWNER)
		fun createArtist(name: String){ 
			let artist <- create Artist(name: name)
			ArtistRegistery.artistTempVaults[artist.id] <-! FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>()) as! @FUSD.Vault
			ArtistRegistery.artists[artist.id] <-! artist
		}
		
		// Update an artist's name
		// If artist doesn't exist, will not fail, nothing will happen
		access(TMP_ENTITLEMENT_OWNER)
		fun updateName(id: UInt64, name: String){ 
			ArtistRegistery.artists[id]?.updateName(name: name)
		}
		
		// Update an artist's vault
		// If artist doesn't exist, will not fail, nothing will happen
		access(TMP_ENTITLEMENT_OWNER)
		fun updateVault(id: UInt64, vault: Capability<&FUSD.Vault>){ 
			pre{ 
				vault.check():
					"The artist vault should be available"
			}
			ArtistRegistery.artists[id]?.updateVault(vault: vault)
		}
		
		// When an artist vault is not available, the tokens are put in a temporary vault
		// This function allows to release the funds to the artist's newly set vault
		// If artist doesn't exist, will not fail, nothing will happen
		access(TMP_ENTITLEMENT_OWNER)
		fun unlockArtistShare(id: UInt64){ 
			ArtistRegistery.artists[id]?.unlockArtistShare()
		}
	}
	
	access(all)
	resource interface ManagerClient{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setArtist(artistID: UInt64, server: Capability<&ArtistRegistery.Admin>): Void
	}
	
	// Manager
	//
	// A manager can change the artist vault and name
	//
	access(all)
	resource Manager: ManagerClient{ 
		access(self)
		var artistID: UInt64?
		
		access(self)
		var server: Capability<&Admin>?
		
		init(){ 
			self.artistID = nil
			self.server = nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArtist(artistID: UInt64, server: Capability<&Admin>){ 
			pre{ 
				server.check():
					"Invalid server capablity"
				self.server == nil:
					"Server already set"
				self.artistID == nil:
					"Artist already set"
			}
			self.server = server
			self.artistID = artistID
		}
		
		// Update an artist's name
		access(TMP_ENTITLEMENT_OWNER)
		fun updateName(name: String){ 
			pre{ 
				self.server != nil:
					"Server not set"
				self.artistID != nil:
					"Artist not set"
			}
			if let artistModifier = (self.server!).borrow(){ 
				artistModifier.updateName(id: self.artistID!, name: name)
				return
			}
			panic("Could not borrow the artist modifier")
		}
		
		// Update an artist's vault
		access(TMP_ENTITLEMENT_OWNER)
		fun updateVault(vault: Capability<&FUSD.Vault>){ 
			pre{ 
				self.server != nil:
					"Server not set"
				self.artistID != nil:
					"Artist not set"
			}
			if let artistModifier = (self.server!).borrow(){ 
				artistModifier.updateVault(id: self.artistID!, vault: vault)
				return
			}
			panic("Could not borrow the artist modifier")
		}
		
		// When an artist vault is not available, the tokens are put in a temporary vault
		// This function allows to release the funds to the artist's newly set vault
		access(TMP_ENTITLEMENT_OWNER)
		fun unlockArtistShare(){ 
			pre{ 
				self.server != nil:
					"Server not set"
				self.artistID != nil:
					"Artist not set"
			}
			if let artistModifier = (self.server!).borrow(){ 
				artistModifier.unlockArtistShare(id: self.artistID!)
				return
			}
			panic("Could not borrow the artist modifier")
		}
	}
	
	// -----------------------------------------------------------------------
	// Contract public functions
	// -----------------------------------------------------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun createManager(): @Manager{ 
		return <-create Manager()
	}
	
	// Send the artist share. If the artist vault is not available, it is put in a temporary vault
	access(TMP_ENTITLEMENT_OWNER)
	fun sendArtistShare(id: UInt64, deposit: @{FungibleToken.Vault}){ 
		pre{ 
			ArtistRegistery.artists[id] != nil:
				"No such artist"
		}
		let artist = &ArtistRegistery.artists[id] as &ArtistRegistery.Artist?
		artist.sendShare(deposit: <-deposit)
	}
	
	// Get an artist's data (name, vault capability)
	access(TMP_ENTITLEMENT_OWNER)
	fun getArtistName(id: UInt64): String{ 
		pre{ 
			ArtistRegistery.artists[id] != nil:
				"No such artist"
		}
		let artist = &ArtistRegistery.artists[id] as &ArtistRegistery.Artist?
		return artist.name
	}
	
	// -----------------------------------------------------------------------
	// Initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.ManagerPublicPath = /public/boulangerieV1artistRegisteryManager
		self.ManagerStoragePath = /storage/boulangerieV1artistRegisteryManager
		self.AdminStoragePath = /storage/boulangerieV1artistRegisteryAdmin
		self.AdminPrivatePath = /private/boulangerieV1artistRegisteryAdmin
		self.artists <-{} 
		self.artistTempVaults <-{} 
		self.numberOfArtists = 0
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
}
