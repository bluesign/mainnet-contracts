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
contract LCubeCompany{ 
	access(all)
	let CompanyPublicPath: PublicPath
	
	access(all)
	let CompanyStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalCount: UInt64
	
	access(contract)
	var idSeq: UInt64
	
	access(all)
	event CompanyCreated(
		address: Address,
		name: String,
		stakeRate: UFix64,
		subAddresses: [
			String
		],
		subShares: [
			UFix64
		]
	)
	
	access(all)
	event CompanyDestroyed(address: Address, name: String)
	
	access(all)
	struct SubAccount{ 
		access(contract)
		var addr: String
		
		access(contract)
		var share: UFix64
		
		access(contract)
		var mail: String
		
		init(addr: String, share: UFix64, mail: String){ 
			self.addr = addr
			self.share = share
			self.mail = mail
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddr(): String{ 
			return self.addr
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getShare(): UFix64{ 
			return self.share
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMail(): String{ 
			return self.mail
		}
	}
	
	access(all)
	struct CompanyDetail{ 
		access(all)
		var companyName: String
		
		access(all)
		var desc: String
		
		access(all)
		var mail: String
		
		access(all)
		var stakeRate: UFix64
		
		init(companyName: String, desc: String, mail: String, stakeRate: UFix64){ 
			self.companyName = companyName
			self.desc = desc
			self.mail = mail
			self.stakeRate = stakeRate
		}
	}
	
	access(all)
	resource interface ICompany{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getCompanyName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDesc(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMail(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakeRate(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): AnyStruct
	}
	
	access(all)
	resource Company: ICompany{ 
		access(contract)
		var id: UInt64
		
		access(contract)
		var companyName: String
		
		access(contract)
		var desc: String
		
		access(contract)
		var mail: String
		
		access(contract)
		var stakeRate: UFix64
		
		access(contract)
		var subAccounts: [AnyStruct]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): UInt64{ 
			return self.id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCompanyName(): String{ 
			return self.companyName
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDesc(): String{ 
			return self.desc
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMail(): String{ 
			return self.mail
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStakeRate(): UFix64{ 
			return self.stakeRate
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSubAccounts(): [AnyStruct]{ 
			return self.subAccounts
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): AnyStruct{ 
			return CompanyDetail(companyName: self.companyName, desc: self.desc, mail: self.mail, stakeRate: self.stakeRate)
		}
		
		init(companyName: String, desc: String, mail: String, stakeRate: UFix64, subAddresses: [String], subShares: [UFix64], subMails: [String]){ 
			self.id = LCubeCompany.idSeq
			self.companyName = companyName
			self.desc = desc
			self.mail = mail
			self.stakeRate = stakeRate
			var subAccounts: [SubAccount] = []
			var i: UInt32 = 0
			for subAddress in subAddresses{ 
				subAccounts.append(SubAccount(addr: subAddress, share: subShares[i], mail: subMails[i]))
				i = i + 1
			}
			self.subAccounts = subAccounts
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createCompany(
			companyName: String,
			desc: String,
			mail: String,
			stakeRate: UFix64,
			subAddresses: [
				String
			],
			subShares: [
				UFix64
			],
			subMails: [
				String
			],
			address: Address
		): @Company{ 
			LCubeCompany.totalCount = LCubeCompany.totalCount + 1
			LCubeCompany.idSeq = LCubeCompany.idSeq + 1
			let a <-
				create Company(
					companyName: companyName,
					desc: desc,
					mail: mail,
					stakeRate: stakeRate,
					subAddresses: subAddresses,
					subShares: subShares,
					subMails: subMails
				)
			emit CompanyCreated(
				address: address,
				name: companyName,
				stakeRate: stakeRate,
				subAddresses: subAddresses,
				subShares: subShares
			)
			return <-a
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun destroyCompany(company: @Company, address: Address){ 
			emit CompanyDestroyed(address: address, name: company.getCompanyName())
			destroy company
		}
	}
	
	init(adminAccount: AuthAccount){ 
		self.totalCount = 0
		self.idSeq = 0
		self.CompanyPublicPath = /public/LCubeCompanyPublic
		self.CompanyStoragePath = /storage/LCubeCompanyStorage
		self.AdminStoragePath = /storage/LCubeAdminStorage
		let admin <- create Admin()
		adminAccount.save(<-admin, to: self.AdminStoragePath)
	}
}
