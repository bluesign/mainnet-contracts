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

	// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Patch: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTTemplateCreated(templateID: UInt64, template: Patch.PatchTemplate)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, templateID: UInt64, serialNumber: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event TemplateUpdated(template: PatchTemplate)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextTemplateID: UInt64
	
	access(self)
	var PatchTemplates:{ UInt64: PatchTemplate}
	
	access(self)
	var tokenMintedPerType:{ UInt64: UInt64}
	
	access(all)
	resource interface PatchCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPatch(id: UInt64): &Patch.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Patch reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct PatchTemplate{ 
		access(all)
		let templateID: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var mintLimit: UInt64
		
		access(all)
		var locked: Bool
		
		access(all)
		var nextSerialNumber: UInt64
		
		access(self)
		var metadata:{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun incrementSerialNumber(){ 
			self.nextSerialNumber = self.nextSerialNumber + 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockTemplate(){ 
			self.locked = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadata(newMetadata:{ String: String}){ 
			pre{ 
				newMetadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.metadata = newMetadata
		}
		
		init(templateID: UInt64, name: String, description: String, mintLimit: UInt64, metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.templateID = templateID
			self.name = name
			self.description = description
			self.mintLimit = mintLimit
			self.metadata = metadata
			self.locked = false
			self.nextSerialNumber = 1
			Patch.nextTemplateID = Patch.nextTemplateID + 1
			emit NFTTemplateCreated(templateID: self.templateID, template: self)
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getNFTTemplate().name, description: self.getNFTTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getNFTTemplate().getMetadata()["uri"]!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://flunks.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Patch.CollectionStoragePath, publicPath: Patch.CollectionPublicPath, publicCollection: Type<&Patch.Collection>(), publicLinkedType: Type<&Patch.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Patch.createEmptyCollection(nftType: Type<@Patch.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/classroom.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Backpack Patch", description: "Backpack Patches #onFlow", externalURL: MetadataViews.ExternalURL("https://flunks.io/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTTemplate(): PatchTemplate{ 
			return Patch.PatchTemplates[self.templateID]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTMetadata():{ String: String}{ 
			return (Patch.PatchTemplates[self.templateID]!).getMetadata()
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initTemplateID: UInt64, serialNumber: UInt64){ 
			self.id = initID
			self.templateID = initTemplateID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource Collection: PatchCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Patch.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(collection: @Collection){ 
			let keys = collection.getIDs()
			for key in keys{ 
				self.deposit(token: <-collection.withdraw(withdrawID: key))
			}
			destroy collection
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPatch(id: UInt64): &Patch.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Patch.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &Patch.NFT
			return exampleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, templateID: UInt64){ 
			pre{ 
				Patch.PatchTemplates[templateID] != nil:
					"Template doesn't exist"
				!(Patch.PatchTemplates[templateID]!).locked:
					"Cannot mint Patch - template is locked"
				(Patch.PatchTemplates[templateID]!).nextSerialNumber <= (Patch.PatchTemplates[templateID]!).mintLimit:
					"Cannot mint Patch - mint limit reached"
			}
			
			// TODO: mint Patch NFT
			let nftTemplate = Patch.PatchTemplates[templateID]!
			let newNFT: @NFT <- create Patch.NFT(initID: Patch.totalSupply, initTemplateID: templateID, serialNumber: nftTemplate.nextSerialNumber)
			emit Mint(id: newNFT.id, templateID: nftTemplate.templateID, serialNumber: nftTemplate.nextSerialNumber)
			Patch.totalSupply = Patch.totalSupply + 1
			(Patch.PatchTemplates[templateID]!).incrementSerialNumber()
			recipient.deposit(token: <-newNFT)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createPatchTemplate(name: String, description: String, mintLimit: UInt64, metadata:{ String: String}){ 
			Patch.PatchTemplates[Patch.nextTemplateID] = PatchTemplate(templateID: Patch.nextTemplateID, name: name, description: description, mintLimit: mintLimit, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePatchTemplate(templateID: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				Patch.PatchTemplates.containsKey(templateID) != nil:
					"Template does not exits."
			}
			(Patch.PatchTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPatchTemplateByID(templateID: UInt64): Patch.PatchTemplate{ 
		return Patch.PatchTemplates[templateID]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPatchTemplates():{ UInt64: Patch.PatchTemplate}{ 
		return Patch.PatchTemplates
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/PatchCollection
		self.CollectionPublicPath = /public/PatchCollection
		self.AdminStoragePath = /storage/PatchAdmin
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.tokenMintedPerType ={} 
		self.PatchTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
