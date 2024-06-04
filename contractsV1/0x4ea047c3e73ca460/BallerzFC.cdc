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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleTokenMetadataViews from "./../../standardsV1/FungibleTokenMetadataViews.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"

import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"

access(all)
contract BallerzFC: FungibleToken{ 
	
	// The amount of tokens in existance
	access(all)
	var totalSupply: UFix64
	
	// nil if there is none
	access(all)
	let maxSupply: UFix64?
	
	// Paths
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdministratorStoragePath: StoragePath
	
	// Events
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensTransferred(amount: UFix64, from: Address, to: Address)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, ViewResolver.Resolver{ 
		access(all)
		var balance: UFix64
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			if let owner: Address = self.owner?.address{ 
				BallerzFC.setBalance(address: owner, balance: self.balance)
			}
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			let vault: @Vault <- from as! @Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			
			// We set the balance to 0.0 here so that it doesn't
			// decrease the totalSupply in the `destroy` function.
			vault.balance = 0.0
			destroy vault
			if let owner: Address = self.owner?.address{ 
				BallerzFC.setBalance(address: owner, balance: self.balance)
			}
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<FungibleTokenMetadataViews.FTView>():
					return FungibleTokenMetadataViews.FTView(ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?, ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?)
				case Type<FungibleTokenMetadataViews.FTDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreia7yuhyjuqadsauw5dnmyaas2sxweulbj7cfpdysfglbu3u6kgtre"), mediaType: "image")
					let medias = MetadataViews.Medias([media])
					return FungibleTokenMetadataViews.FTDisplay(name: "Ballerz FC", symbol: "BFC", description: "A DAO for the ownership and management of Ballerz FC and related assets in the MFL Universe", externalURL: MetadataViews.ExternalURL(""), logos: medias, socials:{ "twitter": MetadataViews.ExternalURL("Ballerz__FC"), "discord": MetadataViews.ExternalURL("sDBp8YdH")})
				case Type<FungibleTokenMetadataViews.FTVaultData>():
					return FungibleTokenMetadataViews.FTVaultData(storagePath: BallerzFC.VaultStoragePath, receiverPath: BallerzFC.ReceiverPublicPath, metadataPath: BallerzFC.VaultPublicPath, receiverLinkedType: /private/BallerzFCVault, metadataLinkedType: Type<&Vault>(), createEmptyVaultFunction: Type<&Vault>(), providerLinkedType: Type<&Vault>(), createEmptyVaultFunction: fun (): @Vault{ 
							return <-BallerzFC.createEmptyVault(vaultType: Type<@BallerzFC.Vault>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
		
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Minter: Toucans.Minter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(amount: UFix64): @Vault{ 
			post{ 
				BallerzFC.maxSupply == nil || BallerzFC.totalSupply <= BallerzFC.maxSupply!:
					"Exceeded the max supply of tokens allowd."
			}
			BallerzFC.totalSupply = BallerzFC.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	// We follow this pattern of storage
	// so the (potentially) huge dictionary 
	// isn't loaded when the contract is imported
	access(all)
	resource Administrator{ 
		// This is an experimental index and should
		// not be used for anything official
		// or monetary related
		access(self)
		let balances:{ Address: UFix64}
		
		access(contract)
		fun setBalance(address: Address, balance: UFix64){ 
			self.balances[address] = balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(address: Address): UFix64{ 
			return self.balances[address] ?? 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalances():{ Address: UFix64}{ 
			return self.balances
		}
		
		init(){ 
			self.balances ={} 
		}
	}
	
	access(contract)
	fun setBalance(address: Address, balance: UFix64){ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		admin.setBalance(address: address, balance: balance)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBalance(address: Address): UFix64{ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		return admin.getBalance(address: address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBalances():{ Address: UFix64}{ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		return admin.getBalances()
	}
	
	init(_paymentTokenInfo: ToucansTokens.TokenInfo, _editDelay: UFix64, _minting: Bool, _initialTreasurySupply: UFix64, _maxSupply: UFix64?, _extra:{ String: AnyStruct}){ 
		
		// Contract Variables
		self.totalSupply = 0.0
		self.maxSupply = _maxSupply
		
		// Paths
		self.VaultStoragePath = /storage/BallerzFCVault
		self.ReceiverPublicPath = /public/BallerzFCReceiver
		self.VaultPublicPath = /public/BallerzFCMetadata
		self.MinterStoragePath = /storage/BallerzFCMinter
		self.AdministratorStoragePath = /storage/BallerzFCAdmin
		
		// Admin Setup
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.VaultPublicPath)
		if self.account.storage.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath) == nil{ 
			self.account.storage.save(<-Toucans.createCollection(), to: Toucans.CollectionStoragePath)
			var capability_3 = self.account.capabilities.storage.issue<&Toucans.Collection>(Toucans.CollectionStoragePath)
			self.account.capabilities.publish(capability_3, at: Toucans.CollectionPublicPath)
		}
		let toucansProjectCollection = self.account.storage.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath)!
		toucansProjectCollection.createProject(projectTokenInfo: ToucansTokens.TokenInfo("BallerzFC", self.account.address, "BFC", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), paymentTokenInfo: _paymentTokenInfo, minter: <-create Minter(), editDelay: _editDelay, minting: _minting, initialTreasurySupply: _initialTreasurySupply, extra: _extra)
		self.account.storage.save(<-create Administrator(), to: self.AdministratorStoragePath)
		
		// Events
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
