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

import cBridge from "./cBridge.cdc"

import PbPegged from "./PbPegged.cdc"

// DelayedTransfer must from same account as addXfer is limited to access(account) to avoid spam
import DelayedTransfer from "./DelayedTransfer.cdc"

// user deposit into SafeBox, cBridge will mint corresponding ERC20 tokens on specified dest chain.
// when user burn ERC20 tokens, cBridge will withdraw FungibleTokens to user specified receiver address
access(all)
contract SafeBox{ 
	// path for admin resource
	access(all)
	let AdminPath: StoragePath
	
	// ========== events ==========
	access(all)
	event Deposited(
		depoId: String,
		depositor: Address,
		token: String,
		amount: UFix64,
		mintChId: UInt64,
		mintAddr: String
	)
	
	access(all)
	event Withdrawn(
		wdId: String,
		receiver: Address,
		token: String,
		amount: UFix64,
		refChId: UInt64,
		burnAddr: String,
		refId: String
	)
	
	// ========== structs ==========
	// token vault type identifier string to its config so we can borrow for deposit/withdraw
	access(all)
	struct TokenCfg{ 
		access(all)
		let vaultPub: PublicPath
		
		access(all)
		let vaultSto: StoragePath
		
		access(all)
		let minDepo: UFix64
		
		access(all)
		let maxDepo: UFix64
		
		// if withdraw amount > delayThreshold, put into delayed transfer map
		access(all)
		let delayThreshold: UFix64
		
		init(
			vaultPub: PublicPath,
			vaultSto: StoragePath,
			minDepo: UFix64,
			maxDepo: UFix64,
			delayThreshold: UFix64
		){ 
			self.vaultPub = vaultPub
			self.vaultSto = vaultSto
			self.minDepo = minDepo
			self.maxDepo = maxDepo
			self.delayThreshold = delayThreshold
		}
	}
	
	// info about one user deposit
	access(all)
	struct DepoInfo{ 
		access(all)
		let amt: UFix64
		
		access(all)
		let mintChId: UInt64
		
		access(all)
		let mintAddr: String
		
		access(all)
		let nonce: UInt64
		
		init(amt: UFix64, mintChId: UInt64, mintAddr: String, nonce: UInt64){ 
			self.amt = amt
			self.mintChId = mintChId
			self.mintAddr = mintAddr
			self.nonce = nonce
		}
	}
	
	// ========== contract states and maps ==========
	// unique chainid required by cbridge system
	access(all)
	let chainID: UInt64
	
	// domainPrefix to ensure no replay on co-sign msgs
	access(contract)
	let domainPrefix: [UInt8]
	
	// similar to solidity pausable
	access(all)
	var isPaused: Bool
	
	// key is token vault identifier, eg. A.1122334455667788.ExampleToken.Vault
	access(account)
	var tokMap:{ String: TokenCfg}
	
	// save for each deposit/withdraw to avoid duplicated process
	// key is calculated depoId or wdId
	access(account)
	var records:{ String: Bool}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTokenConfig(identifier: String): TokenCfg{ 
		let tokenCfg = self.tokMap[identifier]!
		return tokenCfg
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun recordExist(id: String): Bool{ 
		return self.records.containsKey(id)
	}
	
	// ========== resource ==========
	access(all)
	resource SafeBoxAdmin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addTok(identifier: String, tok: TokenCfg){ 
			assert(!SafeBox.tokMap.containsKey(identifier), message: "this token already exist")
			SafeBox.tokMap[identifier] = tok
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rmTok(identifier: String){ 
			assert(SafeBox.tokMap.containsKey(identifier), message: "this token do not exist")
			SafeBox.tokMap.remove(key: identifier)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pause(){ 
			SafeBox.isPaused = true
			DelayedTransfer.pause()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unPause(){ 
			SafeBox.isPaused = false
			DelayedTransfer.unPause()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createSafeBoxAdmin(): @SafeBoxAdmin{ 
			return <-create SafeBoxAdmin()
		}
	}
	
	// ========== functions ==========
	// chainid must be same as cbridge common proto FLOW_MAINNET = 12340001; FLOW_TEST = 12340002;
	init(chID: UInt64){ 
		self.chainID = chID
		// domainPrefix is chainID big endianbytes followed by "A.xxxxxx.SafeBox".utf8, xxxx is this contract account
		self.domainPrefix = chID.toBigEndianBytes().concat(self.getType().identifier.utf8)
		self.isPaused = false
		self.records ={} 
		self.tokMap ={} 
		self.AdminPath = /storage/SafeBoxAdmin
		self.account.storage.save<@SafeBoxAdmin>(<-create SafeBoxAdmin(), to: self.AdminPath)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun deposit(from: &{FungibleToken.Provider}, info: DepoInfo){ 
		pre{ 
			!self.isPaused:
				"contract is paused"
		}
		let user = (from.owner!).address
		let tokStr = from.getType().identifier
		let tokenCfg = self.tokMap[tokStr]!
		assert(info.amt >= tokenCfg.minDepo, message: "deposit amount less than min deposit")
		if tokenCfg.maxDepo > 0.0{ 
			assert(info.amt < tokenCfg.maxDepo, message: "deposit amount larger than max deposit")
		}
		// calculate depoId
		let concatStr =
			user.toString().concat(tokStr).concat(info.amt.toString()).concat(info.nonce.toString())
		let depoId = String.encodeHex(HashAlgorithm.SHA3_256.hash(concatStr.utf8))
		assert(!self.records.containsKey(depoId), message: "depoId already exists")
		self.records[depoId] = true
		let recev =
			self.account.capabilities.get<&{FungibleToken.Receiver}>(tokenCfg.vaultPub).borrow<
				&{FungibleToken.Receiver}
			>()
			?? panic("Could not borrow a reference to the receiver")
		recev.deposit(from: <-from.withdraw(amount: info.amt))
		emit Deposited(
			depoId: depoId,
			depositor: user,
			token: tokStr,
			amount: info.amt,
			mintChId: info.mintChId,
			mintAddr: info.mintAddr
		)
	}
	
	// we can also use recipient: &AnyResource{FungibleToken.Receiver} to do deposit.
	// but now, we use the tokCfg pubPath to get the Receiver first.
	access(TMP_ENTITLEMENT_OWNER)
	fun withdraw(token: String, wdmsg: [UInt8], sigs: [cBridge.SignerSig]){ 
		pre{ 
			!self.isPaused:
				"contract is paused"
		}
		// calculate correct data by prefix domain, sgn needs to sign the same way
		let domain = self.domainPrefix.concat("Withdraw".utf8)
		assert(
			cBridge.verify(data: domain.concat(wdmsg), sigs: sigs),
			message: "verify sigs failed"
		)
		let wdInfo = PbPegged.Withdraw(wdmsg)
		assert(wdInfo.eqToken(tkStr: token), message: "mismatch token string")
		// calculate wdId and check records map
		// withdraw from self storage
		// and deposit into receiver
		// emit Withdrawn
		let tokCfg = SafeBox.tokMap[token] ?? panic("token not support in contract")
		let wdId = String.encodeHex(HashAlgorithm.SHA3_256.hash(wdmsg))
		assert(!self.records.containsKey(wdId), message: "wdId already exists")
		self.records[wdId] = true
		let receiverCap =
			getAccount(wdInfo.receiver).capabilities.get<&{FungibleToken.Receiver}>(tokCfg.vaultPub)
		let vaultRef =
			self.account.storage.borrow<&{FungibleToken.Provider}>(from: tokCfg.vaultSto)
			?? panic("Could not borrow reference to the owner's Vault!")
		// vault that holds to deposit ft
		let vault <- vaultRef.withdraw(amount: wdInfo.amount)
		if wdInfo.amount > tokCfg.delayThreshold{ 
			// add to delayed xfer
			DelayedTransfer.addDelayXfer(id: wdId, receiverCap: receiverCap!, from: <-vault)
		} else{ 
			let receiverRef = receiverCap.borrow() ?? panic("Could not borrow a reference to the receiver")
			// deposit into receiver
			receiverRef.deposit(from: <-vault)
		}
		// emit withdrawn even added to delay, to be consistent with solidity
		emit Withdrawn(
			wdId: wdId,
			receiver: wdInfo.receiver,
			token: token,
			amount: wdInfo.amount,
			refChId: wdInfo.refChainId,
			burnAddr: wdInfo.burnAccount,
			refId: wdInfo.refId
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun executeDelayedTransfer(wdId: String){ 
		pre{ 
			!self.isPaused:
				"contract is paused"
		}
		DelayedTransfer.executeDelayXfer(wdId)
	}
}
