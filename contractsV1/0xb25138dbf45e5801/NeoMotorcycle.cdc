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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NeoViews from "./NeoViews.cdc"

//This NFT contract is a grouping of a Founder (that can admin it) and its members. It lives in the Neo account always and could in essence even be just a resource and not an NFT
access(all)
contract NeoMotorcycle: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(teamId: UInt64)
	
	access(all)
	event AchievementAdded(teamId: UInt64, achievement: String)
	
	access(all)
	event NameChanged(teamId: UInt64, name: String)
	
	access(all)
	event PhysicalLinkAdded(teamId: UInt64, link: String)
	
	access(all)
	event FounderWalletChanged(teamId: UInt64, address: Address)
	
	access(all)
	struct Pointer{ 
		access(all)
		let collection: Capability<&{NeoMotorcycle.CollectionPublic}>
		
		access(all)
		let id: UInt64
		
		init(collection: Capability<&{NeoMotorcycle.CollectionPublic}>, id: UInt64){ 
			self.collection = collection
			self.id = id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolve(): &NeoMotorcycle.NFT?{ 
			return (self.collection.borrow()!).borrowNeoMotorcycle(id: self.id)
		}
	}
	
	access(all)
	struct Achievement{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(TMP_ENTITLEMENT_OWNER)
		init(name: String, description: String){ 
			self.name = name
			self.description = description
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(self)
		var name: String
		
		access(all)
		var physicalLink: String?
		
		access(all)
		var founderWalletCap: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		let achievements: [Achievement]
		
		init(id: UInt64){ 
			self.id = id
			self.physicalLink = nil
			self.achievements = []
			self.founderWalletCap = NeoMotorcycle.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
			self.name = "Team #".concat(id.toString())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPhysicalLink(_ link: String){ 
			pre{ 
				self.physicalLink == nil:
					"Cannot change physicalLink"
			}
			emit PhysicalLinkAdded(teamId: self.id, link: link)
			self.physicalLink = link
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setName(_ name: String){ 
			emit NameChanged(teamId: self.id, name: name)
			self.name = name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getName(): String{ 
			return self.name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setNeoFounderWallet(_ wallet: Capability<&{FungibleToken.Receiver}>){ 
			emit FounderWalletChanged(teamId: self.id, address: wallet.address)
			self.founderWalletCap = wallet
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAchievement(_ achievement: Achievement){ 
			emit AchievementAdded(teamId: self.id, achievement: achievement.name)
			self.achievements.append(achievement)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAchievements(): [Achievement]{ 
			return self.achievements
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalty(): NeoViews.Royalties{ 
			let minterRoyalty = NeoViews.Royalty(wallet: NeoMotorcycle.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.10)
			let founderRoyalty = NeoViews.Royalty(wallet: self.founderWalletCap, cut: 0.05)
			return NeoViews.Royalties(royalties:{ "minter": minterRoyalty, "founder": founderRoyalty})
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//Standard NFT collectionPublic interface that can also borrowArt as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(account)
		fun borrowNeoMotorcycle(id: UInt64): &NeoMotorcycle.NFT?
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @NeoMotorcycle.NFT
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
		
		access(account)
		fun borrowNeoMotorcycle(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NeoMotorcycle.NFT
			} else{ 
				return nil
			}
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
	
	access(account)
	fun mint(): @NFT{ 
		NeoMotorcycle.totalSupply = NeoMotorcycle.totalSupply + 1
		var newNFT <- create NFT(id: NeoMotorcycle.totalSupply)
		emit Minted(teamId: newNFT.id)
		return <-newNFT
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.CollectionPrivatePath = /private/neoMotorcycylesCollection
		self.CollectionStoragePath = /storage/neoMotorcycylesCollection
		let account = self.account
		account.storage.save(<-NeoMotorcycle.createEmptyCollection(nftType: Type<@NeoMotorcycle.Collection>()), to: NeoMotorcycle.CollectionStoragePath)
		account.link<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath, target: NeoMotorcycle.CollectionStoragePath)
		emit ContractInitialized()
	}
}
