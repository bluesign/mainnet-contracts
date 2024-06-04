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

	// Implementation of the DaysOnFlow contract
// Each DaysOnFlow series represents a collection of DayNFTs
// NFTs can be minted for free by the holders of the DayNFTs in the series
// The series also support WL and public minting
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import DayNFT from "../0x1600b04bf033fb99/DayNFT.cdc"

access(all)
contract DaysOnFlow: NonFungibleToken{ 
	
	// PATHS
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let SeriesMinterStoragePath: StoragePath
	
	// EVENTS
	access(all)
	event ContractInitialized()
	
	access(all)
	event Minted(id: UInt64, seriesId: UInt64, seriesImage: String, serial: UInt64, saleType: String)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// STATE
	// The total amount of DOFs that have ever been created
	access(all)
	var totalSupply: UInt64
	
	// All the DOF Series
	access(account)
	var allSeries: @{UInt64: DOFSeries}
	
	// FUNCTIONALITY
	// Represents a DOF item
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesDescription: String
		
		access(all)
		let seriesId: UInt64
		
		access(all)
		let seriesImage: String
		
		access(all)
		let seriesSmallImage: String
		
		access(all)
		let seriesName: String
		
		access(all)
		let serial: UInt64
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.seriesName, description: self.seriesDescription, thumbnail: MetadataViews.HTTPFile(url: "https://day-nft.io/".concat(self.seriesSmallImage).concat(".jpg")))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.seriesName, number: self.serial, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Royalties>():
					let royalty = MetadataViews.Royalty(receiver: DaysOnFlow.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Default royalty")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://day-nft.io")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DaysOnFlow.CollectionStoragePath, publicPath: DaysOnFlow.CollectionPublicPath, publicCollection: Type<&DaysOnFlow.Collection>(), publicLinkedType: Type<&DaysOnFlow.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DaysOnFlow.createEmptyCollection(nftType: Type<@DaysOnFlow.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let header = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://day-nft.io/header.png"), mediaType: "image/png")
					let logo = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://day-nft.io/QmcrhA1C3hTXnhRLpynZWBAyPaf4p8zsAE8NK3H3oM2qsv.jpg"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "Days On Flow", description: "The collection can contain multiple series, each representing a set of DayNFTs.", externalURL: MetadataViews.ExternalURL("https://day-nft.io"), squareImage: logo, bannerImage: header, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/day_nft_io")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_seriesDescription: String, _seriesId: UInt64, _seriesImage: String, _seriesSmallImage: String, _seriesName: String, _serial: UInt64, _saleType: String, _metadata:{ String: AnyStruct}){ 
			self.id = DaysOnFlow.totalSupply
			self.seriesDescription = _seriesDescription
			self.seriesId = _seriesId
			self.seriesImage = _seriesImage
			self.seriesSmallImage = _seriesSmallImage
			self.seriesName = _seriesName
			self.serial = _serial
			self.metadata = _metadata
			emit Minted(id: self.id, seriesId: _seriesId, seriesImage: _seriesImage, serial: _serial, saleType: _saleType)
			DaysOnFlow.totalSupply = DaysOnFlow.totalSupply + 1
		}
	}
	
	// A public interface for people to call into our Collection
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDOF(id: UInt64): &DaysOnFlow.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ownedIdsFromSeries(seriesId: UInt64): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ownedDOFsFromSeries(seriesId: UInt64): [&NFT]
	}
	
	// A Collection that holds all of the users DOFs.
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		// Maps a DOF id to the DOF itself
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Maps a seriesId to the ids of DOFs that
		// this user owns from that series
		access(account)
		var series:{ UInt64:{ UInt64: Bool}}
		
		// Deposits a DOF into the collection
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let nft <- token as! @NFT
			let id = nft.id
			let seriesId = nft.seriesId
			emit Deposit(id: id, to: (self.owner!).address)
			if self.series[seriesId] == nil{ 
				self.series[seriesId] ={ id: true}
			} else{ 
				(self.series[seriesId]!).insert(key: id, true)
			}
			self.ownedNFTs[id] <-! nft
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let nft <- token as! @NFT
			let id = nft.id
			(self.series[nft.seriesId]!).remove(key: id)
			emit Withdraw(id: id, from: self.owner?.address)
			return <-nft
		}
		
		// Get all ids
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns an array of ids that belong to
		// the passed in seriesId
		access(TMP_ENTITLEMENT_OWNER)
		fun ownedIdsFromSeries(seriesId: UInt64): [UInt64]{ 
			if self.series[seriesId] != nil{ 
				return (self.series[seriesId]!).keys
			}
			return []
		}
		
		// Returns an array of DOFs that belong to
		// the passed in seriesId
		access(TMP_ENTITLEMENT_OWNER)
		fun ownedDOFsFromSeries(seriesId: UInt64): [&NFT]{ 
			let answer: [&NFT] = []
			let ids = self.ownedIdsFromSeries(seriesId: seriesId)
			for id in ids{ 
				answer.append(self.borrowDOF(id: id)!)
			}
			return answer
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDOF(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let tokenRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = tokenRef as! &NFT
			return nftRef as &{ViewResolver.Resolver}
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
			self.series ={} 
		}
	}
	
	// Represents a DaysOnFlow series
	// An item of this series can be minted in three ways:
	//	  - A list of DayNFT holders have right to mint an item for free
	//	  - A list of WL addresses have right to mint an item for a given price
	//	  - A given quantity is publicly avaiable
	access(all)
	resource DOFSeries: ViewResolver.Resolver{ 
		access(all)
		var wlClaimable: Bool
		
		access(all)
		var publicClaimable: Bool
		
		access(all)
		let description: String
		
		access(all)
		let seriesId: UInt64
		
		access(all)
		let image: String
		
		access(all)
		let smallImage: String
		
		access(all)
		let name: String
		
		access(all)
		var totalSupply: UInt64
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		// Keeps track of the DayNFT holders that have already claimed
		access(self)
		let dayNFTwlClaimed:{ UInt64: Bool}
		
		// Keeps track of the WL addresses that have already claimed
		access(self)
		let wlClaimed:{ Address: Bool}
		
		// WL price
		access(all)
		let wlPrice: UFix64
		
		// Number of items available for the public sale
		access(all)
		let publicSupply: UInt64
		
		// Public price	  
		access(all)
		let publicPrice: UFix64
		
		// Items already minted on the public sale
		access(all)
		var publicMinted: UInt64
		
		// Get number of DayNFT WL that have been claimed vs total
		access(TMP_ENTITLEMENT_OWNER)
		fun dayNFTwlStats(): [Int]{ 
			var claimed = 0
			for wl in self.dayNFTwlClaimed.keys{ 
				if self.dayNFTwlClaimed[wl]!{ 
					claimed = claimed + 1
				}
			}
			return [claimed, self.dayNFTwlClaimed.keys.length]
		}
		
		// Get number of WL that have been claimed vs total
		access(TMP_ENTITLEMENT_OWNER)
		fun wlStats(): [Int]{ 
			var claimed = 0
			for wl in self.wlClaimed.keys{ 
				if self.wlClaimed[wl]!{ 
					claimed = claimed + 1
				}
			}
			return [claimed, self.wlClaimed.keys.length]
		}
		
		// Number of NFT mintable based on holding DayNFTs
		access(TMP_ENTITLEMENT_OWNER)
		fun nbDayNFTwlToMint(address: Address): Int{ 
			// DayNFT collection
			let holder = getAccount(address).capabilities.get<&DayNFT.Collection>(DayNFT.CollectionPublicPath).borrow<&DayNFT.Collection>()
			if holder == nil || !self.wlClaimable{ 
				return 0
			}
			
			// Compute amount due based on number of NFTs detained
			var toMint = 0
			for id in (holder!).getIDs(){ 
				if self.dayNFTwlClaimed[id] != nil && !self.dayNFTwlClaimed[id]!{ 
					toMint = toMint + 1
				}
			}
			return toMint
		}
		
		// Checks if an address is on the white list
		access(TMP_ENTITLEMENT_OWNER)
		fun hasWlToMint(address: Address): Bool{ 
			return self.wlClaimable && self.wlClaimed[address] != nil && !self.wlClaimed[address]!
		}
		
		// Mints items available based on holding DayNFTs
		access(TMP_ENTITLEMENT_OWNER)
		fun mintDayNFTwl(address: Address){ 
			if !self.wlClaimable{ 
				panic("Unclaimable series")
			}
			// DayNFT collection
			let holder = getAccount(address).capabilities.get<&DayNFT.Collection>(DayNFT.CollectionPublicPath).borrow<&DayNFT.Collection>() ?? panic("Could not get receiver reference to the DayNFT Collection")
			for id in holder.getIDs(){ 
				if self.dayNFTwlClaimed[id] != nil && !self.dayNFTwlClaimed[id]!{ 
					self.mint(address: address, saleType: "DayNFT WL")
					self.dayNFTwlClaimed[id] = true
				}
			}
		}
		
		// Mints an item for a whitelisted address
		access(TMP_ENTITLEMENT_OWNER)
		fun mintWl(address: Address, vault: @FlowToken.Vault){ 
			if !self.wlClaimable{ 
				panic("Unclaimable series")
			}
			if vault.balance != self.wlPrice{ 
				panic("Bad WL price amount")
			}
			if self.wlClaimed[address] == nil{ 
				panic("Account not whitelisted")
			}
			if self.wlClaimed[address]!{ 
				panic("Already claimed")
			}
			let rec = DaysOnFlow.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>() ?? panic("Could not borrow a reference to the Flow receiver")
			rec.deposit(from: <-vault)
			self.mint(address: address, saleType: "WL")
			self.wlClaimed[address] = true
		}
		
		// Number of items left for the public sale
		access(TMP_ENTITLEMENT_OWNER)
		fun nbPublicToMint(): Int{ 
			if !self.publicClaimable{ 
				return 0
			}
			return Int(self.publicSupply - self.publicMinted)
		}
		
		// Mint an item on the public sale
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPublic(address: Address, vault: @FlowToken.Vault){ 
			if !self.publicClaimable{ 
				panic("Unclaimable series")
			}
			if vault.balance != self.publicPrice{ 
				panic("Bad public price amount")
			}
			if self.publicMinted >= self.publicSupply{ 
				panic("Nothing left on public sale")
			}
			let rec = DaysOnFlow.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>() ?? panic("Could not borrow a reference to the Flow receiver")
			rec.deposit(from: <-vault)
			self.mint(address: address, saleType: "Public")
			self.publicMinted = self.publicMinted + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.smallImage, path: nil))
			}
			return nil
		}
		
		// Sets whether the series is claimable or not
		access(contract)
		fun setClaimable(wlClaimable: Bool, publicClaimable: Bool){ 
			self.wlClaimable = wlClaimable
			self.publicClaimable = publicClaimable
		}
		
		// Mint an item
		access(contract)
		fun mint(address: Address, saleType: String): UInt64{ 
			// DOF collection
			let receiver = getAccount(address).capabilities.get<&{DaysOnFlow.CollectionPublic}>(DaysOnFlow.CollectionPublicPath).borrow<&{DaysOnFlow.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			let serial = self.totalSupply
			let token <- create NFT(_seriesDescription: self.description, _seriesId: self.seriesId, _seriesImage: self.image, _seriesSmallImage: self.smallImage, _seriesName: self.name, _serial: serial, _saleType: saleType, _metadata: self.metadata)
			let id = token.id
			self.totalSupply = self.totalSupply + 1
			receiver.deposit(token: <-token)
			return id
		}
		
		init(_wlClaimable: Bool, _publicClaimable: Bool, _description: String, _image: String, _smallImage: String, _name: String, _dayNFTwl: [UInt64], // List of DayNFT ids giving right to an item																																						
																																						_wl: [Address], // List of WL addresses																																										
																																										_wlPrice: UFix64, _publicSupply: UInt64, _publicPrice: UFix64, _metadata:{ String: AnyStruct}){ 
			self.wlClaimable = _wlClaimable
			self.publicClaimable = _publicClaimable
			self.description = _description
			self.seriesId = self.uuid
			self.image = _image
			self.smallImage = _smallImage
			self.name = _name
			self.totalSupply = 0
			self.wlPrice = _wlPrice
			self.publicSupply = _publicSupply
			self.publicPrice = _publicPrice
			self.publicMinted = 0
			self.metadata = _metadata
			self.dayNFTwlClaimed ={} 
			for dwl in _dayNFTwl{ 
				self.dayNFTwlClaimed[dwl] = false
			}
			self.wlClaimed ={} 
			for wl in _wl{ 
				self.wlClaimed[wl] = false
			}
		}
	}
	
	// Admin resource used to manage DOF Series
	access(all)
	resource SeriesMinter{ 
		
		// Create a new series
		access(TMP_ENTITLEMENT_OWNER)
		fun createSeries(_wlClaimable: Bool, _publicClaimable: Bool, _description: String, _image: String, _smallImage: String, _name: String, _dayNFTwl: [UInt64], _wl: [Address], _wlPrice: UFix64, _publicSupply: UInt64, _publicPrice: UFix64, _metadata:{ String: AnyStruct}){ 
			let series <- create DOFSeries(_wlClaimable: _wlClaimable, _publicClaimable: _publicClaimable, _description: _description, _image: _image, _smallImage: _smallImage, _name: _name, _dayNFTwl: _dayNFTwl, _wl: _wl, _wlPrice: _wlPrice, _publicSupply: _publicSupply, _publicPrice: _publicPrice, _metadata: _metadata)
			let seriesId = series.seriesId
			DaysOnFlow.allSeries[seriesId] <-! series
		}
		
		// Make a series claimable / not claimable
		access(TMP_ENTITLEMENT_OWNER)
		fun setClaimable(seriesId: UInt64, wlClaimable: Bool, publicClaimable: Bool){ 
			DaysOnFlow.getSeries(seriesId: seriesId).setClaimable(wlClaimable: wlClaimable, publicClaimable: publicClaimable)
		}
		
		// Delete a series
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSeries(seriesId: UInt64){ 
			let series <- DaysOnFlow.allSeries.remove(key: seriesId)
			destroy series
		}
		
		init(){} 
	}
	
	// PUBLIC APIs
	// Get a list of all available series
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllSeries(): [&DOFSeries]{ 
		let answer: [&DOFSeries] = []
		for id in self.allSeries.keys{ 
			let element = (&self.allSeries[id] as &DOFSeries?)!
			answer.append(element)
		}
		return answer
	}
	
	// Get a reference to a specific series
	access(TMP_ENTITLEMENT_OWNER)
	fun getSeries(seriesId: UInt64): &DOFSeries{ 
		return (&self.allSeries[seriesId] as &DOFSeries?)!
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.totalSupply = 0
		self.allSeries <-{} 
		emit ContractInitialized()
		self.CollectionStoragePath = /storage/DOFCollectionStoragePath
		self.CollectionPublicPath = /public/DOFCollectionPublicPath
		self.SeriesMinterStoragePath = /storage/DOFSeriesMinterStoragePath
		let minter <- create SeriesMinter()
		self.account.storage.save(<-minter, to: self.SeriesMinterStoragePath)
	}
}
