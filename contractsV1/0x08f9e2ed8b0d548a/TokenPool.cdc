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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import TeleportedTetherToken from "../0xcfdd90d4a00f7b5b/TeleportedTetherToken.cdc"

import FlowSwapPair from "../0xc6c77b9f5c7a378f/FlowSwapPair.cdc"

// Perpetual pool between FlowToken and TeleportedTetherToken
// Token1: FlowToken
// Token2: TeleportedTetherToken
access(all)
contract TokenPool{ 
	// Frozen flag controlled by Admin
	access(all)
	var isFrozen: Bool
	
	// Virtual FlowToken amount for price calculation
	access(all)
	var virtualToken1Amount: UFix64
	
	// Virtual TeleportedTetherToken amount for price calculation
	access(all)
	var virtualToken2Amount: UFix64
	
	// Price to buy back FLOW
	access(all)
	var buyBackPrice: UFix64
	
	// Used for precise calculations
	access(all)
	var shifter: UFix64
	
	// Constant for maximum of UFix64
	access(all)
	let UFIX64_MAX: UFix64
	
	// Controls FlowToken vault
	access(contract)
	let token1Vault: @FlowToken.Vault
	
	// Controls TeleportedTetherToken vault
	access(contract)
	let token2Vault: @TeleportedTetherToken.Vault
	
	// Controls FspLpToken vault
	access(contract)
	let fspLpTokenVault: @FlowSwapPair.Vault
	
	// Event that is emitted when a swap happens
	// Side 1: from token1 to token2
	// Side 2: from token2 to token1
	access(all)
	event Trade(token1Amount: UFix64, token2Amount: UFix64, side: UInt8)
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun freeze(){ 
			TokenPool.isFrozen = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unfreeze(){ 
			TokenPool.isFrozen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addLiquidity(from: @FlowSwapPair.TokenBundle){ 
			let token1Vault <- from.withdrawToken1()
			let token2Vault <- from.withdrawToken2()
			if token1Vault.balance > 0.0{ 
				TokenPool.token1Vault.deposit(from: <-token1Vault)
			} else{ 
				destroy token1Vault
			}
			if token2Vault.balance > 0.0{ 
				TokenPool.token2Vault.deposit(from: <-token2Vault)
			} else{ 
				destroy token2Vault
			}
			destroy from
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeLiquidity(amountToken1: UFix64, amountToken2: UFix64): @FlowSwapPair.TokenBundle{ 
			let token1Vault <-
				TokenPool.token1Vault.withdraw(amount: amountToken1) as! @FlowToken.Vault
			let token2Vault <-
				TokenPool.token2Vault.withdraw(amount: amountToken2)
				as!
				@TeleportedTetherToken.Vault
			let tokenBundle <-
				FlowSwapPair.createTokenBundle(fromToken1: <-token1Vault, fromToken2: <-token2Vault)
			return <-tokenBundle
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawFspLpTokens(amount: UFix64): @FlowSwapPair.Vault{ 
			let tokenVault <-
				TokenPool.fspLpTokenVault.withdraw(amount: amount) as! @FlowSwapPair.Vault
			return <-tokenVault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateVirtualAmounts(amountToken1: UFix64, amountToken2: UFix64){ 
			TokenPool.virtualToken1Amount = amountToken1
			TokenPool.virtualToken2Amount = amountToken2
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBuyBackPrice(price: UFix64){ 
			TokenPool.buyBackPrice = price
		}
	}
	
	access(all)
	struct PoolAmounts{ 
		access(all)
		let token1Amount: UFix64
		
		access(all)
		let token2Amount: UFix64
		
		access(all)
		let fspLpTokenAmount: UFix64
		
		init(token1Amount: UFix64, token2Amount: UFix64, fspLpTokenAmount: UFix64){ 
			self.token1Amount = token1Amount
			self.token2Amount = token2Amount
			self.fspLpTokenAmount = fspLpTokenAmount
		}
	}
	
	// Check current pool amounts (virtual pool)
	access(TMP_ENTITLEMENT_OWNER)
	fun getVirtualPoolAmounts(): FlowSwapPair.PoolAmounts{ 
		return FlowSwapPair.PoolAmounts(
			token1Amount: TokenPool.virtualToken1Amount,
			token2Amount: TokenPool.virtualToken2Amount
		)
	}
	
	// Check current pool amounts
	access(TMP_ENTITLEMENT_OWNER)
	fun getActualPoolAmounts(): PoolAmounts{ 
		return PoolAmounts(
			token1Amount: TokenPool.token1Vault.balance,
			token2Amount: TokenPool.token2Vault.balance,
			fspLpTokenAmount: TokenPool.fspLpTokenVault.balance
		)
	}
	
	// Precise division to mitigate fixed-point division error
	access(TMP_ENTITLEMENT_OWNER)
	fun preciseDiv(numerator: UFix64, denominator: UFix64): UFix64{ 
		return numerator / (denominator / self.shifter) / self.shifter
	}
	
	// Get quote for Token1 (given) -> Token2
	access(TMP_ENTITLEMENT_OWNER)
	fun quoteSwapExactToken1ForToken2(amount: UFix64): UFix64{ 
		let quote = amount * self.buyBackPrice
		assert(self.token2Vault.balance > quote, message: "Not enough Token2 in the pool")
		return quote
	}
	
	// Get quote for Token1 -> Token2 (given)
	access(TMP_ENTITLEMENT_OWNER)
	fun quoteSwapToken1ForExactToken2(amount: UFix64): UFix64{ 
		assert(self.token2Vault.balance > amount, message: "Not enough Token2 in the pool")
		return self.preciseDiv(numerator: amount, denominator: self.buyBackPrice)
	}
	
	// Get quote for Token2 (given) -> Token1
	access(TMP_ENTITLEMENT_OWNER)
	fun quoteSwapExactToken2ForToken1(amount: UFix64): UFix64{ 
		let poolAmounts = self.getVirtualPoolAmounts()
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + amount) * (token1Amount - quote)
		let quote =
			self.preciseDiv(
				numerator: poolAmounts.token1Amount * amount,
				denominator: poolAmounts.token2Amount + amount
			)
		return self.token1Vault.balance > quote ? quote : self.token1Vault.balance
	}
	
	// Get quote for Token2 -> Token1 (given)
	access(TMP_ENTITLEMENT_OWNER)
	fun quoteSwapToken2ForExactToken1(amount: UFix64): UFix64{ 
		let poolAmounts = self.getVirtualPoolAmounts()
		if poolAmounts.token1Amount <= amount || self.token1Vault.balance < amount{ 
			// Not enough Token1 in the pool, return UFix64 MAX
			return self.UFIX64_MAX
		}
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + quote) * (token1Amount - amount)
		let quote =
			self.preciseDiv(
				numerator: poolAmounts.token2Amount * amount,
				denominator: poolAmounts.token1Amount - amount
			)
		return quote
	}
	
	// Swaps Token1 (FLOW) -> Token2 (tUSDT)
	access(TMP_ENTITLEMENT_OWNER)
	fun swapToken1ForToken2(from: @FlowToken.Vault): @TeleportedTetherToken.Vault{ 
		pre{ 
			!TokenPool.isFrozen:
				"TokenPool is frozen"
			from.balance > UFix64(0):
				"Empty token vault"
		}
		
		// Calculate amount from pricing curve
		// A fee portion is taken from the final amount
		let token1Amount = from.balance
		let token2Amount = self.quoteSwapExactToken1ForToken2(amount: token1Amount)
		assert(token2Amount > UFix64(0), message: "Exchanged amount too small")
		self.token1Vault.deposit(from: <-(from as!{ FungibleToken.Vault}))
		emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 1)
		return <-(self.token2Vault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault)
	}
	
	// Swap Token2 (tUSDT) -> Token1 (FLOW)
	access(TMP_ENTITLEMENT_OWNER)
	fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FlowToken.Vault{ 
		pre{ 
			!TokenPool.isFrozen:
				"TokenPool is frozen"
			from.balance > UFix64(0):
				"Empty token vault"
		}
		
		// Calculate amount from pricing curve
		// A fee portion is taken from the final amount
		let token2Amount = from.balance
		let token1Amount = self.quoteSwapExactToken2ForToken1(amount: token2Amount)
		assert(token1Amount > UFix64(0), message: "Exchanged amount too small")
		
		// Add to Swap liquidity pool
		let fspPoolAmounts = FlowSwapPair.getPoolAmounts()
		let token1LiquidityAmount =
			self.preciseDiv(
				numerator: fspPoolAmounts.token1Amount * token2Amount,
				denominator: fspPoolAmounts.token2Amount
			)
		if token1LiquidityAmount + token1Amount < self.token1Vault.balance{ 
			let token1Vault <- self.token1Vault.withdraw(amount: token1LiquidityAmount) as! @FlowToken.Vault
			let tokenBundle <- FlowSwapPair.createTokenBundle(fromToken1: <-token1Vault, fromToken2: <-from)
			let fspLpTokenVault <- FlowSwapPair.addLiquidity(from: <-tokenBundle)
			self.fspLpTokenVault.deposit(from: <-(fspLpTokenVault as!{ FungibleToken.Vault}))
		} else{ 
			self.token2Vault.deposit(from: <-(from as!{ FungibleToken.Vault}))
		}
		
		// Update virtual pool
		self.virtualToken2Amount = self.virtualToken2Amount + token2Amount
		self.virtualToken1Amount = self.virtualToken1Amount - token1Amount
		emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 2)
		return <-(self.token1Vault.withdraw(amount: token1Amount) as! @FlowToken.Vault)
	}
	
	init(){ 
		self.isFrozen = true // frozen until admin unfreezes
		
		self.virtualToken1Amount = 100000.0
		self.virtualToken2Amount = 38000.0
		self.buyBackPrice = 0.001
		self.shifter = 10000.0
		self.UFIX64_MAX = 184467440737.09551615
		
		// Setup internal FlowToken vault
		self.token1Vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			as!
			@FlowToken.Vault
		
		// Setup internal TeleportedTetherToken vault
		self.token2Vault <- TeleportedTetherToken.createEmptyVault(
				vaultType: Type<@TeleportedTetherToken.Vault>()
			)
			as!
			@TeleportedTetherToken.Vault
		
		// Setup internal liquidity token vault
		self.fspLpTokenVault <- FlowSwapPair.createEmptyVault(
				vaultType: Type<@FlowSwapPair.Vault>()
			)
			as!
			@FlowSwapPair.Vault
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: /storage/tokenPoolAdmin)
	}
}
