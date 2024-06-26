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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Profile from "./Profile.cdc"

import FIND from "./FIND.cdc"

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import FTRegistry from "./FTRegistry.cdc"

import FindForge from "./FindForge.cdc"

import FindForgeOrder from "./FindForgeOrder.cdc"

import FindPack from "./FindPack.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

import FINDNFTCatalogAdmin from "./FINDNFTCatalogAdmin.cdc"

import FindViews from "./FindViews.cdc"

import NameVoucher from "./NameVoucher.cdc"

access(all)
contract Admin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	/// ===================================================================================
	// Admin things
	/// ===================================================================================
	//Admin client to use for capability receiver pattern
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&FIND.Network>): Void
	}
	
	//admin proxy with capability receiver
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&FIND.Network>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&FIND.Network>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPublicForgeType(name: String, forgeType: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.addPublicForgeType(forgeType: forgeType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPrivateForgeType(name: String, forgeType: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.addPrivateForgeType(name: name, forgeType: forgeType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeForgeType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.removeForgeType(type: type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addForgeContractData(lease: String, forgeType: Type, data: AnyStruct){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.adminAddContractData(lease: lease, forgeType: forgeType, data: data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addForgeMintType(_ mintType: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForgeOrder.addMintType(mintType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun orderForge(leaseName: String, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.adminOrderForge(leaseName: leaseName, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelForgeOrder(leaseName: String, mintType: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.cancelForgeOrder(leaseName: leaseName, mintType: mintType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun fulfillForgeOrder(contractName: String, forgeType: Type): MetadataViews.NFTCollectionDisplay{ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			return FindForge.fulfillForgeOrder(contractName, forgeType: forgeType)
		}
		
		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		access(TMP_ENTITLEMENT_OWNER)
		fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let walletRef = (self.capability!).borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat((self.capability!).address.toString()))
			walletRef.setWallet(wallet)
		}
		
		/// Enable or disable public registration
		access(TMP_ENTITLEMENT_OWNER)
		fun setPublicEnabled(_ enabled: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let walletRef = (self.capability!).borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat((self.capability!).address.toString()))
			walletRef.setPublicEnabled(enabled)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAddonPrice(name: String, price: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let walletRef = (self.capability!).borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat((self.capability!).address.toString()))
			walletRef.setAddonPrice(name: name, price: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPrice(_default: UFix64, additional:{ Int: UFix64}){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let walletRef = (self.capability!).borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat((self.capability!).address.toString()))
			walletRef.setPrice(_default: _default, additionalPrices: additional)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun register(name: String, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection>){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
				FIND.validateFindName(name):
					"A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}
			let walletRef = (self.capability!).borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat((self.capability!).address.toString()))
			walletRef.internal_register(name: name, profile: profile, leases: leases)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAddon(name: String, addon: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
				FIND.validateFindName(name):
					"A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}
			let user = FIND.lookupAddress(name) ?? panic("Cannot find lease owner. Lease : ".concat(name))
			let ref = getAccount(user).capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath).borrow() ?? panic("Cannot borrow reference to lease collection of user : ".concat(name))
			ref.adminAddAddon(name: name, addon: addon)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun adminSetMinterPlatform(name: String, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials:{ String: String}){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
				FIND.validateFindName(name):
					"A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}
			FindForge.adminSetMinterPlatform(leaseName: name, forgeType: forgeType, minterCut: minterCut, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintForge(name: String, forgeType: Type, data: AnyStruct, receiver: &{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindForge.mintAdmin(leaseName: name, forgeType: forgeType, data: data, receiver: receiver)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun debug(_ value: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}
		
		/*
				pub fun setViewConverters(from: Type, converters: [{Dandy.ViewConverter}]) {
					pre {
						self.capability != nil: "Cannot create FIND, capability is not set"
					}
		
					Dandy.setViewConverters(from: from, converters: converters)
				}
				*/
		
		/// ===================================================================================
		// Fungible Token Registry
		/// ===================================================================================
		// Registry FungibleToken Information
		access(TMP_ENTITLEMENT_OWNER)
		fun setFTInfo(alias: String, type: Type, tag: [String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FTRegistry.setFTInfo(alias: alias, type: type, tag: tag, icon: icon, receiverPath: receiverPath, balancePath: balancePath, vaultPath: vaultPath)
		}
		
		// Remove FungibleToken Information by type identifier
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FTRegistry.removeFTInfoByTypeIdentifier(typeIdentifier)
		}
		
		// Remove FungibleToken Information by alias
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFTInfoByAlias(_ alias: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FTRegistry.removeFTInfoByAlias(alias)
		}
		
		/// ===================================================================================
		// Find Pack
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuthPointer(pathIdentifier: String, id: UInt64): FindViews.AuthNFTPointer{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let privatePath = PrivatePath(identifier: pathIdentifier)!
			var cap = Admin.account.capabilities.get<&{ViewResolver.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			if !cap.check(){ 
				let storagePath = StoragePath(identifier: pathIdentifier)!
				Admin.account.link<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath, target: storagePath)
				cap = Admin.account.capabilities.get<&{ViewResolver.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			}
			return FindViews.AuthNFTPointer(cap: cap!, id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProviderCap(_ path: PrivatePath): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(path)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintFindPack(packTypeName: String, typeId: UInt64, hash: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let pathIdentifier = FindPack.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: typeId)
			let path = PublicPath(identifier: pathIdentifier)!
			let receiver = Admin.account.capabilities.get<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(path).borrow() ?? panic("Cannot borrow reference to admin find pack collection public from Path : ".concat(pathIdentifier))
			let mintPackData = FindPack.MintPackData(packTypeName: packTypeName, typeId: typeId, hash: hash, verifierRef: FindForge.borrowVerifier())
			FindForge.adminMint(lease: packTypeName, forgeType: Type<@FindPack.Forge>(), data: mintPackData, receiver: receiver)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun fulfillFindPack(packId: UInt64, types: [Type], rewardIds: [UInt64], salt: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			FindPack.fulfill(packId: packId, types: types, rewardIds: rewardIds, salt: salt)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun requeueFindPack(packId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let cap = Admin.account.storage.borrow<&FindPack.Collection>(from: FindPack.DLQCollectionStoragePath)!
			cap.requeue(packId: packId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFindRoyaltyCap(): Capability<&{FungibleToken.Receiver}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
		}
		
		/// ===================================================================================
		// FINDNFTCatalog
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun addCatalogEntry(collectionIdentifier: String, metadata: NFTCatalog.NFTCatalogMetadata){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let FINDCatalogAdmin = Admin.account.storage.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
			FINDCatalogAdmin.addCatalogEntry(collectionIdentifier: collectionIdentifier, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeCatalogEntry(collectionIdentifier: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let FINDCatalogAdmin = Admin.account.storage.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
			FINDCatalogAdmin.removeCatalogEntry(collectionIdentifier: collectionIdentifier)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSwitchboardReceiverPublic(): Capability<&{FungibleToken.Receiver}>{ 
			// we hard code it here instead, to avoid importing just for path
			return Admin.account.capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)!
		}
		
		/// ===================================================================================
		// Name Voucher
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNameVoucher(receiver: &{NonFungibleToken.Receiver}, minCharLength: UInt64): UInt64{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return NameVoucher.mintNFT(recipient: receiver, minCharLength: minCharLength)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNameVoucherToFind(minCharLength: UInt64): UInt64{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let receiver = Admin.account.storage.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)!
			return NameVoucher.mintNFT(recipient: receiver, minCharLength: minCharLength)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/findAdminProxy
		self.AdminProxyStoragePath = /storage/findAdminProxy
	}
}
