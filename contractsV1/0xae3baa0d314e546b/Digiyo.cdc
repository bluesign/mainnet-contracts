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

	//SPDX-License-Identifier: MIT
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Digiyo: NonFungibleToken{ 
	// events
	access(all)
	event ContractInitialized()
	
	access(all)
	event AssetCreated(id: UInt32, metadata:{ String: String})
	
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	access(all)
	event SetCreated(setID: UInt32, series: UInt32)
	
	access(all)
	event AssetAddedToSet(setID: UInt32, assetID: UInt32)
	
	access(all)
	event AssetRetiredFromSet(setID: UInt32, assetID: UInt32, numInstances: UInt32)
	
	access(all)
	event SetLocked(setID: UInt32)
	
	access(all)
	event InstanceMinted(instanceID: UInt64, assetID: UInt32, setID: UInt32, serialNumber: UInt32)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event InstanceDestroyed(id: UInt64)
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let digiyoAdminPath: StoragePath
	
	// Series to which a given set belongs
	access(all)
	var currentSeries: UInt32
	
	// dictionary of Asset structs
	access(self)
	var assetDatas:{ UInt32: Asset}
	
	// dictionary of SetData structs
	access(self)
	var setDatas:{ UInt32: SetData}
	
	// dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// the ID used to create Assets. Every time an Asset is created 
	// assetID is assigned to the new Asset's ID then incremented by 1.
	access(all)
	var nextAssetID: UInt32
	
	// the ID that is used to create Sets. Every time a Set is created
	// setID is assigned to the new set's ID then incremented by 1.
	access(all)
	var nextSetID: UInt32
	
	// the total number of Digiyo instances created.
	// Also used as global instance IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// Asset is a Struct holding the metadata for a given asset.
	// Instances reference an Asset for metadata provision.
	access(all)
	struct Asset{ 
		access(all)
		let assetID: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Asset Metadata cannot be empty"
			}
			self.assetID = Digiyo.nextAssetID
			self.metadata = metadata
			Digiyo.nextAssetID = Digiyo.nextAssetID + UInt32(1)
			emit AssetCreated(id: self.assetID, metadata: metadata)
		}
	}
	
	// A Set is a grouping of assets
	// SetData is a struct stored in a public field of the contract.
	access(all)
	struct SetData{ 
		access(all)
		let setID: UInt32 // unique ID for the set
		
		
		access(all)
		let name: String // Name of the Set
		
		
		access(all)
		let series: UInt32 // Series to which a set belongs
		
		
		init(name: String){ 
			pre{ 
				name.length > 0:
					"Set must have a name"
			}
			self.setID = Digiyo.nextSetID
			self.name = name
			self.series = Digiyo.currentSeries
			Digiyo.nextSetID = Digiyo.nextSetID + UInt32(1) // increment setID
			
			emit SetCreated(setID: self.setID, series: self.series)
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// assets from a set and mint instances.
	// If the admin locks the Set, assets can no longer be added, but instances can be minted
	// Set is closed permanently if retireAll() & lock() are called back-to-back
	access(all)
	resource Set{ 
		access(all)
		let setID: UInt32 // unique ID for the set
		
		
		access(all)
		var assets: [UInt32] // Array of assets in set
		
		
		access(all)
		var retired:{ UInt32: Bool} // Indicates mintability
		
		
		access(all)
		var locked: Bool // Indicates if the set is locked
		
		
		// Indicates the number of instances that have been minted per asset in this set
		// When an instance is minted, this value is stored therein
		access(all)
		var numberMintedPerAsset:{ UInt32: UInt32}
		
		init(name: String){ 
			self.setID = Digiyo.nextSetID
			self.assets = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerAsset ={} 
			// Create SetData struct for this Set and store it
			Digiyo.setDatas[self.setID] = SetData(name: name)
		}
		
		// addAsset adds an asset to the set
		// Parameters: assetID: The ID of the asset that is being added
		// Pre-Conditions:
		// The asset needs to exist
		// The set cannot have been locked
		// The set must not yet contain the asset
		access(TMP_ENTITLEMENT_OWNER)
		fun addAsset(assetID: UInt32){ 
			pre{ 
				Digiyo.assetDatas[assetID] != nil:
					"Cannot add the Asset to Set: Asset doesn't exist"
				!self.locked:
					"Cannot add the asset to the Set after the set has been locked"
				self.numberMintedPerAsset[assetID] == nil:
					"The asset has already beed added to the set"
			}
			self.assets.append(assetID) // Add the asset to the array of assets
			
			self.retired[assetID] = false // Open the asset up for minting
			
			self.numberMintedPerAsset[assetID] = 0 // Initialize the instance count to zero
			
			emit AssetAddedToSet(setID: self.setID, assetID: assetID)
		}
		
		// addAssets adds multiple assets to the set
		// Parameters: assetIDs: The IDs of the assets
		access(TMP_ENTITLEMENT_OWNER)
		fun addAssets(assetIDs: [UInt32]){ 
			for asset in assetIDs{ 
				self.addAsset(assetID: asset)
			}
		}
		
		// retireAsset retires a asset from the set so that it can't mint new instances
		// Parameters: assetID: The ID of the asset that is being retired
		// Pre-Conditions:
		// The asset needs to be an existing, unretired asset
		access(TMP_ENTITLEMENT_OWNER)
		fun retireAsset(assetID: UInt32){ 
			pre{ 
				self.retired[assetID] != nil:
					"Cannot retire the Asset: Asset doesn't exist in this set!"
			}
			if !self.retired[assetID]!{ 
				self.retired[assetID] = true
				emit AssetRetiredFromSet(setID: self.setID, assetID: assetID, numInstances: self.numberMintedPerAsset[assetID]!)
			}
		}
		
		// retireAll retires all the assets in the set
		// Afterwards, none of the retired assets will be mintable
		access(TMP_ENTITLEMENT_OWNER)
		fun retireAll(){ 
			for asset in self.assets{ 
				self.retireAsset(assetID: asset)
			}
		}
		
		// lock() locks the set so that no more assets can be added to it
		// Pre-Conditions:
		// The set cannot yet have been locked
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setID: self.setID)
			}
		}
		
		// mintInstance mints a new instance and returns it
		// Parameters: assetID: The ID of the asset which the instance references
		// Pre-Conditions:
		// The asset must exist in the set and be mintable
		// Returns: The instance that was minted
		access(TMP_ENTITLEMENT_OWNER)
		fun mintInstance(assetID: UInt32): @NFT{ 
			pre{ 
				self.retired[assetID] != nil:
					"Cannot mint the instance: This asset doesn't exist"
				!self.retired[assetID]!:
					"Cannot mint the instance from this asset: This asset has been retired"
			}
			let numInAsset = self.numberMintedPerAsset[assetID]! // get number of instances minted for this asset
			
			let newInstance: @NFT <- create NFT(serialNumber: numInAsset + UInt32(1), assetID: assetID, setID: self.setID)
			self.numberMintedPerAsset[assetID] = numInAsset + UInt32(1) // Increment the count of instances minted for this asset
			
			return <-newInstance
		}
		
		// batchMintInstance mints an arbitrary quantity of instances 
		// and returns them as a Collection
		// Parameters: assetID: the ID of the asset from which the instances are minted
		//			 quantity: The quantity of instances to be minted
		// Returns: Collection object that contains all the instances that were minted
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintInstance(assetID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintInstance(assetID: assetID))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
	}
	
	access(all)
	struct InstanceData{ 
		access(all)
		let setID: UInt32 // the ID of the Set
		
		
		access(all)
		let assetID: UInt32 // the ID of the Asset
		
		
		access(all)
		let serialNumber: UInt32 // the order in which this instance was minted
		
		
		init(setID: UInt32, assetID: UInt32, serialNumber: UInt32){ 
			self.setID = setID
			self.assetID = assetID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ // Resource representing the Instance NFTs 
		
		access(all)
		let id: UInt64 // global unique instance ID
		
		
		access(all)
		let data: InstanceData // struct of instance metadata
		
		
		init(serialNumber: UInt32, assetID: UInt32, setID: UInt32){ 
			Digiyo.totalSupply = Digiyo.totalSupply + UInt64(1) // Increment the global instance IDs
			
			self.id = Digiyo.totalSupply
			self.data = InstanceData(setID: setID, assetID: assetID, serialNumber: serialNumber) // set the metadata struct
			
			emit InstanceMinted(instanceID: self.id, assetID: assetID, setID: self.data.setID, serialNumber: self.data.serialNumber)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun name(): String{ 
			let fullName: String = Digiyo.getAssetMetaDataByField(assetID: self.data.assetID, field: "FullName") ?? ""
			let assetType: String = Digiyo.getAssetMetaDataByField(assetID: self.data.assetID, field: "AssetType") ?? ""
			return fullName.concat(" ").concat(assetType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String{ 
			let setName: String = Digiyo.getSetName(setID: self.data.setID) ?? ""
			let serialNumber: String = self.data.serialNumber.toString()
			let seriesNumber: String = Digiyo.getSetSeries(setID: self.data.setID)?.toString() ?? ""
			return "A series ".concat(seriesNumber).concat(" ").concat(setName).concat(" instance with serial number ").concat(serialNumber)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun thumbnail(): String{ 
			let cid: String = Digiyo.getAssetMetaDataByField(assetID: self.data.assetID, field: "CID") ?? ""
			return "https://ipfs.io/ipfs/".concat(cid)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata():{ String: AnyStruct}{ 
			let metadata:{ String: AnyStruct} = Digiyo.getAssetMetaData(assetID: self.data.assetID) ??{} 
			return metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.HTTPFile(url: self.thumbnail()))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "digiYo NFT Edition", number: UInt64(self.data.assetID), max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(UInt64(self.data.serialNumber))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					let cid: String = Digiyo.getAssetMetaDataByField(assetID: self.data.assetID, field: "CID") ?? ""
					return MetadataViews.ExternalURL("https://digiyo.io/assets/".concat(cid))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Digiyo.collectionStoragePath, publicPath: Digiyo.collectionPublicPath, publicCollection: Type<&Digiyo.Collection>(), publicLinkedType: Type<&Digiyo.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Digiyo.createEmptyCollection(nftType: Type<@Digiyo.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let square = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmT2MJQpPNrURCUoei3qUVhsG2Zs6ffsbwZXagUCeCq8BX", path: ""), mediaType: "image/svg+xml")
					let banner = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmQfSjHT9Ew2ZLJsiVYRE9GoTrvN6dobncaTXkm14kFKhj", path: ""), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "digiYo", description: "digiYo is a sports NFT marketplace where users can freely and easily create, customize and mint NFTs that provide unique experiences to their community.", externalURL: MetadataViews.ExternalURL("https://digiyo.io"), squareImage: square, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/digiyo3"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/digiyo.nft"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/batstoiofficial")})
				case Type<MetadataViews.Traits>():
					let excludedTraits: [String] = []
					let metadata:{ String: AnyStruct} = self.metadata()
					let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Admin is an authorization resource permitting execution of certain functions
	access(all)
	resource Admin{ 
		
		// createAsset creates a new Asset struct and stores it
		// Parameters: metadata: A dictionary mapping metadata keys to their values
		// Returns: the ID of the new Asset object
		access(TMP_ENTITLEMENT_OWNER)
		fun createAsset(metadata:{ String: String}): UInt32{ 
			var newAsset = Asset(metadata: metadata) // Create the new Asset
			
			let newID = newAsset.assetID
			Digiyo.assetDatas[newID] = newAsset // Store it in the contract storage
			
			return newID
		}
		
		// createSet creates a new Set resource and returns it
		// so that the caller can store it in their account
		// Parameters: name: The name of the set
		//			 series: The series to which the set
		access(TMP_ENTITLEMENT_OWNER)
		fun createSet(name: String){ 
			var newSet <- create Set(name: name) // Create the new Set
			
			Digiyo.sets[newSet.setID] <-! newSet
		}
		
		// borrowSet returns a reference to a set in the Digiyo
		// contract so that the admin can call methods on it
		// Parameters: setID: The ID of the set referenced
		// Returns: A reference to the set with fields and methods exposed
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSet(setID: UInt32): &Set{ 
			pre{ 
				Digiyo.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&Digiyo.sets[setID] as &Set?)!
		}
		
		// startNewSeries ends the current series by incrementing currentSeries
		// Returns: The new series number
		access(TMP_ENTITLEMENT_OWNER)
		fun startNewSeries(): UInt32{ 
			Digiyo.currentSeries = Digiyo.currentSeries + UInt32(1)
			emit NewSeriesStarted(newCurrentSeries: Digiyo.currentSeries)
			return Digiyo.currentSeries
		}
		
		// createNewAdmin creates a new Admin Resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This interface allows the admin or other users to deposit into a users collection
	access(all)
	resource interface DigiyoNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowInstance(id: UInt64): &Digiyo.NFT?{ 
			post{ // If not nil should match argument 
				
				result == nil || result?.id == id:
					"Cannot borrow Instance reference: The ID of the returned reference is incorrect"
			}
		}
	//pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} 
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	access(all)
	resource Collection: DigiyoNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary of Instance conforming tokens
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Instance from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Instance does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes an Instance and adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Digiyo.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token // add the new token to the dictionary
			
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ // iterate through the keys in the collection and deposit each one 
				
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// getIDs returns an array of the IDs in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to an instance in the collection
		// so that the caller can read its ID
		// Parameters: id: The ID of the instance being referenced
		// Returns: A reference to the instance
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowInstance Returns a borrowed reference to an instance in the collection
		// essentially a more robust version of the borrowNFT function (allows method calls)
		// Parameters: id: The ID of the instance to get the reference for
		// Returns: A reference to the instance
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowInstance(id: UInt64): &Digiyo.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Digiyo.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let digiyoNFT = nft as! &Digiyo.NFT
			return digiyoNFT as &{ViewResolver.Resolver}
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
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained therin are also destroyed
	}
	
	// createEmptyCollection creates a new, empty Collection object
	// Once a user has a Collection in storage, they can receive instances
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Digiyo.Collection()
	}
	
	// getAllAssets returns all the assets in digiyo
	// Returns: An array of all the assets that have been created
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllAssets(): [Digiyo.Asset]{ 
		return Digiyo.assetDatas.values
	}
	
	// getAssetMetaData returns the metadata associated with a given asset
	// Parameters: assetID: The id of the asset
	// Returns: The metadata as a String
	access(TMP_ENTITLEMENT_OWNER)
	fun getAssetMetaData(assetID: UInt32):{ String: String}?{ 
		return self.assetDatas[assetID]?.metadata
	}
	
	// getAssetMetaDataByField returns the value in a given field of the metadata
	// Parameters: assetID: The id of the asset
	//			 field: The field (i.e. metadata key) sought
	// Returns: The metadata field as a String Optional
	access(TMP_ENTITLEMENT_OWNER)
	fun getAssetMetaDataByField(assetID: UInt32, field: String): String?{ 
		if let asset = Digiyo.assetDatas[assetID]{ 
			return asset.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getSetName returns the name of the set whose ID is passed.
	// Parameters: setID: The id of the set
	// Returns: The name of the set
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetName(setID: UInt32): String?{ 
		return Digiyo.setDatas[setID]?.name
	}
	
	// getSetSeries returns the of the set whose ID is passed
	// Parameters: setID: The id of the set
	// Returns: The series that the set belongs to
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetSeries(setID: UInt32): UInt32?{ 
		return Digiyo.setDatas[setID]?.series
	}
	
	// getSetIDsByName returns the IDs of the set whose name is passed.
	// Parameters: setName: The name of the set
	// Returns: An array of the IDs of the set if it exists, or nil if doesn't
	access(TMP_ENTITLEMENT_OWNER)
	fun getSetIDsByName(setName: String): [UInt32]?{ 
		var setIDs: [UInt32] = []
		for setData in Digiyo.setDatas.values{ // search setDatas for name 
			
			if setName == setData.name{ 
				setIDs.append(setData.setID) // if the name is found, return the ID
			
			}
		}
		if setIDs.length == 0{ // If name not found, return nil 
			
			return nil
		} else{ 
			return setIDs
		}
	}
	
	// getAssetsInSet returns a list of asset IDs in the set whose ID is passed
	// Parameters: setID: The id of the set
	// Returns: An array of asset IDs
	access(TMP_ENTITLEMENT_OWNER)
	fun getAssetsInSet(setID: UInt32): [UInt32]?{ 
		return Digiyo.sets[setID]?.assets
	}
	
	// isEditionRetired returns a boolean indicating whether a set/asset combo
	//				  (i.e. an edition) is retired. If retired, it still remains
	//				  in the set, but instances can no longer be minted from it.
	// Parameters: setID: The id of the set
	//			 assetID: The id of the asset
	// Returns: Boolean indicating whether the edition is retired
	access(TMP_ENTITLEMENT_OWNER)
	fun isEditionRetired(setID: UInt32, assetID: UInt32): Bool?{ 
		// remove the set from the dictionary to get its field
		if let setToRead <- Digiyo.sets.remove(key: setID){ 
			let retired = setToRead.retired[assetID]
			Digiyo.sets[setID] <-! setToRead
			return retired
		} else{ 
			return nil
		}
	}
	
	// isSetLocked returns a boolean indicating whether a set is locked.
	//			 If locked, new assets can no longer be added to the set,
	//			 but instances can still be minted from assets therein.
	// Parameters: setID: The id of the set
	// Returns: Boolean indicating if the set is locked or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isSetLocked(setID: UInt32): Bool?{ 
		return Digiyo.sets[setID]?.locked
	}
	
	// getNumInstancesInEdition return the number of instances minted from an edition.
	// Parameters: setID: The id of the set
	//			 assetID: The id of the asset
	// Returns: The total number of instances minted from an edition
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumInstancesInEdition(setID: UInt32, assetID: UInt32): UInt32?{ 
		if let setToRead <- Digiyo.sets.remove(key: setID){ 
			let amount = setToRead.numberMintedPerAsset[assetID]
			Digiyo.sets[setID] <-! setToRead
			return amount
		} else{ 
			return nil
		}
	}
	
	init(){ 
		self.collectionPublicPath = /public/DigiyoNFTCollection
		self.collectionStoragePath = /storage/DigiyoNFTCollection
		self.digiyoAdminPath = /storage/DigiyoAdmin
		self.currentSeries = 0
		self.assetDatas ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextAssetID = 1
		self.nextSetID = 1
		self.totalSupply = 0
		self.account.storage.save<@Collection>(<-create Collection(), to: self.collectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{DigiyoNFTCollectionPublic}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		self.account.storage.save<@Admin>(<-create Admin(), to: self.digiyoAdminPath)
		emit ContractInitialized()
	}
}
