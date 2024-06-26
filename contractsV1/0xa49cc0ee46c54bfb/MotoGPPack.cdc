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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MotoGPPackMetadata from 0xa49cc0ee46c54bfb

access(all)
contract MotoGPPack: NonFungibleToken{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.0.2"
	}
	
	// The total number of Packs that have been minted
	access(all)
	var totalSupply: UInt64
	
	// An dictionary of all the pack types that have been
	// created using addPackType method defined 
	// in the MotoGPAdmin contract
	//
	// It maps the packType # to the 
	// information of that pack type
	access(account)
	var packTypes:{ UInt64: PackType}
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	// Event that emitted when the MotoGPPack contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	// Event that is emitted when a Pack is withdrawn,
	// indicating the owner of the collection that it was withdrawn from.
	//
	// If the collection is not in an account's storage, `from` will be `nil`.
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event that emitted when a Pack is deposited to a collection.
	//
	// It indicates the owner of the collection that it was deposited to.
	//
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// PackInfo
	// a struct that represents the info of a Pack.  
	// It is conveniant to have a struct because we 
	// can easily read from it without having to move
	// resources around. Each PackInfo holds a 
	// packNumber and packType
	//
	access(all)
	struct PackInfo{ 
		// The pack # of this pack type
		access(all)
		var packNumber: UInt64
		
		// An ID that represents that type of pack this is
		access(all)
		var packType: UInt64
		
		init(_packNumber: UInt64, _packType: UInt64){ 
			self.packNumber = _packNumber
			self.packType = _packType
		}
	}
	
	// NFT
	// This resource defines a Pack with a PackInfo
	// struct.
	// After a Pack is opened, the Pack is destroyed and its id
	// can never be created again. 
	//
	// The NFT (Pack) resource is arbitrary in the sense that it doesn't
	// actually hold Cards inside. However, by looking at a Pack's
	// packType and mapping that to the # of Cards in a Pack,
	// we will use that info when opening the Pack.
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The Pack's id (completely sequential)
		access(all)
		let id: UInt64
		
		access(all)
		var packInfo: PackInfo
		
		init(_packNumber: UInt64, _packType: UInt64){ 
			let packTypeStruct: &PackType = (&MotoGPPack.packTypes[_packType] as &PackType?)!
			// updates the number of packs minted for this packType
			packTypeStruct.updateNumberOfPacksMinted()
			
			// will panic if this packNumber already exists in this packType
			packTypeStruct.addPackNumber(packNumber: _packNumber)
			self.id = MotoGPPack.totalSupply
			self.packInfo = PackInfo(_packNumber: _packNumber, _packType: _packType)
			MotoGPPack.totalSupply = MotoGPPack.totalSupply + 1 as UInt64
			emit Mint(id: self.id)
		}
		
		///////////////////////////////
		// Resolver interface methods
		/////////////////////////////// 
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return MotoGPPackMetadata.resolveView(view: view, id: self.id, packID: self.packInfo.packType, serial: self.packInfo.packNumber,																																			 // Below four arguments are passed to MotoGPPackMetadata (as opposed being hardcoded there) to avoid cyclic dependencies MotoGPPack <-> MotoGPPackMetadata
																																			 publicCollectionType: Type<&MotoGPPack.Collection>(), publicLinkedType: Type<&MotoGPPack.Collection>(), providerLinkedType: Type<&MotoGPPack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-MotoGPPack.createEmptyCollection(nftType: Type<@MotoGPPack.Collection>())
				})
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// createPack
	// allows us to create Packs from another contract
	// in this account. This is helpful for 
	// allowing MotoGPAdmin to mint Packs.
	//
	access(account)
	fun createPack(packNumber: UInt64, packType: UInt64): @NFT{ 
		return <-create NFT(_packNumber: packNumber, _packType: packType)
	}
	
	// PackType
	// holds all the information for
	// a specific pack type
	//
	access(all)
	struct PackType{ 
		access(all)
		let packType: UInt64
		
		// the number of packs of this pack type
		// that have been minted
		access(all)
		var numberOfPacksMinted: UInt64
		
		// the number of cards that will be minted
		// when a pack of this pack type is opened
		access(all)
		let numberOfCards: UInt64
		
		// the pack numbers that already exist of this
		// pack type.
		// This is primarily used so we don't create duplicate
		// Packs with the same packNumber and packType
		access(all)
		var assignedPackNumbers:{ UInt64: Bool}
		
		// updateNumberOfPacksMinted
		// updates the number of Packs that have
		// been minted for this specific pack type
		//
		access(contract)
		fun updateNumberOfPacksMinted(){ 
			self.numberOfPacksMinted = self.numberOfPacksMinted + 1 as UInt64
		}
		
		// addPackNumber
		// updates the amount of packNumbers that
		// belong to this PackType so we do not
		// make duplicates when minting a Pack
		//
		access(contract)
		fun addPackNumber(packNumber: UInt64){ 
			if let assignedPackNumbers = self.assignedPackNumbers[packNumber]{ 
				panic("The following pack number already exists: ".concat(packNumber.toString()))
			} else{ 
				self.assignedPackNumbers[packNumber] = true
			}
		}
		
		init(_packType: UInt64, _numberOfCards: UInt64){ 
			self.packType = _packType
			self.numberOfCards = _numberOfCards
			self.numberOfPacksMinted = 0
			self.assignedPackNumbers ={} 
		}
	}
	
	// IPackCollectionPublic
	// This defines an interface to only expose a
	// Collection of Packs to the public
	//
	// Allows users to deposit Packs, read all the Pack IDs,
	// borrow a NFT reference to access a Pack's ID,
	// and borrow a Pack reference
	// to access all of the Pack's fields.
	//
	access(all)
	resource interface IPackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(id: UInt64): &MotoGPPack.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// IPackCollectionAdminAccessible
	// Exposes the openPack which allows an admin to
	// open a pack in this collection.
	//
	access(all)
	resource interface IPackCollectionAdminAccessible{} 
	
	//Keep for now for compatibility purposes.
	// Collection
	// a collection of Pack resources so that users can
	// own Packs in a collection and trade them back and forth.
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, IPackCollectionPublic, IPackCollectionAdminAccessible, ViewResolver.ResolverCollection{ 
		// A dictionary that maps ids to the pack with that id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// deposit
		// deposits a Pack into the users Collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @MotoGPPack.NFT
			let id: UInt64 = token.id
			
			// add the new Pack to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		// withdraw
		// withdraws a Pack from the collection
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// getIDs
		// returns the ids of all the Packs this
		// collection has
		// 
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its id
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowPack
		// borrowPack returns a borrowed reference to a Pack
		// so that the caller can read data from it.
		// They can use this to read its PackInfo and id
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPack(id: UInt64): &MotoGPPack.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &MotoGPPack.NFT?
		}
		
		// ResolverCollection interface method
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &MotoGPPack.NFT
			return packNFT as &{ViewResolver.Resolver}
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
	
	// createEmptyCollection
	// creates an empty Collection so that users
	// can be able to receive and deal with Pack resources.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// getPackTypeInfo
	// returns a PackType struct, which represents the info
	// of a specific PackType that is passed in
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getPackTypeInfo(packType: UInt64): PackType{ 
		return self.packTypes[packType] ?? panic("This pack type does not exist")
	}
	
	// addPackType
	// allows us to add new pack types from another contract
	// in this account. This is helpful for 
	// allowing MotoGPAdmin to add new pack types.
	//
	access(account)
	fun addPackType(packType: UInt64, numberOfCards: UInt64){ 
		pre{ 
			self.packTypes[packType] == nil:
				"This pack type already exists!"
		}
		// Adds this pack type
		self.packTypes[packType] = self.PackType(_packType: packType, _numberOfCards: numberOfCards)
	}
	
	init(){ 
		self.totalSupply = 0
		self.packTypes ={} 
		emit ContractInitialized()
	}
}
