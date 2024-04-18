import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract BloctoPrize{ 
	access(contract)
	var totalCampaigns: Int
	
	access(contract)
	var campaigns: [Campaign]
	
	access(contract)
	var tokens:{ String: Token}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let ClaimerStoragePath: StoragePath
	
	access(all)
	let ClaimerPublicPath: PublicPath
	
	access(all)
	resource Admin{ 
		access(all)
		fun createCampaign(
			title: String,
			description: String,
			bannerUrl: String?,
			partner: String?,
			partnerLogo: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			cancelled: Bool?
		){ 
			BloctoPrize.campaigns.append(
				Campaign(
					title: title,
					description: description,
					bannerUrl: bannerUrl,
					partner: partner,
					partnerLogo: partnerLogo,
					startAt: startAt,
					endAt: endAt,
					cancelled: cancelled
				)
			)
			BloctoPrize.totalCampaigns = BloctoPrize.totalCampaigns + 1
		}
		
		access(all)
		fun updateCampaign(
			id: Int,
			title: String?,
			description: String?,
			bannerUrl: String?,
			partner: String?,
			partnerLogo: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			cancelled: Bool?
		){ 
			BloctoPrize.campaigns[id].update(
				title: title,
				description: description,
				bannerUrl: bannerUrl,
				partner: partner,
				partnerLogo: partnerLogo,
				startAt: startAt,
				endAt: endAt,
				cancelled: cancelled
			)
		}
		
		access(all)
		fun addWinners(id: Int, addresses: [Address], prizeIndex: Int){ 
			BloctoPrize.campaigns[id].addWinners(addresses: addresses, prizeIndex: prizeIndex)
		}
		
		access(all)
		fun removeWinners(id: Int, addresses: [Address], prizeIndex: Int){ 
			BloctoPrize.campaigns[id].removeWinners(addresses: addresses, prizeIndex: prizeIndex)
		}
		
		access(all)
		fun addPrize(id: Int, name: String, tokenKey: String, amount: UFix64){ 
			BloctoPrize.campaigns[id].addPrize(
				prize: Prize(name: name, tokenKey: tokenKey, amount: amount)
			)
		}
		
		// remove fungible tokens for contract
		access(all)
		fun removeToken(tokenKey: String){ 
			let token = BloctoPrize.tokens[tokenKey]!
			destroy BloctoPrize.account.storage.load<@AnyResource>(from: token.vaultPath)
			BloctoPrize.account.unlink(token.receiverPath)
			BloctoPrize.account.unlink(token.balancePath)
			BloctoPrize.tokens[tokenKey] = nil
		}
		
		// enable arbitrary fungible tokens for contract
		access(all)
		fun addToken(
			tokenKey: String,
			name: String,
			contractName: String,
			vaultPath: StoragePath,
			receiverPath: PublicPath,
			balancePath: PublicPath,
			address: Address,
			vault: @{FungibleToken.Vault}
		){ 
			BloctoPrize.tokens[tokenKey] = Token(
					name: name,
					contractName: contractName,
					vaultPath: vaultPath,
					receiverPath: receiverPath,
					balancePath: balancePath,
					address: address
				)
			BloctoPrize.account.storage.save(<-vault, to: vaultPath)
			BloctoPrize.account.link<&FungibleToken.Vault>(balancePath, target: vaultPath)
			BloctoPrize.account.link<&FungibleToken.Vault>(receiverPath, target: vaultPath)
		}
	}
	
	// empty source for verifing the prize claimer with resource owner
	access(all)
	resource interface ClaimerPublic{} 
	
	access(all)
	resource Claimer: ClaimerPublic{ 
		access(all)
		fun claimPrizes(id: Int){ 
			let address = (self.owner!).address
			if BloctoPrize.campaigns[id].winners[address] != nil{ 
				BloctoPrize.campaigns[id].claimPrizes(address: address)
			}
		}
	}
	
	access(all)
	struct Token{ 
		access(all)
		let name: String
		
		access(all)
		let contractName: String
		
		access(all)
		let vaultPath: StoragePath
		
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		let balancePath: PublicPath
		
		access(all)
		let address: Address
		
		init(
			name: String,
			contractName: String,
			vaultPath: StoragePath,
			receiverPath: PublicPath,
			balancePath: PublicPath,
			address: Address
		){ 
			self.name = name
			self.contractName = contractName
			self.vaultPath = vaultPath
			self.receiverPath = receiverPath
			self.balancePath = balancePath
			self.address = address
		}
	}
	
	access(all)
	struct Prize{ 
		access(all)
		let name: String
		
		access(all)
		let token: Token
		
		access(all)
		let amount: UFix64
		
		init(name: String, tokenKey: String, amount: UFix64){ 
			self.name = name
			self.token = BloctoPrize.tokens[tokenKey]!
			self.amount = amount
		}
	}
	
	access(all)
	struct Campaign{ 
		access(all)
		let id: Int
		
		access(all)
		var title: String
		
		access(all)
		var description: String
		
		access(all)
		var bannerUrl: String?
		
		access(all)
		var partner: String?
		
		access(all)
		var partnerLogo: String?
		
		// address to prize indexes mapping, user can win multiple prizes in same campaign
		access(all)
		var winners:{ Address: [Int]}
		
		access(all)
		var claimed:{ Address: Bool}
		
		access(all)
		var prizes: [Prize]
		
		access(all)
		var cancelled: Bool
		
		access(all)
		var startAt: UFix64?
		
		access(all)
		var endAt: UFix64?
		
		init(
			title: String,
			description: String,
			bannerUrl: String?,
			partner: String?,
			partnerLogo: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			cancelled: Bool?
		){ 
			pre{ 
				title.length <= 1000:
					"New title too long"
				description.length <= 1000:
					"New description too long"
			}
			self.id = BloctoPrize.totalCampaigns
			self.title = title
			self.description = description
			self.bannerUrl = bannerUrl
			self.partner = partner
			self.partnerLogo = partnerLogo
			self.prizes = []
			self.winners ={} 
			self.claimed ={} 
			self.startAt = startAt
			self.endAt = endAt
			self.cancelled = cancelled == nil ? false : cancelled!
		}
		
		access(all)
		fun update(
			title: String?,
			description: String?,
			bannerUrl: String?,
			partner: String?,
			partnerLogo: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			cancelled: Bool?
		){ 
			pre{ 
				title?.length ?? 0 <= 1000:
					"Title too long"
				description?.length ?? 0 <= 1000:
					"Description too long"
			}
			self.title = title != nil ? title! : self.title
			self.description = description != nil ? description! : self.description
			if bannerUrl != nil{ 
				self.bannerUrl = bannerUrl
			}
			if partner != nil{ 
				self.partner = partner
			}
			if partnerLogo != nil{ 
				self.partnerLogo = partnerLogo
			}
			if startAt != nil{ 
				self.startAt = startAt!
			}
			if endAt != nil{ 
				self.endAt = endAt!
			}
			self.cancelled = cancelled != nil ? cancelled! : self.cancelled
		}
		
		access(all)
		fun addWinners(addresses: [Address], prizeIndex: Int){ 
			for address in addresses{ 
				if self.winners[address] == nil{ 
					self.winners[address] = []
				}
				(self.winners[address]!).append(prizeIndex)
			}
		}
		
		access(all)
		fun removeWinners(addresses: [Address], prizeIndex: Int){ 
			for address in addresses{ 
				var index = 0
				let length = (self.winners[address]!).length
				while index < length{ 
					if (self.winners[address]!)[index] == prizeIndex{ 
						(self.winners[address]!).remove(at: index)
						if (self.winners[address]!).length == 0{ 
							self.winners[address] = nil
						}
						break
					}
					index = index + 1
				}
			}
		}
		
		access(all)
		fun addPrize(prize: Prize){ 
			self.prizes.append(prize)
		}
		
		access(all)
		fun claimPrizes(address: Address){ 
			pre{ 
				self.cancelled == false:
					"Campaign cancelled."
				self.startAt! <= getCurrentBlock().timestamp:
					"Not started."
				self.endAt == nil || self.endAt! >= getCurrentBlock().timestamp:
					"Expired."
				self.claimed[address] == nil:
					"Already claimed."
				self.winners[address] != nil:
					"Not a winner."
			}
			let prizeIndexes = self.winners[address]!
			for index in prizeIndexes{ 
				let prize = self.prizes[index]
				let vaultRef = BloctoPrize.account.storage.borrow<&{FungibleToken.Vault}>(from: prize.token.vaultPath) ?? panic("Could not borrow reference to the owner's Vault!")
				let sentVault <- vaultRef.withdraw(amount: prize.amount)
				let recipient = getAccount(address)
				let receiverRef = (recipient.capabilities.get<&{FungibleToken.Receiver}>(prize.token.receiverPath)!).borrow() ?? panic("Could not borrow receiver reference to the recipient's Vault")
				receiverRef.deposit(from: <-sentVault)
			}
			self.claimed[address] = true
		}
	}
	
	access(all)
	fun initClaimer(): @Claimer{ 
		return <-create Claimer()
	}
	
	access(all)
	fun getTokens():{ String: Token}{ 
		return self.tokens
	}
	
	access(all)
	fun getCampaignsLentgh(): Int{ 
		return self.campaigns.length
	}
	
	access(all)
	fun getCampaigns(): [Campaign]{ 
		return self.campaigns
	}
	
	access(all)
	fun getCampaign(id: Int): Campaign{ 
		return self.campaigns[id]
	}
	
	init(){ 
		self.campaigns = []
		self.totalCampaigns = 0
		self.tokens ={} 
		self.AdminStoragePath = /storage/bloctoPrizeAdmin
		self.ClaimerStoragePath = /storage/bloctoPrizeClaimer
		self.ClaimerPublicPath = /public/bloctoPrizeClaimer
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
