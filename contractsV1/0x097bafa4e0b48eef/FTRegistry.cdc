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
contract FTRegistry{ 
	/* Event */
	access(all)
	event ContractInitialized()
	
	access(all)
	event FTInfoRegistered(alias: String, typeIdentifier: String)
	
	access(all)
	event FTInfoRemoved(alias: String, typeIdentifier: String)
	
	/* Variables */
	// Mapping of {Type Identifier : FT Info Struct}
	access(contract)
	var fungibleTokenList:{ String: FTInfo}
	
	access(contract)
	var aliasMap:{ String: String}
	
	/* Struct */
	access(all)
	struct FTInfo{ 
		access(all)
		let alias: String
		
		access(all)
		let type: Type
		
		access(all)
		let typeIdentifier: String
		
		// Whether it is stable coin or other type of coins. 
		access(all)
		let tag: [String]
		
		access(all)
		let icon: String?
		
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		let receiverPathIdentifier: String
		
		access(all)
		let balancePath: PublicPath
		
		access(all)
		let balancePathIdentifier: String
		
		access(all)
		let vaultPath: StoragePath
		
		access(all)
		let vaultPathIdentifier: String
		
		init(
			alias: String,
			type: Type,
			typeIdentifier: String,
			tag: [
				String
			],
			icon: String?,
			receiverPath: PublicPath,
			balancePath: PublicPath,
			vaultPath: StoragePath
		){ 
			self.alias = alias
			self.type = type
			self.typeIdentifier = typeIdentifier
			self.tag = tag
			self.icon = icon
			self.receiverPath = receiverPath
			self.receiverPathIdentifier = receiverPath.toString().slice(
					from: "/public/".length,
					upTo: receiverPath.toString().length
				)
			self.balancePath = balancePath
			self.balancePathIdentifier = balancePath.toString().slice(
					from: "/public/".length,
					upTo: balancePath.toString().length
				)
			self.vaultPath = vaultPath
			self.vaultPathIdentifier = vaultPath.toString().slice(
					from: "/storage/".length,
					upTo: vaultPath.toString().length
				)
		}
	}
	
	/* getters */
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTInfoByTypeIdentifier(_ typeIdentifier: String): FTInfo?{ 
		return FTRegistry.fungibleTokenList[typeIdentifier]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTInfoByAlias(_ alias: String): FTInfo?{ 
		if let identifier = FTRegistry.aliasMap[alias]{ 
			return FTRegistry.fungibleTokenList[identifier]
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTInfo(_ input: String): FTInfo?{ 
		if let info = self.getFTInfoByAlias(input){ 
			return info
		}
		if let info = self.getFTInfoByTypeIdentifier(input){ 
			return info
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTypeIdentifier(_ alias: String): String?{ 
		return FTRegistry.aliasMap[alias]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTInfoAll():{ String: FTInfo}{ 
		return FTRegistry.fungibleTokenList
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSupportedFTAlias(): [String]{ 
		return FTRegistry.aliasMap.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSupportedFTTypeIdentifier(): [String]{ 
		return FTRegistry.aliasMap.values
	}
	
	/* setters */
	access(account)
	fun setFTInfo(
		alias: String,
		type: Type,
		tag: [
			String
		],
		icon: String?,
		receiverPath: PublicPath,
		balancePath: PublicPath,
		vaultPath: StoragePath
	){ 
		if FTRegistry.fungibleTokenList.containsKey(type.identifier){ 
			panic("This FungibleToken Register already exist. Type Identifier : ".concat(type.identifier))
		}
		let typeIdentifier: String = type.identifier
		FTRegistry.fungibleTokenList[typeIdentifier] = FTInfo(
				alias: alias,
				type: type,
				typeIdentifier: typeIdentifier,
				tag: tag,
				icon: icon,
				receiverPath: receiverPath,
				balancePath: balancePath,
				vaultPath: vaultPath
			)
		FTRegistry.aliasMap[alias] = typeIdentifier
		emit FTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)
	}
	
	access(account)
	fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String): FTInfo{ 
		let info =
			FTRegistry.fungibleTokenList.remove(key: typeIdentifier)
			?? panic("Cannot find this Fungible Token Registry. Type : ".concat(typeIdentifier))
		FTRegistry.aliasMap.remove(key: info.alias)
		emit FTInfoRemoved(alias: (info!).alias, typeIdentifier: (info!).typeIdentifier)
		return info
	}
	
	access(account)
	fun removeFTInfoByAlias(_ alias: String): FTInfo{ 
		let typeIdentifier =
			self.getTypeIdentifier(alias)
			?? panic("Cannot find type identifier from this alias. Alias : ".concat(alias))
		return self.removeFTInfoByTypeIdentifier(typeIdentifier)
	}
	
	init(){ 
		self.fungibleTokenList ={} 
		self.aliasMap ={} 
	}
}
