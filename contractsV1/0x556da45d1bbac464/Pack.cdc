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

	// SPDX-License-Identifier: Apache License 2.0
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Elvn from "../0x3084a96e617d3b0a/Elvn.cdc"

import Moments from "../0xcbe56896caed3fd0/Moments.cdc"

// Pack
//
// A contract made to match Pack Token and [Moments] using `unsafeRandom`
// 
// caution
// 1. The number of `salePacks` and `momentsListCandidate` may be different.
// 2. `salePacks` is reduced in length when the user purchases a pack.
// 3. `momentsListCandidate` is decremented when the user opens the pack.
access(all)
contract Pack{ 
	access(self)
	let vault: @Elvn.Vault
	
	access(self)
	let momentsListCandidate: @{UInt64: [[Moments.NFT]]}
	
	access(self)
	let salePacks: @{UInt64: [Pack.Token]}
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	event CreatePackToken(packId: UInt64, releaseId: UInt64)
	
	access(all)
	event BuyPack(packId: UInt64, price: UFix64)
	
	access(all)
	event OpenPack(packId: UInt64, momentsIds: [UInt64], address: Address?)
	
	access(all)
	event Deposit(releaseId: UInt64, id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(releaseId: UInt64, id: UInt64, from: Address?)
	
	access(all)
	resource Token{ 
		access(all)
		let id: UInt64
		
		access(all)
		let releaseId: UInt64
		
		access(all)
		let price: UFix64
		
		access(all)
		let momentsPerCount: UInt64
		
		access(self)
		var opened: Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPacks(): @[Moments.NFT]{ 
			pre{ 
				Pack.getMomentsListRemainingCount(releaseId: self.releaseId) > 0:
					"Not enough moments in Pack Contract"
				UInt64(Pack.getMomentsLength(releaseId: self.releaseId)) == self.momentsPerCount:
					"Not equal momentsPerCount"
				self.isAvailable():
					"Pack Tokens already used"
			}
			let momentsListLength = Pack.getMomentsListRemainingCount(releaseId: self.releaseId)
			let randomIndex = revertibleRandom<UInt64>() % UInt64(momentsListLength)
			let momentsListCandidateRef =
				(&Pack.momentsListCandidate[self.releaseId] as &[[Moments.NFT]]?)!
			let momentsList <- momentsListCandidateRef.remove(at: randomIndex)
			let momentsIds: [UInt64] = []
			while momentsIds.length < momentsList.length{ 
				let momentsRef = &momentsList[momentsIds.length] as &Moments.NFT
				momentsIds.append(momentsRef.id)
			}
			self.opened = true
			emit OpenPack(packId: self.id, momentsIds: momentsIds, address: self.owner?.address)
			return <-momentsList
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isAvailable(): Bool{ 
			return !self.opened
		}
		
		init(tokenId: UInt64, releaseId: UInt64, price: UFix64, momentsPerCount: UInt64){ 
			self.id = tokenId
			self.releaseId = releaseId
			self.price = price
			self.momentsPerCount = momentsPerCount
			self.opened = false
		}
	}
	
	access(all)
	resource interface PackCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @Pack.Token)
	}
	
	access(all)
	resource Collection: PackCollectionPublic{ 
		// releaseId: [pack]
		access(all)
		var ownedPacks: @{UInt64: [Pack.Token]}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt64]{ 
			let ids: [UInt64] = []
			for releaseId in self.ownedPacks.keys{ 
				let ownedPack = (&self.ownedPacks[releaseId] as &[Pack.Token]?)!
				var i = 0
				while i < ownedPack.length{ 
					let pack = ownedPack[i] as &Pack.Token
					if pack.isAvailable(){ 
						ids.append(pack.id)
					}
					i = i + 1
				}
			}
			return ids
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReleaseIds(): [UInt64]{ 
			let releaseIds: [UInt64] = []
			for releaseId in self.ownedPacks.keys{ 
				let ownedPack = (&self.ownedPacks[releaseId] as &[Pack.Token]?)!
				let isAvailable = Pack.isAvailablePackList(packList: ownedPack)
				if isAvailable{ 
					releaseIds.append(releaseId)
				}
			}
			return releaseIds
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawReleaseId(releaseId: UInt64): @Pack.Token{ 
			pre{ 
				self.ownedPacks[releaseId] != nil:
					"missing Pack releaseId: ".concat(releaseId.toString())
			}
			let tokenListRef = (&self.ownedPacks[releaseId] as &[Pack.Token]?)!
			if tokenListRef.length == 0{ 
				return panic("Not enough Pack releaseId: ".concat(releaseId.toString()))
			}
			let token <- tokenListRef.remove(at: 0)
			emit Withdraw(releaseId: releaseId, id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: UInt64): @Pack.Token{ 
			for key in self.ownedPacks.keys{ 
				let tokenList = (&self.ownedPacks[key] as &[Pack.Token]?)!
				if tokenList.length > 0{ 
					var i = 0
					while i < tokenList.length{ 
						let token = tokenList[i] as &Pack.Token
						if token.id == id{ 
							let token <- tokenList.remove(at: i)
							emit Withdraw(releaseId: token.releaseId, id: token.id, from: self.owner?.address)
							return <-token
						}
						i = i + 1
					}
				}
			}
			return panic("Not found id: ".concat(id.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @Pack.Token){ 
			let id = token.id
			let releaseId = token.releaseId
			if self.ownedPacks[releaseId] == nil{ 
				self.ownedPacks[releaseId] <-! [<-token]
			} else{ 
				let packListRef = (&self.ownedPacks[releaseId] as &[Pack.Token]?)!
				packListRef.append(<-token)
			}
			emit Deposit(releaseId: releaseId, id: id, to: self.owner?.address)
		}
		
		init(){ 
			self.ownedPacks <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun isPackExists(releaseId: UInt64): Bool{ 
		return self.salePacks[releaseId] != nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getPackRemainingCount(releaseId: UInt64): Int{ 
		pre{ 
			self.isPackExists(releaseId: releaseId):
				"Not found releaseId: ".concat(releaseId.toString())
		}
		let packsRef = (&self.salePacks[releaseId] as &[Pack.Token]?)!
		return packsRef.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getMomentsListRemainingCount(releaseId: UInt64): Int{ 
		pre{ 
			self.isPackExists(releaseId: releaseId):
				"Not found releaseId: ".concat(releaseId.toString())
		}
		let momentsListCandidateRef = (&self.momentsListCandidate[releaseId] as &[[Moments.NFT]]?)!
		return momentsListCandidateRef.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getMomentsLength(releaseId: UInt64): Int{ 
		pre{ 
			self.getMomentsListRemainingCount(releaseId: releaseId) > 0:
				"Not enough moments in Pack Contract"
		}
		let momentsListCandidateRef = (&self.momentsListCandidate[releaseId] as &[[Moments.NFT]]?)!
		let momentsListRef = momentsListCandidateRef[0] as &[Moments.NFT]
		return momentsListRef.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getOnSaleReleaseIds(): [UInt64]{ 
		let releaseIds: [UInt64] = []
		for releaseId in self.salePacks.keys{ 
			let remainingCount = self.getPackRemainingCount(releaseId: releaseId)
			if remainingCount > 0{ 
				releaseIds.append(releaseId)
			}
		}
		return releaseIds
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getPackPrice(releaseId: UInt64): UFix64{ 
		pre{ 
			self.getPackRemainingCount(releaseId: releaseId) > 0:
				"Sold out pack"
		}
		let packsRef = (&self.salePacks[releaseId] as &[Pack.Token]?)!
		let packRef = packsRef[0] as &Pack.Token
		return packRef.price
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun buyPack(releaseId: UInt64, vault: @Elvn.Vault): @Pack.Token{ 
		pre{ 
			self.getPackPrice(releaseId: releaseId) == vault.balance:
				"Not enough balance"
		}
		let balance = vault.balance
		self.vault.deposit(from: <-vault)
		let salePacksRef = (&self.salePacks[releaseId] as &[Pack.Token]?)!
		let pack <- salePacksRef.remove(at: 0)
		emit BuyPack(packId: pack.id, price: pack.price)
		return <-pack
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addItem(pack: @Pack.Token, momentsList: @[Moments.NFT]){ 
			pre{ 
				pack.momentsPerCount == UInt64(momentsList.length):
					"Not equal momentsPerCount"
			}
			let releaseId = pack.releaseId
			if Pack.salePacks[releaseId] == nil{ 
				let packs: @[Pack.Token] <- [<-pack]
				Pack.salePacks[releaseId] <-! packs
			} else{ 
				let packsRef = (&Pack.salePacks[releaseId] as &[Pack.Token]?)!
				packsRef.append(<-pack)
			}
			if Pack.momentsListCandidate[releaseId] == nil{ 
				let moments: @[[Moments.NFT]] <- [<-momentsList]
				Pack.momentsListCandidate[releaseId] <-! moments
			} else{ 
				let momentsRef = (&Pack.momentsListCandidate[releaseId] as &[[Moments.NFT]]?)!
				momentsRef.append(<-momentsList)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createPackToken(
			releaseId: UInt64,
			price: UFix64,
			momentsPerCount: UInt64
		): @Pack.Token{ 
			let pack <-
				create Pack.Token(
					tokenId: Pack.totalSupply,
					releaseId: releaseId,
					price: price,
					momentsPerCount: momentsPerCount
				)
			Pack.totalSupply = Pack.totalSupply + 1
			emit CreatePackToken(packId: pack.id, releaseId: releaseId)
			return <-pack
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64?): @{FungibleToken.Vault}{ 
			if let amount = amount{ 
				return <-Pack.vault.withdraw(amount: amount)
			} else{ 
				let balance = Pack.vault.balance
				return <-Pack.vault.withdraw(amount: balance)
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isAvailablePackList(packList: &[Pack.Token]): Bool{ 
		var i = 0
		while i < packList.length{ 
			let pack = packList[i] as &Pack.Token
			if pack.isAvailable(){ 
				return true
			}
			i = i + 1
		}
		return false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Pack.Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/sportiumPackCollection
		self.CollectionPublicPath = /public/sportiumPackCollection
		self.momentsListCandidate <-{} 
		self.salePacks <-{} 
		self.vault <- Elvn.createEmptyVault(vaultType: Type<@Elvn.Vault>()) as! @Elvn.Vault
		self.totalSupply = 0
		self.account.storage.save(<-create Administrator(), to: /storage/sportiumPackAdministrator)
	}
}
