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

import ThulToken from "./ThulToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract DimensionX: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var customSupply: UInt64
	
	access(all)
	var genesisSupply: UInt64
	
	access(all)
	var commonSupply: UInt64
	
	access(all)
	var totalBurned: UInt64
	
	access(all)
	var customBurned: UInt64
	
	access(all)
	var genesisBurned: UInt64
	
	access(all)
	var commonBurned: UInt64
	
	access(all)
	var thulMintPrice: UFix64
	
	access(all)
	var thulMintEnabled: Bool
	
	access(all)
	var metadataUrl: String
	
	access(all)
	var stakedNfts:{ UInt64: Address} // map nftId -> ownerAddress
	
	
	access(all)
	var crypthulhuAwake: UFix64
	
	access(all)
	var crypthulhuSleepTime: UFix64
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun crypthulhuSleeps(): Bool{ 
		return getCurrentBlock().timestamp - DimensionX.crypthulhuAwake > DimensionX.crypthulhuSleepTime
	}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, type: UInt8)
	
	access(all)
	event Burn(id: UInt64, type: UInt8)
	
	access(all)
	event Stake(id: UInt64, to: Address?)
	
	access(all)
	event Unstake(id: UInt64, from: Address?)
	
	access(all)
	event MinterCreated()
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	enum NFTType: UInt8{ 
		access(all)
		case custom
		
		access(all)
		case genesis
		
		access(all)
		case common
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let type: NFTType
		
		init(id: UInt64, type: NFTType){ 
			self.id = id
			self.type = type
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(DimensionX.metadataUrl.concat(self.id.toString()))
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "DimensionX #".concat(self.id.toString()), description: "A Superhero capable of doing battle in the DimensionX Game!", thumbnail: MetadataViews.HTTPFile(url: DimensionX.metadataUrl.concat("i/").concat(self.id.toString()).concat(".png")))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					royalties.append(MetadataViews.Royalty(receiver: DimensionX.account.capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: UFix64(0.10), description: "Crypthulhu royalties"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DimensionX.CollectionStoragePath, publicPath: DimensionX.CollectionPublicPath, publicCollection: Type<&DimensionX.Collection>(), publicLinkedType: Type<&DimensionX.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DimensionX.createEmptyCollection(nftType: Type<@DimensionX.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Dimension X", description: "Dimension X is a Free-to-Play, Play-to-Earn strategic role playing game on the Flow blockchain set in the Dimension X comic book universe, where a pan-dimensional explosion created super powered humans, aliens and monsters with radical and terrifying superpowers!", externalURL: MetadataViews.ExternalURL("https://dimensionxnft.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionX.metadataUrl.concat("collection_image.png")), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionX.metadataUrl.concat("collection_banner.png")), mediaType: "image/png"), socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/BK5yAD6VQg"), "twitter": MetadataViews.ExternalURL("https://twitter.com/DimensionX_NFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDimensionX(id: UInt64): &DimensionX.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DimensionX reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stake(id: UInt64){ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot stake: you can only stake tokens that you own"
				!DimensionX.stakedNfts.containsKey(id):
					"Cannot stake: the token is already staked"
			}
			let ownerAddress = self.owner?.address
			DimensionX.stakedNfts[id] = ownerAddress
			emit Stake(id: id, to: ownerAddress)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(id: UInt64){ 
			pre{ 
				DimensionX.stakedNfts.containsKey(id):
					"Cannot unstake: the token is not staked"
				self.ownedNFTs.containsKey(id):
					"Cannot unstake: you can only unstake tokens that you own"
				DimensionX.crypthulhuSleeps():
					"Cannot unstake: you can only unstake through the game at this moment"
			}
			let ownerAddress = self.owner?.address
			DimensionX.stakedNfts.remove(key: id)
			emit Unstake(id: id, from: ownerAddress)
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				!DimensionX.stakedNfts.containsKey(withdrawID):
					"Cannot withdraw: the token is staked"
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @DimensionX.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDimensionX(id: UInt64): &DimensionX.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DimensionX.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dmxNft = nft as! &DimensionX.NFT
			return dmxNft as &{ViewResolver.Resolver}
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
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// range if possible
		access(TMP_ENTITLEMENT_OWNER)
		fun getNextCustomID(): UInt64{ 
			var nextId = DimensionX.customSupply + UInt64(1)
			return nextId <= 1000 ? nextId : self.getNextCommonID()
		}
		
		// Determine the next available ID for genesis NFTs and use the reserved
		// range if possible
		access(TMP_ENTITLEMENT_OWNER)
		fun getNextGenesisID(): UInt64{ 
			var nextId = UInt64(1000) + DimensionX.genesisSupply + UInt64(1)
			return nextId <= 11000 ? nextId : panic("Cannot mint more than 10000 genesis NFTs")
		}
		
		// Determine the next available ID for the rest of NFTs and take into
		// account the custom NFTs that have been minted outside of the reserved
		// range
		access(TMP_ENTITLEMENT_OWNER)
		fun getNextCommonID(): UInt64{ 
			var customIdOverflow = Int256(DimensionX.customSupply) - Int256(1000)
			customIdOverflow = customIdOverflow > 0 ? customIdOverflow : 0
			return 11000 + DimensionX.commonSupply + UInt64(customIdOverflow) + UInt64(1)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintCustomNFT(recipient: &Collection){ 
			var nextId = self.getNextCustomID()
			
			// Update supply counters
			DimensionX.customSupply = DimensionX.customSupply + UInt64(1)
			DimensionX.totalSupply = DimensionX.totalSupply + UInt64(1)
			self.mint(recipient: recipient, id: nextId, type: DimensionX.NFTType.custom)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintGenesisNFT(recipient: &Collection){ 
			// Determine the next available ID
			var nextId = self.getNextGenesisID()
			
			// Update supply counters
			DimensionX.genesisSupply = DimensionX.genesisSupply + UInt64(1)
			DimensionX.totalSupply = DimensionX.totalSupply + UInt64(1)
			self.mint(recipient: recipient, id: nextId, type: DimensionX.NFTType.genesis)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &Collection){ 
			// Determine the next available ID
			var nextId = self.getNextCommonID()
			
			// Update supply counters
			DimensionX.commonSupply = DimensionX.commonSupply + UInt64(1)
			DimensionX.totalSupply = DimensionX.totalSupply + UInt64(1)
			self.mint(recipient: recipient, id: nextId, type: DimensionX.NFTType.common)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintStakedNFT(recipient: &Collection){ 
			var nextId = self.getNextCommonID()
			self.mintNFT(recipient: recipient)
			let ownerAddress = recipient.owner?.address
			DimensionX.stakedNfts[nextId] = ownerAddress
			emit Stake(id: nextId, to: ownerAddress)
		}
		
		access(self)
		fun mint(recipient: &Collection, id: UInt64, type: DimensionX.NFTType){ 
			// create a new NFT
			var newNFT <- create NFT(id: id, type: type)
			switch newNFT.type{ 
				case NFTType.custom:
					emit Mint(id: id, type: UInt8(0))
				case NFTType.genesis:
					emit Mint(id: id, type: UInt8(1))
				case NFTType.common:
					emit Mint(id: id, type: UInt8(2))
			}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun unstake(id: UInt64){ 
			pre{ 
				DimensionX.stakedNfts.containsKey(id):
					"Cannot unstake: the token is not staked"
			}
			let ownerAddress = DimensionX.stakedNfts[id]
			DimensionX.stakedNfts.remove(key: id)
			emit Unstake(id: id, from: ownerAddress)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMetadataUrl(url: String){ 
			DimensionX.metadataUrl = url
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setThulMintPrice(price: UFix64){ 
			DimensionX.thulMintPrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setThulMintEnabled(enabled: Bool){ 
			DimensionX.thulMintEnabled = enabled
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNFTMinter(): @NFTMinter{ 
			emit MinterCreated()
			return <-create NFTMinter()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCrypthulhuSleepTime(time: UFix64){ 
			DimensionX.crypthulhuSleepTime = time
			self.crypthulhuAwake()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun crypthulhuAwake(){ 
			DimensionX.crypthulhuAwake = getCurrentBlock().timestamp
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mint(recipient: &Collection, paymentVault: @ThulToken.Vault){ 
		pre{ 
			DimensionX.thulMintEnabled:
				"Cannot mint: $THUL minting is not enabled"
			paymentVault.balance >= DimensionX.thulMintPrice:
				"Insufficient funds"
		}
		let minter = self.account.storage.borrow<&NFTMinter>(from: self.MinterStoragePath)!
		minter.mintNFT(recipient: recipient)
		let contractVault = self.account.storage.borrow<&ThulToken.Vault>(from: ThulToken.VaultStoragePath)!
		contractVault.deposit(from: <-paymentVault)
	}
	
	init(){ 
		// Initialize supply counters
		self.totalSupply = 0
		self.customSupply = 0
		self.genesisSupply = 0
		self.commonSupply = 0
		
		// Initialize burned counters
		self.totalBurned = 0
		self.customBurned = 0
		self.genesisBurned = 0
		self.commonBurned = 0
		self.thulMintPrice = UFix64(120)
		self.thulMintEnabled = false
		self.metadataUrl = "https://www.dimensionx.com/api/nfts/"
		self.stakedNfts ={} 
		
		// Initialize Dead Man's Switch
		self.crypthulhuAwake = getCurrentBlock().timestamp
		self.crypthulhuSleepTime = UFix64(60 * 60 * 24 * 30)
		
		// Set the named paths
		self.CollectionStoragePath = /storage/dmxCollection
		self.CollectionPublicPath = /public/dmxCollection
		self.AdminStoragePath = /storage/dmxAdmin
		self.MinterStoragePath = /storage/dmxMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&DimensionX.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let admin <- create Admin()
		let minter <- admin.createNFTMinter()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
