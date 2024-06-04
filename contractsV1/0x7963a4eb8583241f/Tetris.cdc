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

	import GameLevels from "../0x9d041d36947924c0/GameLevels.cdc"

import GameEngine from "../0x9d041d36947924c0/GameEngine.cdc"

import TraditionalTetrisPieces from "./TraditionalTetrisPieces.cdc"

import TetrisObjects from "./TetrisObjects.cdc"

access(all)
contract Tetris: GameLevels{ 
	access(all)
	struct StandardLevel: GameEngine.Level{ 
		access(all)
		var gameboard: GameEngine.GameBoard
		
		access(all)
		var objects:{ UInt64:{ GameEngine.GameObject}}
		
		access(all)
		var state:{ String: String}
		
		access(all)
		let tickRate: UInt64
		
		access(all)
		let boardWidth: Int
		
		access(all)
		let boardHeight: Int
		
		access(all)
		let extras:{ String: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewTetrisPiece(): TetrisObjects.TetrisPiece{ 
			let tetrisPiece = TetrisObjects.TetrisPiece()
			if self.state["lastShape"] == nil{ 
				self.state["lastShape"] = "L"
			}
			let shape = TraditionalTetrisPieces.getNextShape(self.state["lastShape"]!)
			// Make the active piece slightly transparent.
			let color = TraditionalTetrisPieces.getColorForShape(shape).concat("99")
			self.state["lastShape"] = shape
			tetrisPiece.fromMap({"id": "1", "type": "TetrisPiece", "doesTick": "true", "x": "0", "y": "4", "shape": shape, "rotation": "0", "color": color, "dropRate": "5", "lastDropTick": "0"})
			return tetrisPiece
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createInitialGameObjects(): [{GameEngine.GameObject}?]{ 
			let tetrisPiece = self.createNewTetrisPiece()
			let lockedInTetrisPiece = TetrisObjects.LockedInTetrisPiece()
			var fullRow: [Int] = []
			var i = 0
			var emptyRow: [Int] = []
			while i < self.boardWidth{ 
				emptyRow.append(0)
				fullRow.append(1)
				i = i + 1
			}
			var j = 0
			var lockedInitialPositions: [[Int]] = []
			while j < self.boardHeight - 1{ 
				lockedInitialPositions.append(emptyRow)
				j = j + 1
			}
			lockedInitialPositions.append(fullRow)
			lockedInTetrisPiece.setRelativePositions(lockedInitialPositions)
			lockedInTetrisPiece.setReferencePoint([0, 0])
			return [tetrisPiece, lockedInTetrisPiece]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun parseGameObjectsFromMaps(_ map: [{String: String}]): [{GameEngine.GameObject}?]{ 
			let objects: [{GameEngine.GameObject}?] = []
			for objectMap in map{ 
				var object:{ GameEngine.GameObject}? = nil
				if objectMap["type"] == "TetrisPiece"{ 
					object = TetrisObjects.TetrisPiece()
				}
				if objectMap["type"] == "LockedInTetrisPiece"{ 
					object = TetrisObjects.LockedInTetrisPiece()
				}
				(object!).fromMap(objectMap)
				objects.append(object!)
			}
			return objects
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun tick(tickCount: UInt64, events: [GameEngine.PlayerEvent]){ 
			var keys = self.objects.keys
			for key in keys{ 
				if self.objects[key] == nil{ 
					continue
				}
				let object = self.objects[key]!
				if (self.objects[key]!).doesTick{ 
					// When passed as a parameter, level is readonly because the param copies the level.
					// For any actions that might be required that need to affect the actual level,
					// we provide the callbacks object.
					let redraw = fun (_ object: AnyStruct?): AnyStruct?{ 
							let map = object! as!{ String:{ GameEngine.GameObject}}
							let prevObject = map["prev"]!
							let gameObject = map["new"]!
							self.gameboard.remove(prevObject)
							self.gameboard.add(gameObject)
							return nil
						}
					let remove = fun (_ object: AnyStruct?): AnyStruct?{ 
							let gameObject = object! as!{ GameEngine.GameObject}
							self.gameboard.remove(gameObject)
							self.objects.remove(key: gameObject.id)
							return nil
						}
					let spawn = fun (_ object: AnyStruct?): AnyStruct?{ 
							let newTetrisPiece = self.createNewTetrisPiece()
							self.objects[newTetrisPiece.id] = newTetrisPiece
							self.gameboard.add(newTetrisPiece)
							return nil
						}
					let expandLockedIn = fun (_ object: AnyStruct?): AnyStruct?{ 
							let gameObject = object! as! TetrisObjects.TetrisPiece
							var color = gameObject.color.slice(from: 0, upTo: 7) // Remove the opacity
							
							var newRows:{ Int: Bool} ={} 
							// loop through all of the relative positions of the tetris piece
							// and create a new individual locked in piece for each one
							// with the same reference point and color as the tetris piece
							var i = 0
							while i < gameObject.relativePositions.length{ 
								var j = 0
								while j < gameObject.relativePositions[i].length{ 
									if gameObject.relativePositions[i][j] == 1{ 
										let newLockedInPiece = TetrisObjects.LockedInTetrisPiece()
										newLockedInPiece.setID(UInt64.fromString(self.state["lastID"]!)!)
										self.state["lastID"] = (UInt64.fromString(self.state["lastID"]!)! + 1).toString()
										newLockedInPiece.setRelativePositions([[1]])
										newLockedInPiece.setReferencePoint([gameObject.referencePoint[0] + i, gameObject.referencePoint[1] + j])
										newRows[gameObject.referencePoint[0] + i] = true
										newLockedInPiece.setColor(color)
										self.gameboard.add(newLockedInPiece)
										self.objects[newLockedInPiece.id] = newLockedInPiece
									}
									j = j + 1
								}
								i = i + 1
							}
							
							// check if any of the `newRows` are full
							// if they are, remove them and shift all of the locked in pieces above them down
							// also increment the score state
							var rowsToRemove: [Int] = []
							for row in newRows.keys{ 
								if (self.gameboard.board[row]!).keys.length == self.boardWidth{ 
									self.state["score"] = (UInt64.fromString(self.state["score"]!)! + 1).toString()
									let values = (self.gameboard.board[row]!).values
									for lockedInPiece in values{ 
										self.objects.remove(key: (lockedInPiece!).id)
										self.gameboard.remove(lockedInPiece!)
									}
									
									// Shift all game objects above the row down
									var i = row
									while i > 0{ 
										if self.gameboard.board[i] == nil{ 
											i = i - 1
											continue
										}
										for j in (self.gameboard.board[i]!).keys{ 
											let obj: TetrisObjects.LockedInTetrisPiece?? = (self.gameboard.board[i]!)[j]! as? TetrisObjects.LockedInTetrisPiece?
											if obj == nil || obj! == nil{ 
												continue
											}
											let prev = obj!!
											(self.objects[prev.id]!).setReferencePoint([i + 1, j])
											let params:{ String:{ GameEngine.GameObject}} ={ "prev": prev, "new": self.objects[prev.id]!}
											redraw(params)
										}
										i = i - 1
									}
								}
							}
							return nil
						}
					let callbacks:{ String: fun (AnyStruct?): AnyStruct?} ={ "redraw": redraw, "remove": remove, "spawn": spawn, "expandLockedIn": expandLockedIn}
					(self.objects[key]!).tick(tickCount: tickCount, events: events, level: self, callbacks: callbacks)
				}
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun postTick(tickCount: UInt64, events: [GameEngine.PlayerEvent]){} 
		
		// do nothing
		init(){ 
			self.boardWidth = 10
			self.boardHeight = 20
			self.tickRate = 10 // ideal ticks per second from the client
			
			self.state ={ "score": "0", "lastID": "2"}
			self.extras ={ "boardWidth": self.boardWidth, "boardHeight": self.boardHeight, "description": "A traditional tetris level w/ some bugs."}
			self.objects ={} 
			self.gameboard = GameEngine.GameBoard(width: self.boardWidth, height: self.boardHeight)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createLevel(_ name: String): AnyStruct?{ 
		return StandardLevel()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAvailableLevels(): [String]{ 
		return ["StandardLevel"]
	}
}
