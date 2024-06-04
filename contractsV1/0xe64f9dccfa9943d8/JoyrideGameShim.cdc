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

	import JoyridePayments from "../0xecfad18ba9582d4f/JoyridePayments.cdc"

access(all)
contract JoyrideGameShim{ 
	access(all)
	event PlayerTransaction(gameID: String)
	
	access(all)
	event FinalizeTransaction(gameID: String)
	
	access(all)
	event RefundTransaction(gameID: String)
	
	//Fake Token Events for User Mapping
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun GameIDtoStoragePath(_ gameID: String): StoragePath{ 
		return StoragePath(identifier: "JoyrideGame_".concat(gameID))!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun GameIDtoCapabilityPath(_ gameID: String): PrivatePath{ 
		return PrivatePath(identifier: "JoyrideGame_".concat(gameID))!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun CreateJoyrideGame(
		paymentsAdmin: Capability<&{JoyridePayments.WalletAdmin}>,
		gameID: String
	): @JoyrideGameShim.JoyrideGame{ 
		return <-create JoyrideGameShim.JoyrideGame(paymentsAdmin: paymentsAdmin, gameID: gameID)
	}
	
	access(all)
	resource interface JoyrideGameData{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun readGameInfo(_ key: String): AnyStruct
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setGameInfo(_ key: String, value: AnyStruct)
	}
	
	access(all)
	resource JoyrideGame: JoyrideGameData, JoyridePayments.WalletAdmin{ 
		access(self)
		let gameInfo:{ String: AnyStruct}
		
		access(self)
		var paymentsAdmin: Capability<&{JoyridePayments.WalletAdmin}>
		
		init(paymentsAdmin: Capability<&{JoyridePayments.WalletAdmin}>, gameID: String){ 
			self.gameInfo ={ "gameID": gameID}
			self.paymentsAdmin = paymentsAdmin
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun readGameInfo(_ key: String): AnyStruct{ 
			return self.gameInfo[key]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setGameInfo(_ key: String, value: AnyStruct){ 
			self.gameInfo[key] = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun PlayerTransaction(playerID: String, tokenContext: String, amount: Fix64, gameID: String, txID: String, reward: Bool, notes: String): Bool{ 
			if !self.gameInfo.containsKey("gameID"){ 
				panic("gameID not set")
			}
			let _gameID = self.readGameInfo("gameID")! as! String
			if gameID != _gameID{ 
				panic("Incorrect GameID for Shim")
			}
			emit JoyrideGameShim.PlayerTransaction(gameID: gameID)
			return (self.paymentsAdmin.borrow()!).PlayerTransaction(playerID: playerID, tokenContext: tokenContext, amount: amount, gameID: gameID, txID: txID, reward: reward, notes: notes)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun FinalizeTransactionWithDevPercentage(txID: String, profit: UFix64, devPercentage: UFix64): Bool{ 
			emit JoyrideGameShim.FinalizeTransaction(gameID: self.readGameInfo("gameID")! as! String)
			return (self.paymentsAdmin.borrow()!).FinalizeTransactionWithDevPercentage(txID: txID, profit: profit, devPercentage: devPercentage)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun RefundTransaction(txID: String): Bool{ 
			emit JoyrideGameShim.RefundTransaction(gameID: self.readGameInfo("gameID")! as! String)
			return (self.paymentsAdmin.borrow()!).RefundTransaction(txID: txID)
		}
	}
}
