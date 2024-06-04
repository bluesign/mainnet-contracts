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

	import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract ToucansTokens{ 
	access(self)
	let tokens:{ Type: TokenInfo}
	
	access(all)
	struct TokenInfo{ 
		access(all)
		let contractName: String
		
		access(all)
		let contractAddress: Address
		
		access(all)
		let tokenType: Type
		
		access(all)
		let symbol: String
		
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		init(
			_ cn: String,
			_ ca: Address,
			_ s: String,
			_ rp: PublicPath,
			_ pp: PublicPath,
			_ sp: StoragePath
		){ 
			self.contractName = cn
			self.contractAddress = ca
			let caToString: String = ca.toString()
			self.tokenType = CompositeType(
					"A.".concat(caToString.slice(from: 2, upTo: caToString.length)).concat(
						".".concat(cn)
					).concat(".Vault")
				)!
			self.symbol = s
			self.receiverPath = rp
			self.publicPath = pp
			self.storagePath = sp
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addToken(tokenInfo: TokenInfo){ 
			ToucansTokens.tokens[tokenInfo.tokenType] = tokenInfo
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeToken(tokenType: Type){ 
			ToucansTokens.tokens.remove(key: tokenType)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTokenInfo(tokenType: Type): TokenInfo?{ 
		return self.tokens[tokenType]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTokenSymbol(tokenType: Type): String?{ 
		return self.tokens[tokenType]?.symbol
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTokenInfoFromSymbol(symbol: String): TokenInfo?{ 
		for info in self.tokens.values{ 
			if info.symbol == symbol{ 
				return info
			}
		}
		return nil
	}
	
	// stringAddress DOES NOT include the `0x`
	access(TMP_ENTITLEMENT_OWNER)
	fun stringToAddress(stringAddress: String): Address{ 
		var r: UInt64 = 0
		var bytes: [UInt8] = stringAddress.decodeHex()
		while bytes.length > 0{ 
			r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
		}
		return Address(r)
	}
	
	init(){ 
		self.tokens ={ 
				Type<@FlowToken.Vault>():
				TokenInfo(
					"FlowToken",
					self.stringToAddress(
						stringAddress: FlowToken.getType().identifier.slice(from: 2, upTo: 18)
					),
					"FLOW",
					/public/flowTokenReceiver,
					/public/flowTokenBalance,
					/storage/flowTokenVault
				),
				Type<@FiatToken.Vault>():
				TokenInfo(
					"FiatToken",
					self.stringToAddress(
						stringAddress: FiatToken.getType().identifier.slice(from: 2, upTo: 18)
					),
					"USDC",
					/public/USDCVaultReceiver,
					/public/USDCVaultBalance,
					/storage/USDCVault
				)
			}
		self.account.storage.save(<-create Admin(), to: /storage/ToucansTokensAdmin)
	}
}
