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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SwapError from "./SwapError.cdc"

import SwapConfig from "./SwapConfig.cdc"

import SwapInterfaces from "./SwapInterfaces.cdc"

access(all)
contract SwapFactory{ 
	/// Account which has deployed pair template contract
	access(all)
	var pairContractTemplateAddress: Address
	
	/// All pairs' address array
	access(self)
	let pairs: [Address]
	
	/// pairMap[token0Identifier][token1Identifier] == pairMap[token1Identifier][token0Identifier]
	access(self)
	let pairMap:{ String:{ String: Address}}
	
	/// Pair admin key might be attached in the beginning for the sake of safety reasons,
	/// but it'll be revoked in future for a pure decentralized exchange.
	access(all)
	var pairAccountPublicKey: String?
	
	/// Fee receiver address
	access(all)
	var feeTo: Address?
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/// Events
	access(all)
	event PairCreated(token0Key: String, token1Key: String, pairAddress: Address, numPairs: Int)
	
	access(all)
	event PairTemplateAddressChanged(oldTemplate: Address, newTemplate: Address)
	
	access(all)
	event FeeToAddressChanged(oldFeeTo: Address?, newFeeTo: Address?)
	
	access(all)
	event PairAccountPublicKeyChanged(oldPublicKey: String?, newPublicKey: String?)
	
	/// Create Pair
	///
	/// @Param - token0/1Vault: use createEmptyVault() to create init vault types for SwapPair
	/// @Param - accountCreationFee: fee (0.001 FlowToken) pay for the account creation.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun createPair(
		token0Vault: @{FungibleToken.Vault},
		token1Vault: @{FungibleToken.Vault},
		accountCreationFee: @{FungibleToken.Vault}
	): Address{ 
		pre{ 
			token0Vault.balance == 0.0 && token1Vault.balance == 0.0:
				SwapError.ErrorEncode(msg: "SwapFactory: no need to provide liquidity when creating a pool", err: SwapError.ErrorCode.INVALID_PARAMETERS)
		}
		/// The tokenKey is the type identifier of the token, eg A.f8d6e0586b0a20c7.FlowToken
		let token0Key =
			SwapConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: token0Vault.getType().identifier
			)
		let token1Key =
			SwapConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: token1Vault.getType().identifier
			)
		assert(
			token0Key != token1Key,
			message: SwapError.ErrorEncode(
				msg: "SwapFactory: identical FungibleTokens",
				err: SwapError.ErrorCode.CANNOT_CREATE_PAIR_WITH_SAME_TOKENS
			)
		)
		assert(
			self.getPairAddress(token0Key: token0Key, token1Key: token1Key) == nil,
			message: SwapError.ErrorEncode(
				msg: "SwapFactory: pair already exists",
				err: SwapError.ErrorCode.ADD_PAIR_DUPLICATED
			)
		)
		assert(
			accountCreationFee.balance >= 0.001,
			message: SwapError.ErrorEncode(
				msg: "SwapFactory: insufficient account creation fee",
				err: SwapError.ErrorCode.INVALID_PARAMETERS
			)
		)
		(
			/// Deposit account creation fee into factory account, which then acts as payer of account creation
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow<&{FungibleToken.Receiver}>()!
		).deposit(from: <-accountCreationFee)
		let pairAccount = AuthAccount(payer: self.account)
		if self.pairAccountPublicKey != nil{ 
			pairAccount.keys.add(publicKey: PublicKey(publicKey: (self.pairAccountPublicKey!).decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256), hashAlgorithm: HashAlgorithm.SHA3_256, weight: 1000.0)
		}
		let pairAddress = pairAccount.address
		let pairTemplateContract =
			getAccount(self.pairContractTemplateAddress).contracts.get(name: "SwapPair")!
		/// Deploy pair contract with initialized parameters
		pairAccount.contracts.add(
			name: "SwapPair",
			code: pairTemplateContract.code,
			token0Vault: <-token0Vault,
			token1Vault: <-token1Vault
		)
		
		/// insert pair map
		if self.pairMap.containsKey(token0Key) == false{ 
			self.pairMap.insert(key: token0Key,{} )
		}
		if self.pairMap.containsKey(token1Key) == false{ 
			self.pairMap.insert(key: token1Key,{} )
		}
		(self.pairMap[token0Key]!).insert(key: token1Key, pairAddress)
		(self.pairMap[token1Key]!).insert(key: token0Key, pairAddress)
		self.pairs.append(pairAddress)
		
		/// event
		emit PairCreated(
			token0Key: token0Key,
			token1Key: token1Key,
			pairAddress: pairAddress,
			numPairs: self.pairs.length
		)
		return pairAddress
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyLpTokenCollection(): @LpTokenCollection{ 
		return <-create LpTokenCollection()
	}
	
	/// LpToken Collection Resource
	///
	/// Used to collect all lptoken vaults in the user's local storage
	///
	access(all)
	resource LpTokenCollection: SwapInterfaces.LpTokenCollectionPublic{ 
		access(self)
		var lpTokenVaults: @{Address:{ FungibleToken.Vault}}
		
		init(){ 
			self.lpTokenVaults <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(pairAddr: Address, lpTokenVault: @{FungibleToken.Vault}){ 
			pre{ 
				lpTokenVault.balance > 0.0:
					SwapError.ErrorEncode(msg: "LpTokenCollection: deposit empty lptoken vault", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			}
			let pairPublicRef = getAccount(pairAddr).capabilities.get<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!
			assert(lpTokenVault.getType() == pairPublicRef.getLpTokenVaultType(), message: SwapError.ErrorEncode(msg: "LpTokenCollection: input token vault type mismatch with pair lptoken vault", err: SwapError.ErrorCode.MISMATCH_LPTOKEN_VAULT))
			if self.lpTokenVaults.containsKey(pairAddr){ 
				let vaultRef = (&self.lpTokenVaults[pairAddr] as &{FungibleToken.Vault}?)!
				vaultRef.deposit(from: <-lpTokenVault)
			} else{ 
				self.lpTokenVaults[pairAddr] <-! lpTokenVault
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(pairAddr: Address, amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				self.lpTokenVaults.containsKey(pairAddr):
					SwapError.ErrorEncode(msg: "LpTokenCollection: haven't provided liquidity to pair ".concat(pairAddr.toString()), err: SwapError.ErrorCode.INVALID_PARAMETERS)
			}
			let vaultRef = (&self.lpTokenVaults[pairAddr] as &{FungibleToken.Vault}?)!
			let withdrawVault <- vaultRef.withdraw(amount: amount)
			if vaultRef.balance == 0.0{ 
				let deletedVault <- self.lpTokenVaults[pairAddr] <- nil
				destroy deletedVault
			}
			return <-withdrawVault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getCollectionLength(): Int{ 
			return self.lpTokenVaults.keys.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLpTokenBalance(pairAddr: Address): UFix64{ 
			if self.lpTokenVaults.containsKey(pairAddr){ 
				let vaultRef = (&self.lpTokenVaults[pairAddr] as &{FungibleToken.Vault}?)!
				return vaultRef.balance
			}
			return 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllLPTokens(): [Address]{ 
			return self.lpTokenVaults.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedLPTokens(from: UInt64, to: UInt64): [Address]{ 
			pre{ 
				from <= to && from < UInt64(self.getCollectionLength()):
					SwapError.ErrorEncode(msg: "from index out of range", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			}
			let pairLen = UInt64(self.getCollectionLength())
			let endIndex = to >= pairLen ? pairLen - 1 : to
			var curIndex = from
			// Array.slice() is not supported yet.
			let list: [Address] = []
			while curIndex <= endIndex{ 
				list.append(self.lpTokenVaults.keys[curIndex])
				curIndex = curIndex + 1
			}
			return list
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPairAddress(token0Key: String, token1Key: String): Address?{ 
		let pairExist0To1 =
			self.pairMap.containsKey(token0Key) && (self.pairMap[token0Key]!).containsKey(token1Key)
		let pairExist1To0 =
			self.pairMap.containsKey(token1Key) && (self.pairMap[token1Key]!).containsKey(token0Key)
		if pairExist0To1 && pairExist1To0{ 
			return (self.pairMap[token0Key]!)[token1Key]!
		} else{ 
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPairInfo(token0Key: String, token1Key: String): AnyStruct?{ 
		var pairAddr = self.getPairAddress(token0Key: token0Key, token1Key: token1Key)
		if pairAddr == nil{ 
			return nil
		}
		return (
			getAccount(pairAddr!).capabilities.get<&{SwapInterfaces.PairPublic}>(
				SwapConfig.PairPublicPath
			).borrow()!
		).getPairInfo()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllPairsLength(): Int{ 
		return self.pairs.length
	}
	
	/// Get sliced array of pair addresses (inclusive for both indexes)
	access(TMP_ENTITLEMENT_OWNER)
	fun getSlicedPairs(from: UInt64, to: UInt64): [Address]{ 
		pre{ 
			from <= to && from < UInt64(self.pairs.length):
				SwapError.ErrorEncode(msg: "from index out of range", err: SwapError.ErrorCode.INVALID_PARAMETERS)
		}
		let pairLen = UInt64(self.pairs.length)
		let endIndex = to >= pairLen ? pairLen - 1 : to
		var curIndex = from
		// Array.slice() is not supported yet.
		let list: [Address] = []
		while curIndex <= endIndex{ 
			list.append(self.pairs[curIndex])
			curIndex = curIndex + 1
		}
		return list
	}
	
	/// Get sliced array of PairInfos (inclusive for both indexes)
	access(TMP_ENTITLEMENT_OWNER)
	fun getSlicedPairInfos(from: UInt64, to: UInt64): [AnyStruct]{ 
		let pairSlice: [Address] = self.getSlicedPairs(from: from, to: to)
		var i = 0
		var res: [AnyStruct] = []
		while i < pairSlice.length{ 
			res.append((getAccount(pairSlice[i]).capabilities.get<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!).getPairInfo())
			i = i + 1
		}
		return res
	}
	
	/// Admin function to update feeTo and pair template
	///
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setPairContractTemplateAddress(newAddr: Address){ 
			emit PairTemplateAddressChanged(
				oldTemplate: SwapFactory.pairContractTemplateAddress,
				newTemplate: newAddr
			)
			SwapFactory.pairContractTemplateAddress = newAddr
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFeeTo(feeToAddr: Address){ 
			emit FeeToAddressChanged(oldFeeTo: SwapFactory.feeTo, newFeeTo: feeToAddr)
			SwapFactory.feeTo = feeToAddr
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPairAccountPublicKey(publicKey: String?){ 
			emit PairAccountPublicKeyChanged(
				oldPublicKey: SwapFactory.pairAccountPublicKey,
				newPublicKey: publicKey
			)
			SwapFactory.pairAccountPublicKey = publicKey
		}
	}
	
	init(pairTemplate: Address, pairAccountPublicKey: String?){ 
		self.pairContractTemplateAddress = pairTemplate
		self.pairs = []
		self.pairMap ={} 
		self.pairAccountPublicKey = pairAccountPublicKey
		self.feeTo = nil
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: /storage/swapFactoryAdmin)
		self.account.storage.save(<-create Admin(), to: /storage/swapFactoryAdmin)
	}
}
