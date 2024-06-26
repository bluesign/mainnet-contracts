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

	/**
*  SPDX-License-Identifier: GPL-3.0-only
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import PartyMansionGiveawayContract from "./PartyMansionGiveawayContract.cdc"

import FindUtils from "../0x097bafa4e0b48eef/FindUtils.cdc"

import Profile from "../0x097bafa4e0b48eef/Profile.cdc"

//							   ..`																  
//							  +..o																  
//							  :::/									  `						   
//								`						 .os:.		`y+../y.					 
//										 ++./.		  `o++o/o`		+mmdms					  
//									   `:yNmd.		 -oy//+o-	   -ohmmmmdo.					
//								./`	`-:my+/	   `o+:ss/+		 ---/mm/:::					
//							   :yd.	   /		 .sd-``::			  so						
//							   +::+`			  `os/+:+.										  
//								`oh`			 -+ho.+y:	 -:::-								 
//							 -sdmh-			`yd:+-+:	  :/   -/								
//							 o-++			  `ys``+:	   .+. `+-								
//							  -+s							  -:-`								 
//						   .+shd:   `:::															
//						   s+h/`	+.`+.									 `-.				   
//						   -/:o	 `-:.									 -dmm:				  
//						 `:+sd/			   -.-h.						  `sys.				  
//						`ody+-				-hmmy+.		::::			  `					
//						`++	.--			-ysdo`		 o..o					   /:-o-	   
//							  `dmmo		   `  ..		  `..`  `o`				  :s-++-	  
//					 `..`	  +ys-				 `.`			//+..::			 ./:+o..	  
//					`y:.-:-`					   .y:/:``	  /+/:``-++.				.-		
//					omh`  .:/.` ```			 -::`++.dho	  `.-+ ..o.						   
//				   /mmmh.	-//--:/		   -m::/.o+-.`		`s/--:s`						  
//				  -mmmms/:	+.   /-	  -::  :s-ds:`		   `:			   `				
//				 `dmmms  -/`  .+-.:s.	 +d-//`.y/							 :sso/:+o:		   
//				 ymmms	`/:   `.``//-+:+`/s:dh/`						/yss/+mm../+dy.		   
//				ommmo	   sh:	  `+d-:yoy+	   .-`		   `+sso:sNy `/syo				  
//			   /mmmo	  :dmmmy-	 .-s/+:`	  -/.`-+`	   ``yN/ ./hy-						
//			  -mmm+	 .smmmmmmmy:  /mms//`	   o`   +.	  `+ohs.							  
//			 `dmm+	 +dmmmmmmmds-/:.``  `/-	  `/:-:-		  `								
//			 ymm+	-hmmmmmmmh/`   `::-	:/		`											 
//			omm/   .smmmmmmds-`	  ./hho:` -/													 
//		   /mm/   /dmmmmmh+.	 `:ohdmmmmmhs/:													 
//		  -mm/  -ymmmmms:`   `-/ydmmmmmdyo:.`													   
//		 `hm: `ommmmh+.   .:shmmmmdho/-`															
//		 ym: :hmmmy:` `-+ydmmdhs/-.																 
//		od:.ymmdo-`./sdmdhs+:.																	  
//	   :d:+mmy/-:ohddy+:.`																		  
//	  .dohds++shho/-`																			   
//	 `hdmhyso/-`																					
//	 sds/-`																						 
//	 `																							  
// PartyMansionDrinksContract
//
// "To Imgur! Full of truth and full of fiction, please raise your glasses to 
// our unbreakable addiction."
//																	
access(all)
contract PartyMansionDrinksContract: NonFungibleToken{ 
	
	// Data 
	//
	// The fridge contains the beers to be served
	access(self)
	var fridge: [DrinkStruct]
	
	// The shaker contains the LongDrinks to be served
	access(self)
	var shaker: [DrinkStruct]
	
	// The whiskyCellar contains the whisky to be served
	access(self)
	var whiskyCellar: [DrinkStruct]
	
	// FIFO
	access(all)
	var firstIndex: UInt32
	
	// totalSupply
	access(all)
	var totalSupply: UInt64
	
	// last call (stop minting)
	access(all)
	var lastCall: Bool
	
	// Beer price
	access(all)
	var beerPrice: UFix64
	
	// Long Drink Price
	access(all)
	var longDrinkPrice: UFix64
	
	// Whisky Price
	access(all)
	var whiskyPrice: UFix64
	
	// Private collection storage path
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Public collection storage path
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Admin storage path
	access(all)
	let BarkeeperStoragePath: StoragePath
	
	// Events
	//
	// Event to be emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	// Event to be emitted whenever a Drink is withdrawn from a collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event to be emitted whenever a Drink is deposited to a collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Event to be emitted whenever a new Drink is minted
	access(all)
	event Minted(id: UInt64, title: String, description: String, cid: String)
	
	// Event to be emitted whenever a new airdrop happens
	access(all)
	event Airdropped(id: UInt64)
	
	//											   ```./+++/.										   
	//										`-:::/+++oyy/..+++o+-									   
	//									   /s:--/.`   -+:-.   ./y+/-`								   
	//									-//o.	 .   `	   ````./y:`								 
	//								`:/o/.`	.	 . `   `-/++:`  .:+o-							   
	//							   /o:.`  `   :.  . `:`.:/yo/--+yo:.`  -h-							  
	//							  :y`  `. `.	  `:+/. `/s`   ` .:+oo. :y							  
	//							  +o`  ` ``  `   `  `-++/:` `  `	 :y/.h.							 
	//							 `so`  ` ``  .- .:   -d.	`  `  .` ..od+							  
	//							 o+ `   `   `:-./- -oy:` `` -``. `.	.o+							  
	//							 o/ -   `  .`-+s-   d- ` -  ` .` `. .`  :y							  
	//							 d/`	:`	  ```/d  .   ::  . .`  `  .h							  
	//							 :y-	`   .  .dso/++++++//::-/` - .`  .h							  
	//							  `s: ``  o`  .hod..mmmmmmmmmmmmmdys+.  -y							  
	//							   `y   -`  :+d:ym.:mmmmhmmmm+smmmmmm/s/+o							  
	//								-h```   :s- mm-/mmmmdmmmmmmmmmmmm-m-y:							  
	//								 +s:-- `h`  dm//mmmmmmymmmmmdhmmd+d.d							   
	//								  oy+  `h   yms-mmmmmmmmmmmmmmmmsd++o							   
	//								  `d.   y-  +md.mmdommmmddmmmmmmym.d.							   
	//								   s+-  +o  .mm-mmmmmmmmmmmmmmmmmo/s								
	//								   .d//.y/   dm+ymmmmdmmmhmmmmmmm.h-								
	//									s+:/:	omhommmmdmmmhmmmmmms/y								 
	//									.h.+	 -mm+mmmmmmmmmmyhmmm.h-								 
	//									 y:/	  dmommmmsmmmmmdmmmy:y								  
	//									 :y.	  omhdmmmmmmmmmdmmm:y:								  
	//									  d.	  -mmdmmmmmymmmmmmd.d`								  
	//									  o+`	  mmmmmmmmmmmmmmmo/s								   
	//									  :y-`	 ymmmmddmmmmmmmm:y:								   
	//									  `m`/	 +mmmmmmmmmmmmmm`d`								   
	//									   d.o	 -mmmmmmmmdmmmmd`m									
	//									   h-y	 `mmmmmhmmmmmmmh-h									
	//									   y:y`	 mmmmmmmmdmmmdy:y									
	//									   y:y.	 dmmmmmmmmmmsmy:y									
	//									   y:y.	 hmmmmmmymmm/mh-h									
	//									   d.h`	 dmmmmmmmmmm-md.d									
	//									  `m`m`	`mmmmmmmmmmm-hm`m`								   
	//									  -h-m`	-mmmmmmmmmmm:om-y:								   
	//									  +o+m. `-:oyyhhhdmmmmm+-m++o								   
	//									  h-hm+ `-:/+osydhhmmmm+-mh.d								   
	//									 .d.mmm:`  :osyhhmmmmmmydmm.h-								  
	//									 o+ommhhyo+hmmmmmmmmmddhhmmo/s								  
	//									 m`dmmmmhhysssooosssyhhmmmmm`m`								 
	//									 y/odddmdhdddmmmmmdddhdmdddo/y								  
	//									 `+o/++///.`.-----.`.://///o+`								  
	//									   `:+o+:.```-/++:.``.:+o+/`									
	//										   .-/+++++++++++/-.										
	// Drink data structure
	// This structure is used to store the payload of the Drink NFT
	//
	// "Here’s to a night on the town, new faces all around, taking the time
	// to finally unwind, tonight it’s about to go down!"
	//
	access(all)
	struct DrinkStruct{ 
		
		// ID of drink
		access(all)
		let drinkID: UInt64
		
		// ID in collection
		access(all)
		let collectionID: UInt64
		
		// Title of drink
		access(all)
		let title: String
		
		// Long description
		access(all)
		let description: String
		
		// CID of the IPFS address of the picture related to the Drink NFT
		access(all)
		let cid: String
		
		// Drink type
		access(all)
		let drinkType: DrinkType
		
		// Drink rarity
		access(all)
		let rarity: UInt64
		
		// Metadata of the Drink
		access(all)
		let metadata:{ String: AnyStruct}
		
		// init
		// Constructor method to initialize a Drink
		//
		// "To nights we will never remember, with the friends we will never forget."
		//
		init(drinkID: UInt64, collectionID: UInt64, title: String, description: String, cid: String, drinkType: DrinkType, rarity: UInt64, metadata:{ String: AnyStruct}){ 
			self.drinkID = drinkID
			self.collectionID = collectionID
			self.title = title
			self.description = description
			self.cid = cid
			self.drinkType = drinkType
			self.rarity = rarity
			self.metadata = metadata
		}
	}
	
	// Drink Enum
	//
	// German
	// „Ach, mir tut das Herz so weh,
	// wenn ich vom Glas den Boden seh.“
	//
	access(all)
	enum DrinkType: UInt8{ 
		access(all)
		case Beer
		
		access(all)
		case Whisky
		
		access(all)
		case LongDrink
	}
	
	// Drink NFT
	//
	// "Here’s to those who wish us well. And those that don’t can go to hell."
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// NFT id
		access(all)
		let id: UInt64
		
		// Data structure containing all relevant describing data
		access(all)
		let data: DrinkStruct
		
		// Original owner of NFT
		access(all)
		let originalOwner: Address
		
		// init 
		// Constructor to initialize the Drink
		//
		// "May we be in heaven half an hour before the Devil knows we’re dead."
		//
		init(drink: DrinkStruct, originalOwner: Address){ 
			PartyMansionDrinksContract.totalSupply = PartyMansionDrinksContract.totalSupply + 1
			let nftID = PartyMansionDrinksContract.totalSupply
			self.data = DrinkStruct(drinkID: nftID, collectionID: drink.collectionID, title: drink.title, description: drink.description, cid: drink.cid, drinkType: drink.drinkType, rarity: drink.rarity, metadata: drink.metadata)
			self.id = UInt64(self.data.drinkID)
			self.originalOwner = originalOwner
		}
		
		// name
		//
		// "If the ocean was beer and I was a duck, 
		//  I’d swim to the bottom and drink my way up. 
		//  But the ocean’s not beer, and I’m not a duck. 
		//  So raise up your glasses and shut the fuck up."
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun name(): String{ 
			return self.data.title
		}
		
		// description
		//
		// "Ashes to ashes, dust to dust, if it weren’t for our ass, our belly would bust!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String{ 
			return "A ".concat(PartyMansionDrinksContract.rarityToString(rarity: self.data.rarity)).concat(" ").concat(self.data.title).concat(" with serial number ").concat(self.id.toString())
		}
		
		// imageCID
		//
		// "Here’s to being single, drinking doubles, and seeing triple."
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun imageCID(): String{ 
			return self.data.cid
		}
		
		// getViews
		//
		// "Up a long ladder, down a stiff rope, here’s to King Billy, to hell with the pope!"
		//
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Rarity>()]
		}
		
		// resolveView
		//
		// "Let us drink to bread, for without bread, there would be no toast."
		//
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.IPFSFile(cid: self.imageCID(), path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://partymansion.io/beers/".concat(self.id.toString()))
				case Type<MetadataViews.Royalties>():
					let pmCap = Profile.findReceiverCapability(address: PartyMansionDrinksContract.account.address, path: /public/flowTokenReceiver, type: Type<@FlowToken.Vault>())!
					let ownerCap = Profile.findReceiverCapability(address: self.originalOwner, path: /public/flowTokenReceiver, type: Type<@FlowToken.Vault>())!
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: pmCap, cut: 0.05, description: "Party Mansion"), MetadataViews.Royalty(receiver: ownerCap, cut: 0.01, description: "First Owner")])
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PartyMansionDrinksContract.CollectionStoragePath, publicPath: PartyMansionDrinksContract.CollectionPublicPath, publicCollection: Type<&PartyMansionDrinksContract.Collection>(), publicLinkedType: Type<&PartyMansionDrinksContract.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PartyMansionDrinksContract.createEmptyCollection(nftType: Type<@PartyMansionDrinksContract.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Party Mansion Drinks", description: "What is a Party without drinks!? The Party Beers are an fun art collection of whacky drinks that can only be found at the bar in Party Mansion. These collectibles were first airdropped to Party Gooberz and will be a staple in the Mansion, Drink up!", externalURL: MetadataViews.ExternalURL("https://partymansion.io/"), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmSEJEwqdpotJ7RX42RKDy5sVgQzhNy3XiDmFsc81wgzNC", path: nil), mediaType: "image/jpg"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVyXgw67QVAU98765yfQAB1meZhnSnYVoL6mz6UpzSw7W", path: nil), mediaType: "image/jpg"), socials:{ "twitter": MetadataViews.ExternalURL("https://mobile.twitter.com/the_goobz_nft"), "discord": MetadataViews.ExternalURL("http://discord.gg/zJRNqKuDQH")})
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					for traitName in self.data.metadata.keys{ 
						let traitValue = self.data.metadata[traitName]
						if traitValue != nil{ 
							if let tv = traitValue! as? String{ 
								traits.append(MetadataViews.Trait(name: FindUtils.to_snake_case(traitName), value: tv!, displayType: "String", rarity: nil))
								continue
							}
						}
					}
					var drinkType = "Beer"
					switch self.data.drinkType{ 
						case DrinkType.Whisky:
							drinkType = "Whisky"
						case DrinkType.LongDrink:
							drinkType = "LongDrink"
					}
					traits.append(MetadataViews.Trait(name: "drink_type", value: drinkType, displayType: "String", rarity: nil))
					return traits
				case Type<MetadataViews.Rarity>():
					return MetadataViews.Rarity(score: nil, max: nil, description: PartyMansionDrinksContract.rarityToString(rarity: self.data.rarity))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Interface to publicly acccess DrinkCollection
	//
	// "Out with the old. In with the new. Cheers to the future. And All that we do"
	//
	access(all)
	resource interface DrinkCollectionPublic{ 
		
		// Deposit NFT
		// Param token refers to a NonFungibleToken.NFT to be deposited within this collection
		//
		// Belgian
		// "Proost op onze lever"
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		// Get all IDs related to the current Drink Collection
		// returns an Array of IDs
		//
		// Czech
		// "Na EX!"
		//
		access(all)
		view fun getIDs(): [UInt64]
		
		// Borrow NonFungibleToken NFT with ID from current Drink Collection 
		// Param id refers to a Drink ID
		// Returns a reference to the NonFungibleToken.NFT
		//
		// Czech
		// "Do dna!"
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// Eventually borrow Drink NFT with ID from current Drink Collection
		// Returns an option reference to PartyMansionDrinksContract.NFT
		//
		// Czech
		// "Na zdraví!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDrink(id: UInt64): &PartyMansionDrinksContract.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Drink reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	//ddxxkO000OOO0000OOOOO0000000O00KXXNWWNX0Oxoc:::;;;;;::::c:ccclooooooooooooooooooooddddddx0NWWWWNXK00
	//xxxkkkkkkkkkxxddddddddxxxxxxxxxxxdoolc;,,;:clloddoodxxddxdollllccloooooooooodxxkOKXXKKXXXNWMMMWXK0OO
	//ooooooooooooooooooooooooooooooc:;,..',:codkOOOO00OOO00OO0000000OxddolldddddOXNNWWWWWWNNNWWWWWWNK0OOO
	//oooooooooooooooooooooooooool:,'...';:lodddxxkkkO00OOO000OO00000K0OKKkdx0KKXWWWWWNNXXK00KXXNNNXK00OOO
	//oooooooooooooooooooooooool;'....',;:::cloddxkOOO0KKK000K0O0000000000K0OOKWWWWWWNNNXK0OOOO000000OOOOk
	//oooooooooodddooooooooool:'....',,,,,,:clddkkOO000000K0KKKKKKKKKKKK00000kkKNNWWWWWWNXK0Okkkkkkkxxxxxx
	//ooooooooooooooooooooooc,......'''',,;:cloodxxxxkkkOOOOOOOOO00O000KKK0000xkKXXNNWNNXK00Okkkkkkkxxxxxx
	//ooooooooodooddoooddooc.........'',;;:::ccclllllllclccllcccclooxkO000KKK0kxkOkO00OOOOOOOO000OOkkxxxxx
	//ddddddddddxkkxddddddl'....'..',;;;;:::;,,,,,,,,,,,,,,,'''...'',:loxO000KkxkOOOOOOO000000000Okxdddddd
	//kkkkkkOO0KXXXK0kxxdo;...''.',,;;;;,,,'...............		 ...,:lxkk0kdkkkOOOOOOOOOOOOOkkkxxxxddd
	//KKKKKKKXNNNNNNNXKKOd,..',',,;;;,,'........					   ...;lxdddxdxxxxxxxxxxxxxxxxxkxxddxx
	//kO0KKXXXNNWWWWWWWWWKc..,;;::;,'........  .....	  ....'',,;;,.. ...;codddddddddddddddddddddddddddd
	//odk0KXXXXXNWWMMMMMWM0;,::::;,........  .','..   .. ..';;:cloddo;.....:oddddddddddddddddddddddddddddd
	//odO0K0000KXNWWWWMMMWWKdlll:'..... .....''.. ...''.....';cloddxxo;...,ldddddddddddddddddddddddddddddd
	//oxkOkxxkO0KKKKXXNWWWWWNX0d,...   ... ....  ....'''.'...,:coddxkkl'..;odddddxxxddddddddddddxddddddddd
	//ddxddodxkOOOOkkkO00KKXXXNO, ..   .......   ..........'',;:codxxkx:..cddddddddddddddddddddxxxdddddddd
	//kkkxxdxxxxkkxxxxkkkkOOOO0k' ..   .. ..	 .......''''',;::loxxxkd;,odddddddddxxkOOkxddddddddddddddd
	//kkkkkkkkkkkkkkkkkkOOOO00KO, ..   ..	   ...........'',,;:cldxxxxdlodddddxxxk0KXXXXK0OOO00OOkkkxxxx
	//xxxxxxxxxxxxxxxxxxxxxk00Oo,...   .		............'',;:clodxxxkkooddxxkOO0KKK0OO0000XXK0000OOkkk
	//ddddddddddddddddddddddxxl:c,..   .  .   .. .............',;:cloddxxxxooxxxxxxxkkkkkkkkkkO0OkkOOkxxxx
	//dxxxdddddddddddxddxxxddxdl;...   .  . .........'..........',;:ldxxxxkkooxxxdddddddxxxdxxxxxxxxxxxxxx
	//xxxxkkkkOOOOkkkkkkxxkxxo::cl:. ....  ...........'''........'',:cccloddlcdxxdddddxxxxxxxdxxxxxxxxxxxx
	//kkkkkOO00KKK00OOOOOOOkxllxdxc. .............................',;,'';::;;cdxxddxxdxxxxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxxkxxxxxxxxxxl. ...  ................'......'',;:cccllllcdxxdddxxxxxxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxxxxxxxxxxxxxl...'.  ...........''......''',,,;::clllolloddddddddddxxxdxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxxxxxxxxxxxxxo'.''... ........'',,;;;'..',;;;::::clllcccoollllllllldxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxxxxxxxxxxxxxo'.,'...........'',;;;;:;,,''',;;::cclllllodxddddddddddxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxxxxxxxxxxxdoc...............',,;;:::cc:,..'',;;;:cccldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxkxxxxxxdolc:,...............',,;;:::cclc;''...''';;:ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	//xxxxxxxxxxxxxxxxkkxxkkdc::;:,...............',,;;::::clooo:,'.....,;ldxxxxxxxxxxxxxxxxxxxxxxxxxxxkkk
	//kkkkkkkkkkkkkkkkkkkxxko::;,,'................',,,;;:::cloddl:,.',;:coxkxxxxxxxxxxxxxxxxkxxxxkkkkkkkk
	//kkkkkkkkkkkkkkkkkkkkkkdl:;,''''.'...........''',,,,;::clooooc,.coodkkkkkxxxxxxxxkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkkkkkkkkxl:;;;;,,'''...'...''',,,,,,;;;;cllolc;';oxkkxdxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkkkkkkxdlc::::;;:::;;,'''''''...,;:::::;;:cc:,';ldOXX0Oxxdxkkkkkkkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkkkkxdlc:::::::::c::cc:;,',,,'....'::col:;;,'';:cxKXXKKKKkccdkkkkkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkkkdc,,'''',,;;:clccllllc:;;;;;,,....,cooc'..'::lOXXXXKKK0l,coxkkkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkkd:;,,,,,'''''',;clllllolc:;::cc:....;clo:'',clo0XXXXKKKKd;cxxxkkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkkdllc:::ccccc:;,''',:lllooolc:clll;....:looc',lco0XXXXKKKKk;:OKxxkkkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkkkd:;,''...'',:lool;'',:loooodoclllll:'..'lddo;,lldKXXXXKKKKx;:OXkdkOkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkOkl,,.....'''',,;cddc,'':loodddoooollc:,..:dddc,ldkKXXNNK0K0o,c00xodOkkkkkkkkkkkkkkkkkkk
	//kkkkkkkkkkkkOx:........''',,;::lo:'.':oddddkkdollll:..;odxl;lokKXXXXK0KOc'ckxdookOkkOkkkkkkkkkkkkkkk
	//kkkkkkkkOkkkOx;.............';::c;'..,coooxOOxlllllc,..,:llclokXXXNXK0Kkc';lodllxOkkOOkkOkkkkkkkOOOO
	//OOOOOOkkOkkOOd'...	 ......',,;;'..';lookOOxolllll,...',cllokXXNNXK00x:',:lc;;dOkkOOkOOOOOOOOOOOOO
	//OOOOOOOkOOOkOo;,...........''''.......';lxkOOkocllll:..'',:lloOXNNXKK00d;'.',,,;oOOkOOOOOOOOOOOOOOOO
	//OOOOOOOOkkOOko::,''''',;coolcc:;,'..'..,lkOOkxocclloc,.''';lloOXNNXKK0kd;'.,:ldddkOOOOOOOOOOOOOOOOOO
	//OOOOOOOOOOOOkl:;''''';codddoddxxdc..'..'okkkxxdlcllol;'''';lodkXNXXX0kkx:.,oxOOxdkOOOOOOOOOOOOOOOOOO
	//OOOOOOOOOOOOklc:,,,;:cooooddxkkkxc.....'lxxxxddlclloo;...';lddOXNXNKkkOx;.,okOOOxkOOOOOOOOOOOOOOOOOO
	//OOOOOOOOOOOOxllc::;;:cldxkO00KK0k:....',lddoooolclooo:..'':odd0XNXKOxk0d,'cxO00OdxOOOOOOOOOOOOOOOOOO
	//OOOOOOOOOOOOkolc;;;;;clodxk0KKKOkc.....';lllloollloll;..',:odx0XXKOxxOOl'',cloolcxOkOOOOOOOOOOOOOOOO
	//OOOOOOOOOOOOklc:;;,,;:ccloxO00Oxd:......,:cccoollllll;'',,:odx0X0Oxxk0k:...';::::dOOOOOOOOOOOOOOOOOO
	// Resource to define methods to be used by the barkeeper in order 
	// to administer and populate the fridge
	//
	// "Here’s to those who seen us at our best and seen us 
	// at our worst and cannot tell the difference."
	//
	access(all)
	resource Barkeeper{ 
		
		// Adds drinks to the fridge
		//
		// Polish
		// "Sto lat!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun fillFridge(collectionID: UInt64, title: String, description: String, cid: String, rarity: UInt64, metadata:{ String: AnyStruct}){ 
			pre{ 
				cid.length > 0:
					"Could not create Drink: cid is required."
			}
			PartyMansionDrinksContract.fridge.append(DrinkStruct(drinkID: 0 as UInt64, collectionID: collectionID, title: title, description: description, cid: cid, drinkType: DrinkType.Beer, rarity: rarity, metadata: metadata))
		}
		
		// Replaces old drinks in fridge
		// because nobody serves old drinks to the party people
		//
		// Polish
		// "Za nas!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun replaceDrinkInFridge(collectionID: UInt64, title: String, description: String, cid: String, rarity: UInt64, metadata:{ String: AnyStruct}, index: Int){ 
			pre{ 
				cid.length > 0:
					"Could not create Drink: cid is required."
				index >= 0:
					"Index is out of bounds"
				PartyMansionDrinksContract.fridge.length > index:
					"Index is out of bounds."
			}
			PartyMansionDrinksContract.fridge[index] = DrinkStruct(drinkID: 0 as UInt64, collectionID: collectionID, title: title, description: description, cid: cid, drinkType: DrinkType.Beer, rarity: rarity, metadata: metadata)
		}
		
		// removeDrinkFromFridge
		// because sometimes party people do change their taste
		//
		// Polish
		// “Za tych co nie mogą”
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun removeDrinkFromFridge(index: UInt64){ 
			pre{ 
				PartyMansionDrinksContract.fridge[index] != nil:
					"Could not take drink out of the fridge: drink does not exist."
			}
			PartyMansionDrinksContract.fridge.remove(at: index)
		}
		
		// throwHouseRound
		// The barkeeper throws a house round and airdrops the Drink to a Recipient
		//
		// "Here’s to the glass we love so to sip,
		// It dries many a pensive tear;
		// ’Tis not so sweet as a woman’s lip
		// But a damned sight more sincere."
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun throwHouseRound(collectionID: UInt64, title: String, description: String, cid: String, rarity: UInt64, metadata:{ String: AnyStruct}, drinkType: DrinkType, recipient: &{NonFungibleToken.CollectionPublic}, originalOwner: Address){ 
			pre{ 
				cid.length > 0:
					"Could not create Drink: cid is required."
			}
			// GooberStruct initializing
			let drink: DrinkStruct = DrinkStruct(drinkID: 0 as UInt64, collectionID: collectionID, title: title, description: description, cid: cid, drinkType: drinkType, rarity: rarity, metadata: metadata)
			recipient.deposit(token: <-create PartyMansionDrinksContract.NFT(drink: drink, originalOwner: originalOwner))
			emit Minted(id: PartyMansionDrinksContract.totalSupply, title: (drink!).title, description: (drink!).description, cid: (drink!).cid)
			emit Airdropped(id: PartyMansionDrinksContract.totalSupply)
		}
		
		// retrievePoolDrink
		//
		// "Time to hydrate"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun retrievePoolDrink(drinkType: DrinkType): DrinkStruct{ 
			pre{ 
				PartyMansionDrinksContract.checkIfBarIsSoldOut(drinkType: drinkType) == false:
					"Bar is sold out"
			}
			let disposedDrink: DrinkStruct = PartyMansionDrinksContract.getDrinkFromStorage(drinkType: drinkType)
			return disposedDrink
		}
		
		// announceLastCall
		// Barkeeper shouts "Last Call"
		//
		// "May you always lie, cheat, and steal. Lie beside the one you love,
		// cheat the devil, and steal away from bad company."
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun announceLastCall(lastCall: Bool){ 
			PartyMansionDrinksContract.lastCall = lastCall
		}
		
		// setDrinkPrices
		//
		// Mexico
		// "Por lo que ayer dolió y hoy ya no importa, salud!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun setDrinkPrices(beerPrice: UFix64, whiskyPrice: UFix64, longDrinkPrice: UFix64){ 
			PartyMansionDrinksContract.beerPrice = beerPrice
			PartyMansionDrinksContract.whiskyPrice = whiskyPrice
			PartyMansionDrinksContract.longDrinkPrice = longDrinkPrice
		}
	}
	
	//								  `--:/+oosyyyhhhhhhhhhhyysso+//:-.`								 
	//						`.:+sydmNMMNNmmdhhyyysssssssssyyyhhddmNNMMNmdhs+/-`						 
	//				   `-/sdNNNmdys+/:-````` ``			  ```````.-/+syhmNNNmyo:`					
	//				./ymNNdy+:.``										 ``.-+shmNNh+-				 
	//			  .smNds:.`													 `.:odNNh:`			  
	//			 /mMh:`															 `-sNNy`			 
	//			.NMs`																  :NMs			 
	//			:MM/																   `mMd			 
	//			-MMm/`																.yMMy			 
	//			`MMMMdo.`														 `.:yNMMMs			 
	//			 NMh+dNNds/-``											   ```:ohmMNy/MM+			 
	//			 mMd  .+ymNMmdyo/-```								  ``.:+sydNMNds:` .MM/			 
	//			 hMm	  .:+ydmMMMNmhyso++/:--...````````...-::/+osyhdmNMMNmho/-`	 :MM-			 
	//			 yMM			`.:/osyhdmmNMMMMMMMMMMMMMMMMMMMNNmdhyso+/-`			+MM.			 
	//			 oMM`					`````...----::----...`````					oMN			  
	//			 +MM-																  yMm			  
	//			 :MM/																  hMh			  
	//			 -MM+										   .-:+-				  mMy			  
	//			 `MMs									`.-:+ssso//ys-				NMo			  
	//			  NMy		  ``..--:/+os/`	   `.-/+ssso/-.`	`/hs.			 `MM+			  
	//			  mMd	 /oossyyyssoo+::/dy-...:ossso/-.`			`+hs.		   -MM:			  
	//			  hMm	`Nd:-.``		 .ymmmNMMs`					.odo.		 :MM-			  
	//			  yMM	`mhy`			  :mMMMyhs`					 -ymo`	   +MM`			  
	//			  oMM.   `m`yh`			  `sMMo`sd-				 `-oyydMdo-	 oMN			   
	//			  /MM-   `m``sh`	  ```.-/+osdMo  /m/			 ./yhs/. sMMMMy.   yMm			   
	//			  :MM/   oMNhohd:+osyyyyso+/-.` do   -ms`	   `:shy+.	 hMMMMMh   hMh			   
	//			  .MM+   -NMMMMMMs-`			do	`yd.   -ohho-	  .+mMMMMMM+   mMy			   
	//			  `MMs	.smMMMMMNho/-`		ds	  +m+yhs:``	.:odNMMMMMNy-	NMo			   
	//			   NMy   o-``:shmMMMMMNNmhso+//:mNmho+/:-ym/::://oshmNNMMMMNdy/`-+/  `MM/			   
	//			   mMd   dNms/.``-/oyhdmNMMMMMMNMMMMMMMNNNMNNNNMMMMNmmhyo/-.-:odNM:  -MM:			   
	//			   hMm   yMM/+yhyo/:.....-://+ossyyyyhyyyyyssoo+/:---://+osymNMMMM.  :MM.			   
	//			   yMN`  sMMd:`.Nddddmdhyso++//::::::::::://++ooosssoooosydmNMMMMN`  +MM`			   
	//			   oMM.  oMMMNs.m+`.--:/+oyhdNMMMMMMNyo++hm+//:---:/ohmNMMMMMMMMMm   oMN				
	//			   /MM-  /MMMMMmN+ `.-:+yhmNMMMMMMMMMNd+.oh `.:ohmNMMMMMMMMMMMMMMy   yMd				
	//			   :MM/  `dMMMMMMhydmNMMMMMMMMMMMMMMMMMMNmmhdNMMMMMMMMMMMMMMMMMMM:   hMh				
	//			   .MM+   .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo	mMs				
	//			   `MMy`   `+mNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNh-	.NMo				
	//				NMMd/`   `-+ymNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmy+.   `-sNMM/				
	//				mMMMMNy/`	 .:+ydNMMMMMMMMMMMMMMMMMMMMMMMMMMMMmhs+:`	`:smMMmMM:				
	//				hMMMMMMMNho-`	   `.:/oosyhhdddddddhhhyso+/-.	   .:odMMMm+.+MM.				
	//				sMMMMMMMMMMMNds+:.`		   ``  ``		   `.:+shmNMMMMMMy  oMM				 
	//				oMMMMMMMMM-:oydNNNNdhso+/::---...-.--:::/+osyhmNNNNdyo/hMMMMMs  sMN				 
	//				/MMMMMMMMM.   `.-/osyhdmmNNNNNNNNNNNNNNNmmdhhyo+:..`   sMMMMMo  hMd				 
	//				:MMMMMMMMM-		  ```...--:::::----....```		  sMMMMM+  dMy				 
	//				.MMMMMMMMM:											sMMMMM/ `mMs				 
	//				 yNMMMMMMM:											sMMMMM//dMd-				 
	//				  /dMMMMMM/											sMMMMMmMmo.				  
	//				   `/hNMMMo`										   yMMMMNmo.					
	//					  -odNMmho:.``								`.-/smMNms:`					  
	//						 ./sdNNNmhso/-.````  `	   `  ````.-:+oydNNNmy+-						  
	//							 `-+shmNNMMNNmdhhyyyyssyyyhhddmNNMNNmhs+:.							  
	//									`-:/+ossyyhhhhhhhyysso+/:-.		
	// Collection
	// A collection of Drink NFTs owned by an account
	//
	// Polish
	// “Człowiek nie wielbłąd, pić musi”
	//
	access(all)
	resource Collection: DrinkCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		// Norwegian
		// "Vi skåler for våre venner og de som vi kjenner og 
		//  de som vi ikke kjenner de driter vi i. Hei, skål!"
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		// British
		// "Let's drink the liquid of amber so bright;
		//  Let's drink the liquid with foam snowy white; 
		//  Let's drink the liquid that brings all good cheer; 
		//  Oh, where is the drink like old-fashioned beer?"
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		// Irish
		// "May your blessings outnumber
		// The shamrocks that grow,
		// And may trouble avoid you
		// Wherever you go."
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @PartyMansionDrinksContract.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			// destroy old resource
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		// Irish
		// "Here’s to a long life and a merry one.
		// A quick death and an easy one.
		// A pretty girl and an honest one.
		// A cold beer and another one."
		//
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		// French
		// “Je lève mon verre à la liberté.” 
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowDrink
		// Gets a reference to an NFT in the collection as a Drink,
		// exposing all data.
		// This is safe as there are no functions that can be called on the Drink.
		//
		// Spanish
		// "¡arriba, abajo, al centro y adentro!"
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDrink(id: UInt64): &PartyMansionDrinksContract.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PartyMansionDrinksContract.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PartyMansionDrinksContract.NFT
			}
			panic("Missing NFT. ID : ".concat(id.toString()))
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
		
		// destructor
		//
		// Russian
		// "Давайте всегда наслаждаться жизнью, как этим бокалом вина!"
		//
		// initializer
		//
		// Russian
		// "Выпьем за то, что мы здесь собрались, и чтобы чаще собирались!"
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	// Russian
	// "Выпьем за то, чтобы у нас всегда был повод для праздника!"
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// +ooooooooooooooo+/.														   -/+syyyso/-`		 
	// hNNNNNNNNNNNNNNNMMNd+`													`/ymNMNmmddmNMNNh/`	  
	// ````````````````.:yMMd.												 `omMNho:.`````.-+hNMmo`	
	//					/NMm/											   -dMNs-`			.sNMm:   
	//					 -dMNo`											:NMm:				 -dMN/  
	//					  `sMMh.										  `mMN-				   .mMN. 
	//						/NMm:										 +MMo					 /MMs 
	//						 -dMNo`									   :++.					 .MMd 
	//			 /ssssssssssssyMMMhssssssssssssssssssssssssssssssssssssssssssssssssso`			 -MMh 
	//			  +NMMMMNNNNNNNNNNMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMh.			  sMM+ 
	//			   .yMMN+````````-mMMs```````````````````````````````````````-dMMm/			   /MMd` 
	//				 :mMMh.	   `yMMh`									+NMMs`			  `sMMd`  
	//				   oNMMo`	   +NMm-								 -dMMd-`+:		   -sNMNo	
	//					.hMMm:   +sssdMMNssssssssssssssssssssssssssssssssyMMN+  yMMNhs+///+ohmMMms.	 
	//					  /mMMy. `sNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy.   `-ohmNMMMMMNmho:`	   
	//					   `sMMN+` -dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd:		 ``..--.``		   
	//						 :dMMd- `+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo`							  
	//						  `+NMNs. .yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh-								
	//							.yMMm/  :dMMMMMMMMMMMMMMMMMMMMMMMMMMm/`								 
	//							  /mMMy. `oNMMMMMMMMMMMMMMMMMMMMMMNs.								   
	//							   `sNMN+` -hMMMMMMMMMMMMMMMMMMMMd:									 
	//								 -dMMd:  +mMMMMMMMMMMMMMMMMNo`									  
	//								   +NMMs` .yMMMMMMMMMMMMMMh.										
	//									.yMMm/  :dMMMMMMMMMMm/										  
	//									  :mMMh.  oNMMMMMMMs`										   
	//										oNMMo` .hMMMMd-											 
	//										 .hMMm:`yMMN+											   
	//										   /mMMNMMy.												
	//											`yMMN:												  
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//											 /MMd												   
	//								```````.....-oMMm--.....``````									  
	//							  -/+oossyyyyyyyyyyyyyyyyyyyyssso+/:`								  
	// Beware !!! These methods know only german drinking toasts !!!
	// checkIfBarIsSoldOut
	//
	// Before selling a drink the barkeeper needs to check the stock
	//
	// German
	// "Nimmst du täglich deinen Tropfen,
	//  wird dein Herz stets freudig klopfen,
	//  wirst im Alter wie der Wein,
	//  stets begehrt und heiter sein."
	//
	access(TMP_ENTITLEMENT_OWNER)
	view fun checkIfBarIsSoldOut(drinkType: DrinkType): Bool{ 
		switch drinkType{ 
			case DrinkType.Beer:
				return PartyMansionDrinksContract.fridge.length == 0
			case DrinkType.Whisky:
				return PartyMansionDrinksContract.whiskyCellar.length == 0
			case DrinkType.LongDrink:
				return PartyMansionDrinksContract.shaker.length == 0
			default:
				panic("Undefined drink type.")
		}
		return false
	}
	
	// getPriceByTypeFromPriceList
	//
	// German
	// "Der größte Feind des Menschen wohl,
	// das ist und bleibt der Alkohol.
	// Doch in der Bibel steht geschrieben:
	// „Du sollst auch deine Feinde lieben.“
	//
	access(TMP_ENTITLEMENT_OWNER)
	view fun getPriceByTypeFromPriceList(drinkType: DrinkType): UFix64{ 
		var price: UFix64 = 0.00
		switch drinkType{ 
			case DrinkType.Beer:
				price = self.beerPrice
			case DrinkType.Whisky:
				price = self.whiskyPrice
			case DrinkType.LongDrink:
				price = self.longDrinkPrice
			default:
				panic("Undefined drink type.")
		}
		return price
	}
	
	// getDrinkFromStorage
	//
	// German
	// "Moses klopfte an einen Stein,
	// da wurde Wasser gleich zu Wein,
	// doch viel bequemer hast du's hier,
	// brauchst nur rufen: Wirt, ein Bier!"
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getDrinkFromStorage(drinkType: DrinkType): DrinkStruct{ 
		var disposedDrink: DrinkStruct = DrinkStruct(drinkID: 0 as UInt64, collectionID: 0 as UInt64, title: " ", description: " ", cid: " ", drinkType: drinkType, rarity: 0 as UInt64, metadata:{} )
		switch drinkType{ 
			case DrinkType.Beer:
				disposedDrink = PartyMansionDrinksContract.fridge.remove(at: PartyMansionDrinksContract.firstIndex)
			case DrinkType.Whisky:
				disposedDrink = PartyMansionDrinksContract.whiskyCellar.remove(at: PartyMansionDrinksContract.firstIndex)
			case DrinkType.LongDrink:
				disposedDrink = PartyMansionDrinksContract.shaker.remove(at: PartyMansionDrinksContract.firstIndex)
			default:
				panic("Undefined drink type.")
		}
		return disposedDrink
	}
	
	// buyDrink
	// Mints a new Drink NFT with a new ID and disposes it from the Bar
	// and deposits it in the recipients collection using their collection reference
	//
	// German
	// "Wer Liebe mag und Einigkeit, der trinkt auch mal ne Kleinigkeit."
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun buyDrink(recipient: &{NonFungibleToken.CollectionPublic}, address: Address, paymentVault: @{FungibleToken.Vault}, drinkType: DrinkType){ 
		pre{ 
			PartyMansionDrinksContract.lastCall == false:
				"No minting possible. Barkeeper already announced last call."
			PartyMansionDrinksContract.checkIfBarIsSoldOut(drinkType: drinkType) == false:
				"Bar is sold out"
			paymentVault.isInstance(Type<@FlowToken.Vault>()):
				"payment vault is not requested fungible token"
			paymentVault.balance >= PartyMansionDrinksContract.getPriceByTypeFromPriceList(drinkType: drinkType):
				"Could not buy Drink: payment balance insufficient."
		}
		
		// pay the barkeeper
		let partyMansionDrinkContractAccount: &Account = getAccount(PartyMansionDrinksContract.account.address)
		let partyMansionDrinkContractReceiver: Capability<&{FungibleToken.Receiver}> = partyMansionDrinkContractAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!
		let borrowPartyMansionDrinkContractReceiver = partyMansionDrinkContractReceiver.borrow()!
		borrowPartyMansionDrinkContractReceiver.deposit(from: <-paymentVault.withdraw(amount: paymentVault.balance))
		
		// serve drink
		let disposedDrink: DrinkStruct = PartyMansionDrinksContract.getDrinkFromStorage(drinkType: drinkType)
		recipient.deposit(token: <-create PartyMansionDrinksContract.NFT(drink: disposedDrink!, originalOwner: address))
		emit Minted(id: PartyMansionDrinksContract.totalSupply, title: (disposedDrink!).title, description: (disposedDrink!).description, cid: (disposedDrink!).cid)
		
		// close the wallet
		destroy paymentVault
	}
	
	// retrieveFreeDrink
	//
	// “Alcohol may be man’s worst enemy, but the bible says love your enemy.”
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun retrieveFreeDrink(recipient: &{NonFungibleToken.CollectionPublic}, address: Address, giveawayCode: String, drinkType: DrinkType){ 
		pre{ 
			PartyMansionDrinksContract.checkIfBarIsSoldOut(drinkType: drinkType) == false:
				"Bar is sold out"
		}
		if PartyMansionGiveawayContract.checkGiveawayCode(giveawayCode: giveawayCode) == false{ 
			panic("Giveaway code not known.")
		}
		
		// deposit it in the recipient's account using their reference
		let disposedDrink: DrinkStruct = PartyMansionDrinksContract.getDrinkFromStorage(drinkType: drinkType)
		recipient.deposit(token: <-create PartyMansionDrinksContract.NFT(drink: disposedDrink!, originalOwner: address))
		PartyMansionGiveawayContract.removeGiveawayCode(giveawayCode: giveawayCode)
		emit Minted(id: PartyMansionDrinksContract.totalSupply, title: (disposedDrink!).title, description: (disposedDrink!).description, cid: (disposedDrink!).cid)
	}
	
	//												 -:.												
	//												 :hd--											  
	//												 -sMNm-											 
	//												  `+MM+											 
	//												   `NN.											 
	//												   :Mm											  
	//												  `mMh											  
	//												  +MMs											  
	//												 `NMM/											  
	//									 `-/++-./-`  /MMM.											  
	//								   `+mMMMMMNMMy` sMMy											   
	//								   yMMMMMMMMMMMo-NMN.											   
	//								-:/MMMMMMMMMMMMMNMMs												
	//							 `.-yMMMMMMMMMMMMMMMMMN.												
	//						   :yNMMMMMMMMMMMMMMMMMMMMy												 
	//						  :MMMMMMMMMMMMMMMMMMMMMMM-												 
	//						  `yNNmMMMMMMMMMMMMMMMMMMh												  
	//						   `+-yMMMMMMMMMMMMMNMMMM-												  
	//							  -NMMMMMMMMMMMMMMMMN.												  
	//							  `dNMMMMMMMMMMMMMMMMmy:												
	//							   .dMMMMMMMMMMMMMMMMMMN-											   
	//							  `oMMMNmNMMMMMMMMMMMMMM/											   
	//							 .hMMMh//mNNMMMMMMMMMMMM+											   
	//							-dMMMs` ./-:hMMMMMMMMMMMh											   
	//						   -mMMMs	   `/mMMMMMMMMMM:											  
	//						   dMMMm/.`	   .hMMMMMMMMMm:											 
	//						  `dNNMMMNho/-.``  /MMMMMMMMMMN/											
	//							.-/shmNNMMNmhhhmMMMMMMMMMMMM+`										  
	//								  `-o+oymNNMMMMMMMMMMMMMMh`										 
	//									`  `..-mMMMMMMMMMMMMMMm.										
	//										   yMMMMMMMMMMMMMMMm.									   
	//										   hMMMMMMMMMMMMMMMMd									   
	//										  `NMMMMMMMMMMMMMMMMM+									  
	//										  /MMMMMMMMMMMMMMMMMMd									  
	//										  dMMMMMMMMMMMMMMMMMMM-									 
	//										 -MMMMMMMMmyysmMMMMMMMo									 
	//										 oMMMMMMMN-   :MMMMMMMd									 
	//										 hMMMMMMM:	 hMMMMMMM`									
	//										 mMMMMMMs	  .NMMMMMM/									
	//										`MMMMMMm`	   yMMMMMMs									
	//										-MMMMMMo		-MMMMMMh									
	//										:MMMMMN`		 yMMMMMm									
	//										/MMMMMs		  -MMMMMN`								   
	//										oMMMMN.		   yMMMMM.								   
	//										dMMMMo			-NMMMMs								   
	//									   :MMMMs			  /NMMMm								   
	//									  .mMMMh				/MMMM/								  
	//									 `dMMMM/				`MMMMN.								 
	//									 sMMMMN`				 mMMMMh								 
	//									.MMMMM+				  oMMMMM:								
	//									oMMMMy				   `hMMMMh								
	//									dMMMy`					`hMMMM.							   
	//								   `NMMm`					  `hMMMs							   
	//								   -MMM/						.mMMN`							  
	//								   :MMh						  :MMM+							  
	//								   oMN-						   yMMd							  
	//								   dMh							:MMM:							 
	//								  :MMo							.MMMy							 
	//								  hMM-							:MMMN`							
	//								 :MMm							 .mmMM+							
	//								`mMMo							  o.dMh`						   
	//								sMMN-							  o -NMho`						 
	//								-::-							   -  :///.						 
	// getContractAddress
	// returns address to smart contract
	//
	// “Lift ’em high and drain ’em dry, to the guy who says, “My turn to buy.”
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getContractAddress(): Address{ 
		return self.account.address
	}
	
	// getBeerPrice
	//
	// "May we never go to hell but always be on our way."
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getBeerPrice(): UFix64{ 
		return self.beerPrice
	}
	
	// getWhiskyPrice
	//
	// "God in goodness sent us grapes to cheer both great and small. 
	//  Little fools drink too much, and great fools not at all!"
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhiskyPrice(): UFix64{ 
		return self.whiskyPrice
	}
	
	// getLongDrinkPrice
	//
	// "The past is history, the future is a mystery, but today is a gift, 
	//  because it’s the present."
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getLongDrinkPrice(): UFix64{ 
		return self.longDrinkPrice
	}
	
	// rarityToString
	//
	// "Life is short, but sweet."
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun rarityToString(rarity: UInt64): String{ 
		switch rarity{ 
			case 0 as UInt64:
				return "Common"
			case 1 as UInt64:
				return "Rare"
			case 2 as UInt64:
				return "Epic"
			case 3 as UInt64:
				return "Legendary"
		}
		return ""
	}
	
	// Init function of the smart contract
	//
	// "We drink to those who love us, we drink to those who don’t. 
	//  We drink to those who fuck us, and fuck those who don’t!"
	//
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// position to take the drinks from
		self.firstIndex = 0
		
		// Set last call
		self.lastCall = false
		
		// Initialize drink prices
		self.beerPrice = 4.20
		self.whiskyPrice = 12.60
		self.longDrinkPrice = 42.00
		
		// Init collections
		self.CollectionStoragePath = /storage/PartyMansionDrinkCollection
		self.CollectionPublicPath = /public/PartyMansionDrinkCollectionPublic
		
		// init & save Barkeeper, assign to Bar 
		self.BarkeeperStoragePath = /storage/PartyMansionBarkeeper
		self.account.storage.save<@Barkeeper>(<-create Barkeeper(), to: self.BarkeeperStoragePath)
		
		// Init the Bar
		self.fridge = []
		self.shaker = []
		self.whiskyCellar = []
	}
}
