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

	access(all)
contract GameCatalog{ 
	access(all)
	struct Game{ 
		access(all)
		let levelType: Type
		
		access(all)
		let gameEngineType: Type
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		init(
			levelType: Type,
			gameEngineType: Type,
			name: String,
			description: String,
			image: String
		){ 
			self.levelType = levelType
			self.gameEngineType = gameEngineType
			self.name = ""
			self.description = ""
			self.image = ""
		}
	}
	
	access(all)
	let games: [Game]
	
	access(TMP_ENTITLEMENT_OWNER)
	fun addGame(game: Game){ 
		self.games.append(game)
	}
	
	init(){ 
		self.games = []
	}
}
