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

import LampionsPack from "./LampionsPack.cdc"

/*
- Can be Player or Team moment
*/

access(all)
contract LampionsNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, address: Address)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var nounce: UInt64
		
		access(all)
		let play_id: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let badges:{ String: String}
		
		init(play_id: UInt64, edition: UInt64){ 
			pre{ 
				LampionsNFT.plays.containsKey(play_id):
					"Play must be present"
			}
			self.nounce = 0
			self.id = self.uuid
			self.play_id = play_id
			self.edition = edition
			self.badges ={} 
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<LampionsPack.PackRevealData>()]
		}
		
		//todo: externalURL
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let play = LampionsNFT.getPlay(self.play_id)!
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: LampionsNFT.CollectionStoragePath, publicPath: LampionsNFT.CollectionPublicPath, publicCollection: Type<&LampionsNFT.Collection>(), publicLinkedType: Type<&LampionsNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-LampionsNFT.createEmptyCollection(nftType: Type<@LampionsNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("http://lampions.onefootbal.com")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://miro.medium.com/fit/c/176/176/1*hzfP51MATg3et5vghYy1uQ.png"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://miro.medium.com/fit/c/176/176/1*hzfP51MATg3et5vghYy1uQ.png"), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/onefootball")}
					return MetadataViews.NFTCollectionDisplay(name: "Lampions", description: "Lampions by OneFootball", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Display>():
					return play.asDisplay()
				case Type<MetadataViews.Medias>():
					return play.getMedias()
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: "play", number: self.edition, max: play.serials)])
				case Type<MetadataViews.Rarity>():
					return MetadataViews.Rarity(score: nil, max: nil, description: play.rarity)
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits(play.getTraits())
				case Type<LampionsPack.PackRevealData>():
					let display = play.asDisplay()
					return LampionsPack.PackRevealData({"play_id": self.play_id.toString(), "image": display.thumbnail.uri(), "name": display.name, "rarity": play.rarity, "serial": self.edition.toString(), "maxSerial": play.serials.toString(), "id": self.id.toString()})
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun increaseNounce(){ 
			self.nounce = self.nounce + 1
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @NFT
			let id: UInt64 = token.id
			//TODO: add nounce and emit better event the first time it is moved.
			token.increaseNounce()
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
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let lampions = nft as! &NFT
			return lampions as &{ViewResolver.Resolver}
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
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, play_id: UInt64, edition: UInt64){ 
		pre{ 
			recipient.owner != nil:
				"Recipients NFT collection is not owned"
		}
		LampionsNFT.totalSupply = LampionsNFT.totalSupply + 1
		// create a new NFT
		var newNFT <- create NFT(play_id: play_id, edition: edition)
		recipient.deposit(token: <-newNFT)
	}
	
	access(all)
	struct Game{ 
		access(all)
		let id: UInt64
		
		access(all)
		let homeTeamName: String
		
		access(all)
		let awayTeamName: String
		
		access(all)
		let derbyID: String
		
		access(all)
		let competition: String
		
		access(all)
		let season: String
		
		access(all)
		let date: UFix64
		
		access(all)
		let matchday: UInt64
		
		access(all)
		let highlightedTeam: String
		
		access(all)
		let homeScore: UInt64
		
		access(all)
		let awayScore: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, homeTeamName: String, awayTeamName: String, derbyID: String, competition: String, season: String, date: UFix64, matchday: UInt64, highlightedTeam: String, homeScore: UInt64, awayScore: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.homeTeamName = homeTeamName
			self.awayTeamName = awayTeamName
			self.derbyID = derbyID
			self.competition = competition
			self.season = season
			self.date = date
			self.matchday = matchday
			self.highlightedTeam = highlightedTeam
			
			//are you sure you do not want this as two int numbers so you can create filters that can do math on them in market?
			self.homeScore = homeScore
			self.awayScore = awayScore
			self.metadata = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTraits(): [MetadataViews.Trait]{ 
			var winner = "tie"
			if self.homeScore > self.awayScore{ 
				winner = "home"
			} else if self.homeScore < self.awayScore{ 
				winner = "away"
			}
			let views = [MetadataViews.Trait(name: "HomeTeam", value: self.homeTeamName, displayType: "String", rarity: nil), MetadataViews.Trait(name: "AwayTeam", value: self.awayTeamName, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Competition", value: self.competition, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Season", value: self.season, displayType: "String", rarity: nil), MetadataViews.Trait(name: "MatchDate", value: self.date, displayType: "Date", rarity: nil), MetadataViews.Trait(name: "MatchDay", value: self.matchday, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "HomeScore", value: self.homeScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "AwayScore", value: self.awayScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "Score", value: self.homeScore.toString().concat("-").concat(self.awayScore.toString()), displayType: "String", rarity: nil)]
			if self.derbyID != ""{ 
				views.append(MetadataViews.Trait(name: "DerbyID", value: self.derbyID, displayType: "String", rarity: nil))
			}
			return views
		}
	}
	
	access(self)
	let games:{ UInt64: Game}
	
	access(account)
	fun addGame(_ game: Game){ 
		self.games[game.id] = game
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getGames():{ UInt64: Game}{ 
		return self.games
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getGame(_ id: UInt64): Game?{ 
		return self.games[id]
	}
	
	access(all)
	struct License{ 
		access(all)
		let id: UInt64
		
		access(all)
		let note: String
		
		access(all)
		let copyright: String
		
		init(id: UInt64, note: String, copyright: String){ 
			self.id = id
			self.note = note
			self.copyright = copyright
		}
	}
	
	access(self)
	let licenses:{ UInt64: License}
	
	access(account)
	fun addLicense(_ player: License){ 
		self.licenses[player.id] = player
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLicenses():{ UInt64: License}{ 
		return self.licenses
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLicense(_ id: UInt64): License?{ 
		return self.licenses[id]
	}
	
	/// A struct to hold information about a play
	access(all)
	struct Play{ 
		access(all)
		let id: UInt64
		
		access(all)
		let gameID: UInt64
		
		access(all)
		let playersInvolved:{ String: UInt64}
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let imageIpfsHash: String
		
		access(all)
		let videoIpfsHash: String
		
		access(all)
		let type: String
		
		access(all)
		let rarity: String
		
		access(all)
		let serials: UInt64
		
		access(all)
		let half: String
		
		access(all)
		let time: UInt64
		
		access(all)
		let homeScore: UInt64
		
		access(all)
		let awayScore: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, gameID: UInt64, playersInvolved:{ String: UInt64}, title: String, description: String, imageIpfsHash: String, videoIpfsHash: String, type: String, rarity: String, serials: UInt64, half: String, time: UInt64, homeScore: UInt64, awayScore: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.gameID = gameID
			self.playersInvolved = playersInvolved
			self.metadata = metadata
			self.title = title
			self.description = description
			self.imageIpfsHash = imageIpfsHash
			self.videoIpfsHash = videoIpfsHash
			self.type = type
			self.rarity = rarity
			self.serials = serials
			self.half = half
			self.time = time
			self.homeScore = homeScore
			self.awayScore = awayScore
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTraits(): [MetadataViews.Trait]{ 
			let traits = [MetadataViews.Trait(name: "PlayHalf", value: self.half, displayType: "String", rarity: nil), MetadataViews.Trait(name: "PlayTime", value: self.time, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "PlayHomeScore", value: self.homeScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "PlayAwayScore", value: self.awayScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "PlayScore", value: self.homeScore.toString().concat("-").concat(self.awayScore.toString()), displayType: "String", rarity: nil)]
			traits.appendAll((LampionsNFT.getGame(self.gameID)!).getTraits())
			for role in self.playersInvolved.keys{ 
				let player = LampionsNFT.getPlayer(self.playersInvolved[role]!)!
				var prefix = role
				if role == "Main"{ 
					prefix = ""
				}
				traits.appendAll(player.getTraits(prefix))
			}
			return traits
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMedias(): MetadataViews.Medias{ 
			let imageFile = MetadataViews.IPFSFile(cid: self.imageIpfsHash, path: "thumbnail.png")
			return MetadataViews.Medias([self.getVideo(), MetadataViews.Media(file: imageFile, mediaType: "image/png")])
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun asDisplay(): MetadataViews.Display{ 
			let imageFile = MetadataViews.IPFSFile(cid: self.imageIpfsHash, path: "thumbnail.png")
			return MetadataViews.Display(name: self.title, description: self.description, thumbnail: imageFile)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVideo(): MetadataViews.Media{ 
			let file = MetadataViews.IPFSFile(cid: self.videoIpfsHash, path: "video.mp4")
			return MetadataViews.Media(file: file, mediaType: self.getVideoMediaType())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVideoMediaType(): String{ 
			let videoMediaType = self.metadata["videoMediaType"]
			return videoMediaType ?? "video/mp4"
		}
	}
	
	access(self)
	let plays:{ UInt64: Play}
	
	access(account)
	fun addPlay(_ play: Play){ 
		self.plays[play.id] = play
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlays():{ UInt64: Play}{ 
		return self.plays
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlay(_ id: UInt64): Play?{ 
		return self.plays[id]
	}
	
	/// Players store information about a player that can change and is therefore not stored in the NFT itself
	/// can be mutated from Admin
	access(all)
	struct Player{ 
		access(all)
		let id: UInt64
		
		access(all)
		let jerseyname: String
		
		access(all)
		let position: String
		
		access(all)
		let number: UInt64
		
		access(all)
		let nationality: String
		
		access(all)
		let birthday: String
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, jerseyname: String, position: String, number: UInt64, nationality: String, birthday: String, metadata:{ String: String}){ 
			self.id = id
			self.jerseyname = jerseyname
			self.position = position
			self.number = number
			self.nationality = nationality
			self.birthday = birthday
			self.metadata = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTraits(_ prefix: String): [MetadataViews.Trait]{ 
			return [MetadataViews.Trait(name: prefix.concat("PlayerJersey"), value: self.jerseyname, displayType: "String", rarity: nil), MetadataViews.Trait(name: prefix.concat("PlayerPosition"), value: self.position, displayType: "String", rarity: nil), MetadataViews.Trait(name: prefix.concat("PlayerNumber"), value: self.number, displayType: "Number", rarity: nil), MetadataViews.Trait(name: prefix.concat("PlayerNationality"), value: self.nationality, displayType: "String", rarity: nil), MetadataViews.Trait(name: prefix.concat("PlayerBirthday"), value: self.birthday, displayType: "String", rarity: nil)]
		}
	}
	
	access(self)
	let players:{ UInt64: Player}
	
	access(account)
	fun addPlayer(_ player: Player){ 
		self.players[player.id] = player
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayers():{ UInt64: Player}{ 
		return self.players
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPlayer(_ id: UInt64): Player?{ 
		return self.players[id]
	}
	
	init(){ 
		self.players ={} 
		self.games ={} 
		self.plays ={} 
		self.licenses ={} 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/lampionsNFTs
		self.CollectionPublicPath = /public/lampionsNFTs
		self.CollectionPrivatePath = /private/lampionsNFTs
		emit ContractInitialized()
	}
}
