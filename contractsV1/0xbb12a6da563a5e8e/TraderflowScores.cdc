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

	/*

	The TradeScores object creates a append only store for historical trade and equity data.
	This data can be processed to determine performance information for a given trade account.
 */

access(all)
contract TraderflowScores{ 
	access(all)
	enum TradeType: UInt8{ 
		access(all)
		case Short
		
		access(all)
		case Long
	}
	
	access(all)
	struct Equity{ 
		access(all)
		let timestamp: UFix64
		
		access(all)
		let value: UFix64
		
		init(_value: UFix64){ 
			self.timestamp = getCurrentBlock().timestamp
			self.value = _value
		}
	}
	
	access(all)
	struct TradeMetadata{ 
		access(all)
		let score: UInt32
		
		access(all)
		let drawdown: UInt32
		
		access(all)
		let winrate: UInt32
		
		access(all)
		let tradeCount: UInt64
		
		access(all)
		let equity: UFix64
		
		access(all)
		let average_profit: UFix64
		
		access(all)
		let average_loss: UFix64
		
		access(all)
		let average_long_profit_ema150: UFix64
		
		access(all)
		let average_long_loss_ema150: UFix64
		
		access(all)
		let average_short_profit_ema150: UFix64
		
		access(all)
		let average_short_loss_ema150: UFix64
		
		access(all)
		let achievement_provisional: Bool
		
		access(all)
		let achievement_bear: Bool
		
		access(all)
		let achievement_bull: Bool
		
		access(all)
		let achievement_piggyban: Bool
		
		access(all)
		let achievement_scales: Bool
		
		access(all)
		let achievement_robot: Bool
		
		access(all)
		let achievement_bank: Bool
		
		access(all)
		let achievement_moneybags: Bool
		
		access(all)
		let achievement_safe: Bool
		
		access(all)
		let achievement_crown1: Bool
		
		access(all)
		let achievement_crown2: Bool
		
		access(all)
		let achievement_diamond1: Bool
		
		access(all)
		let achievement_diamond2: Bool
		
		access(all)
		let achievement_onfire: Bool
		
		init(
			_score: UFix64,
			_drawdown: UFix64,
			_winrate: UFix64,
			_tradeCount: UInt64,
			_equity: UFix64,
			_average_profit: UFix64,
			_average_loss: UFix64,
			_average_long_profit_ema150: UFix64,
			_average_long_loss_ema150: UFix64,
			_average_short_profit_ema150: UFix64,
			_average_short_loss_ema150: UFix64,
			_achievement_provisional: Bool,
			_achievement_bear: Bool,
			_achievement_bull: Bool,
			_achievement_piggyban: Bool,
			_achievement_scales: Bool,
			_achievement_robot: Bool,
			_achievement_bank: Bool,
			_achievement_moneybags: Bool,
			_achievement_safe: Bool,
			_achievement_crown1: Bool,
			_achievement_crown2: Bool,
			_achievement_diamond1: Bool,
			_achievement_diamond2: Bool,
			_achievement_onfire: Bool
		){ 
			self.score = UInt32(_score * 100.0)
			self.drawdown = UInt32(_drawdown * 100.0)
			self.winrate = UInt32(_winrate * 100.0)
			self.tradeCount = _tradeCount
			self.equity = _equity
			self.average_profit = _average_profit
			self.average_loss = _average_loss
			self.average_long_profit_ema150 = _average_long_profit_ema150
			self.average_long_loss_ema150 = _average_long_loss_ema150
			self.average_short_profit_ema150 = _average_short_profit_ema150
			self.average_short_loss_ema150 = _average_short_loss_ema150
			self.achievement_provisional = _achievement_provisional
			self.achievement_bear = _achievement_bear
			self.achievement_bull = _achievement_bull
			self.achievement_piggyban = _achievement_piggyban
			self.achievement_scales = _achievement_scales
			self.achievement_robot = _achievement_robot
			self.achievement_bank = _achievement_bank
			self.achievement_moneybags = _achievement_moneybags
			self.achievement_safe = _achievement_safe
			self.achievement_crown1 = _achievement_crown1
			self.achievement_crown2 = _achievement_crown2
			self.achievement_diamond1 = _achievement_diamond1
			self.achievement_diamond2 = _achievement_diamond2
			self.achievement_onfire = _achievement_onfire
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun equal(md: TradeMetadata): Bool{ 
			if self.score != md.score{ 
				return false
			}
			if self.drawdown != md.drawdown{ 
				return false
			}
			if self.winrate != md.winrate{ 
				return false
			}
			if self.achievement_provisional != md.achievement_provisional{ 
				return false
			}
			if self.achievement_bear != md.achievement_bear{ 
				return false
			}
			if self.achievement_bull != md.achievement_bull{ 
				return false
			}
			if self.achievement_piggyban != md.achievement_piggyban{ 
				return false
			}
			if self.achievement_scales != md.achievement_scales{ 
				return false
			}
			if self.achievement_robot != md.achievement_robot{ 
				return false
			}
			if self.achievement_bank != md.achievement_bank{ 
				return false
			}
			if self.achievement_moneybags != md.achievement_moneybags{ 
				return false
			}
			if self.achievement_safe != md.achievement_safe{ 
				return false
			}
			if self.achievement_crown1 != md.achievement_crown1{ 
				return false
			}
			if self.achievement_crown2 != md.achievement_crown2{ 
				return false
			}
			if self.achievement_diamond1 != md.achievement_diamond1{ 
				return false
			}
			if self.achievement_diamond2 != md.achievement_diamond2{ 
				return false
			}
			if self.achievement_onfire != md.achievement_onfire{ 
				return false
			}
			return true
		}
	}
	
	access(all)
	struct TradeMetadataRebuild{ 
		access(all)
		let tbv: TradeMetadata
		
		access(all)
		let rebuild: Bool
		
		init(_metadata: TradeMetadata, _rebuild: Bool){ 
			self.tbv = _metadata
			self.rebuild = _rebuild
		}
	}
	
	access(all)
	struct Trade{ 
		access(all)
		let onchain: UFix64
		
		access(all)
		let symbol: String
		
		access(all)
		let tradeType: TradeType
		
		access(all)
		let openPrice: Fix64
		
		access(all)
		let openTime: UInt64
		
		access(all)
		let closePrice: Fix64
		
		access(all)
		let closeTime: UInt64
		
		access(all)
		let stopLoss: Fix64
		
		access(all)
		let takeProfit: Fix64
		
		access(all)
		let profit: Fix64
		
		access(all)
		let equity: UFix64
		
		access(all)
		let ticket: UInt64
		
		access(all)
		var openEquity: UFix64?
		
		access(all)
		var minEquity: UFix64?
		
		access(all)
		var maxEquity: UFix64?
		
		init(
			_symbol: String,
			_tradeType: TradeType,
			_openPrice: Fix64,
			_openTime: UInt64,
			_closePrice: Fix64,
			_closeTime: UInt64,
			_stopLoss: Fix64,
			_takeProfit: Fix64,
			_profit: Fix64,
			_equity: UFix64,
			_ticket: UInt64
		){ 
			self.onchain = getCurrentBlock().timestamp
			self.symbol = _symbol
			self.tradeType = _tradeType
			self.openPrice = _openPrice
			self.openTime = _openTime
			self.closePrice = _closePrice
			self.closeTime = _closeTime
			self.stopLoss = _stopLoss
			self.takeProfit = _takeProfit
			self.profit = _profit
			self.equity = _equity
			self.ticket = _ticket
			self.openEquity = nil
			self.minEquity = nil
			self.maxEquity = nil
		}
	}
	
	access(all)
	struct TradeScores{ 
		/* Log of trades and counts */
		access(self)
		var historical: [Trade]
		
		access(contract)
		var positive_long_total: UInt
		
		access(contract)
		var negative_long_total: UInt
		
		access(contract)
		var positive_long_run: UInt
		
		access(contract)
		var negative_long_run: UInt
		
		access(contract)
		var positive_short_total: UInt
		
		access(contract)
		var negative_short_total: UInt
		
		access(contract)
		var positive_short_run: UInt
		
		access(contract)
		var negative_short_run: UInt
		
		/* Moving average of % profit */
		access(contract)
		var average_long_profit_ema150: UFix64
		
		access(contract)
		var average_long_loss_ema150: UFix64
		
		access(contract)
		var average_short_profit_ema150: UFix64
		
		access(contract)
		var average_short_loss_ema150: UFix64
		
		/* Log of equity and totals */
		access(self)
		var historical_equity: [Equity]
		
		access(contract)
		var equity_max: UFix64
		
		init(){ 
			self.historical = []
			self.historical_equity = []
			self.positive_long_total = 0
			self.negative_long_total = 0
			self.positive_long_run = 0
			self.negative_long_run = 0
			self.positive_short_total = 0
			self.negative_short_total = 0
			self.positive_short_run = 0
			self.negative_short_run = 0
			self.equity_max = 0.0
			self.average_long_profit_ema150 = 0.0
			self.average_long_loss_ema150 = 0.0
			self.average_short_profit_ema150 = 0.0
			self.average_short_loss_ema150 = 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun findOpen(_symbol: String, _ticket: UInt64): Trade?{ 
			var pos: Int = self.historical.length - 1
			var openTrade: Trade? = nil
			while pos > 0{ 
				var trade: Trade = self.historical[pos]
				if _symbol == trade.symbol && trade.ticket == _ticket{ 
					if trade.closeTime == 0{ 
						return trade
					}
				}
				pos = pos - 1
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun equityMinMaxBetween(start: UFix64, end: UFix64): [UFix64]{ 
			var min: UFix64 = UFix64.max
			var max: UFix64 = 0.0
			var cnt: Int = self.historical_equity.length
			while cnt > 0{ 
				cnt = cnt - 1
				var eq = self.historical_equity[cnt]
				if eq.timestamp < end{ 
					if eq.timestamp < start{ 
						cnt = 0
						break
					} else{ 
						if eq.value < max{ 
							max = eq.value
						}
						if min > eq.value{ 
							min = eq.value
						}
					}
				}
			}
			return [min, max]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pushEquity(_equity: UFix64): TradeMetadataRebuild{ 
			let oldMetadata = self.metadata()
			var eq: Equity = Equity(_value: _equity)
			self.historical_equity.append(eq)
			if self.equity_max < _equity{ 
				self.equity_max = _equity
			}
			/* Determine if the NFT needs to be rebuilt */
			let newMetadata = self.metadata()
			return TradeMetadataRebuild(
				_metadata: newMetadata,
				_rebuild: !oldMetadata.equal(md: newMetadata)
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pushTrade(_trade: Trade): TradeMetadataRebuild{ 
			let oldMetadata = self.metadata()
			self.pushEquity(_equity: _trade.equity)
			/* Calculate the running totals for completed trades */
			if _trade.closeTime != 0{ // Has the trade completed 
				
				if _trade.tradeType == TradeType.Long{ // Is the trade long 
					
					if _trade.profit > 0.0{ 
						self.positive_long_total = self.positive_long_total + 1
						self.positive_long_run = self.positive_long_run + 1
						self.negative_long_run = 0
					} else{ 
						self.negative_long_total = self.negative_long_total + 1
						self.negative_long_run = self.positive_long_run + 1
						self.positive_long_run = 0
					}
				} else if _trade.tradeType == TradeType.Short{ 
					if _trade.profit > 0.0{ 
						self.positive_short_total = self.positive_short_total + 1
						self.positive_short_run = self.positive_short_run + 1
						self.negative_short_run = 0
					} else{ 
						self.negative_short_total = self.negative_short_total + 1
						self.negative_short_run = self.positive_short_run + 1
						self.positive_short_run = 0
					}
				}
				var open: Trade? = self.findOpen(_symbol: _trade.symbol, _ticket: _trade.ticket)
				if open != nil{ 
					var start: UFix64 = (open!).onchain // Start timestamp
					
					var end: UFix64 = _trade.onchain // End timestamp
					
					/* Find minimum and maximum equity value for the duration of the open trade */
					var minmax: [UFix64] = self.equityMinMaxBetween(start: start, end: end)
					_trade.minEquity = minmax[0]
					_trade.maxEquity = minmax[1]
					/* Calculate 150 trade exponential moving average percentage for profit and loss */
					let ema = 2.0 / 150.0
					let invEma = 1.0 - ema
					var profitPercent: Fix64 = _trade.profit / Fix64((open!).equity)
					if _trade.profit > 0.0{ 
						if _trade.tradeType == TradeType.Short{ 
							if self.positive_short_total == 1{ 
								self.average_short_profit_ema150 = UFix64(profitPercent)
							} else{ 
								self.average_short_profit_ema150 = self.average_short_profit_ema150 * invEma + UFix64(profitPercent) * ema
							}
						} else if _trade.tradeType == TradeType.Long{ 
							if self.positive_long_total == 1{ 
								self.average_long_profit_ema150 = UFix64(profitPercent)
							} else{ 
								self.average_long_profit_ema150 = self.average_long_profit_ema150 * invEma + UFix64(profitPercent) * ema
							}
						}
					} else if _trade.profit < 0.0{ 
						var lossPercent: UFix64 = UFix64(-profitPercent)
						if _trade.tradeType == TradeType.Short{ 
							if self.negative_short_total == 1{ 
								self.average_short_loss_ema150 = lossPercent
							} else{ 
								self.average_short_loss_ema150 = self.average_short_loss_ema150 * invEma + lossPercent * ema
							}
						} else if _trade.tradeType == TradeType.Long{ 
							if self.negative_long_total == 1{ 
								self.average_long_loss_ema150 = lossPercent
							} else{ 
								self.average_long_loss_ema150 = self.average_long_loss_ema150 * invEma + lossPercent * ema
							}
						}
					}
				}
			}
			/* Every trade is added to the historical data to allow for verification */
			self.historical.append(_trade)
			/* Determine if the NFT needs to be rebuilt */
			let newMetadata = self.metadata()
			return TradeMetadataRebuild(
				_metadata: newMetadata,
				_rebuild: !oldMetadata.equal(md: newMetadata)
			)
		}
		
		/* INTERMEDIATE CALCULATIONS */
		/* Return last recorded equity value */
		access(TMP_ENTITLEMENT_OWNER)
		fun Equity(): UFix64{ 
			let len: Int = self.historical_equity.length
			if len == 0{ 
				return 0.0
			} else{ 
				return self.historical_equity[len - 1].value
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun DrawDown(): UFix64{ 
			let equity = self.Equity()
			if equity == 0.0{ 
				return 0.0
			} else{ 
				return self.equity_max / equity
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun WinRate(): UFix64{ 
			var ptotal: UFix64 = UFix64(self.positive_long_total + self.positive_short_total)
			var total: UFix64 =
				ptotal + UFix64(self.negative_long_total + self.negative_short_total)
			if total == 0.0 || ptotal == 0.0{ 
				return 0.0
			} else{ 
				return ptotal / total
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun AverageProfitAndLoss(): [UFix64]{ 
			var aveP: Fix64 = 0.0
			var aveL: Fix64 = 0.0
			var avePC: Fix64 = 0.0
			var aveLC: Fix64 = 0.0
			for trade in self.historical{ 
				if trade.profit > 0.0{ 
					aveP = aveP + trade.profit
					avePC = avePC + 1.0
				} else if trade.profit < 0.0{ 
					aveL = aveL - trade.profit
					aveLC = aveLC + 1.0
				}
			}
			var avePnL: [UFix64] = []
			if avePC == 0.0{ 
				avePnL.append(0.0)
			} else{ 
				avePnL.append(UFix64(aveP / avePC))
			}
			if aveLC == 0.0{ 
				avePnL.append(0.0)
			} else{ 
				avePnL.append(UFix64(aveL / aveLC))
			}
			return avePnL
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Score(): UFix64{ 
			var pl: [UFix64] = self.AverageProfitAndLoss()
			var win: UFix64 = self.WinRate()
			if pl[0] == 0.0{ 
				pl[0] = 1.0
			}
			if pl[1] == 0.0{ 
				pl[1] = 1.0
			}
			var score: UFix64 = pl[0] / pl[1] * win
			if score > 79.999999{} 
			return score
		}
		
		/* ACHIEVEMENTS */
		access(TMP_ENTITLEMENT_OWNER)
		fun Provisional_Achievement(): Bool{ 
			/* Duration of 60 days in seconds */
			let sixty_days: UFix64 = 60.0 * 24.0 * 60.0 * 60.0
			/* If a user has less than 50 trades they are provisional */
			if self.historical.length < 50{ 
				return true
			}
			/* Additionally if they have less than 60 days of trades on chain they are provisional */
			if self.historical[0].onchain + sixty_days < getCurrentBlock().timestamp{ 
				return true
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Bear_Achievement(): Bool{ 
			return self.positive_short_total > 25
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Bull_Achievement(): Bool{ 
			return self.positive_long_total > 25
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Piggybank_Achievement(): Bool{ 
			return self.positive_long_total + self.positive_short_total > 50
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Scales_Achievement(): Bool{ 
			return self.positive_short_total > 25 && self.positive_long_total > 25
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Robot_Achievement(): Bool{ 
			return self.positive_long_total + self.positive_short_total > 100
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Bank_Achievement(): Bool{ 
			return self.Equity() > 1000.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Moneybags_Achievement(): Bool{ 
			return self.Equity() > 10000.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Safe_Achievement(): Bool{ 
			return self.DrawDown() < 0.10
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Crown1_Achievement(): Bool{ 
			return true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Crown2_Achievement(): Bool{ 
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Diamond1_Achievement(): Bool{ 
			return true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun Diamond2_Achievement(): Bool{ 
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun OnFire_Achievement(): Bool{ 
			return self.positive_long_run > 10 || self.positive_short_run > 10
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun metadata(): TradeMetadata{ 
			var pl: [UFix64] = self.AverageProfitAndLoss()
			return TradeMetadata(
				_score: self.Score(),
				_drawdown: self.DrawDown(),
				_winrate: self.WinRate(),
				_tradeCount: UInt64(self.historical.length),
				_equity: self.Equity(),
				_average_profit: pl[0],
				_average_loss: pl[1],
				_average_long_profit_ema150: self.average_long_profit_ema150,
				_average_long_loss_ema150: self.average_long_loss_ema150,
				_average_short_profit_ema150: self.average_short_profit_ema150,
				_average_short_loss_ema150: self.average_short_loss_ema150,
				_achievement_provisional: self.Provisional_Achievement(),
				_achievement_bear: self.Bear_Achievement(),
				_achievement_bull: self.Bull_Achievement(),
				_achievement_piggyban: self.Piggybank_Achievement(),
				_achievement_scales: self.Scales_Achievement(),
				_achievement_robot: self.Robot_Achievement(),
				_achievement_bank: self.Bank_Achievement(),
				_achievement_moneybags: self.Moneybags_Achievement(),
				_achievement_safe: self.Safe_Achievement(),
				_achievement_crown1: self.Crown1_Achievement(),
				_achievement_crown2: self.Crown2_Achievement(),
				_achievement_diamond1: self.Diamond1_Achievement(),
				_achievement_diamond2: self.Diamond2_Achievement(),
				_achievement_onfire: self.OnFire_Achievement()
			)
		}
	}
}
