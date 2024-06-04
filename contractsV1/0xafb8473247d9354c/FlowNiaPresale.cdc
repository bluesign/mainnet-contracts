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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowNia from "./FlowNia.cdc"

access(all)
contract FlowNiaPresale{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale?
	
	access(all)
	struct Sale{ 
		access(all)
		var price: UFix64
		
		access(all)
		var paymentVaultType: Type
		
		access(all)
		var receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		var startTime: UFix64?
		
		access(all)
		var endTime: UFix64?
		
		access(all)
		var max: UInt64
		
		access(all)
		var current: UInt64
		
		init(
			price: UFix64,
			paymentVaultType: Type,
			receiver: Capability<&{FungibleToken.Receiver}>,
			startTime: UFix64?,
			endTime: UFix64?,
			max: UInt64,
			current: UInt64
		){ 
			self.price = price
			self.paymentVaultType = paymentVaultType
			self.receiver = receiver
			self.startTime = startTime
			self.endTime = endTime
			self.max = max
			self.current = current
		}
		
		access(contract)
		fun incCurrent(){ 
			self.current = self.current + UInt64(1)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun paymentMint(
		payment: @{FungibleToken.Vault},
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			self.sale != nil:
				"sale closed"
			(self.sale!).startTime == nil || (self.sale!).startTime! <= getCurrentBlock().timestamp:
				"sale not started yet"
			(self.sale!).endTime == nil || (self.sale!).endTime! > getCurrentBlock().timestamp:
				"sale already ended"
			(self.sale!).max > (self.sale!).current:
				"sale items sold out"
			(self.sale!).receiver.check():
				"invalid receiver"
			payment.isInstance((self.sale!).paymentVaultType):
				"payment vault is not requested fungible token"
			payment.balance == (self.sale!).price!:
				"payment vault does not contain requested price"
		}
		let receiver = (self.sale!).receiver.borrow()!
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&FlowNia.NFTMinter>(from: FlowNia.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		let tokenId = FlowNia.totalSupply
		// metadata code here
		minter.mintNFT(id: recipient, recipient: metadata)
		(self.sale!).incCurrent()
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setSale(sale: Sale?){ 
			FlowNiaPresale.sale = sale
		}
	}
	
	init(){ 
		self.sale = nil
		self.AdminStoragePath = /storage/FlowNiaPresaleAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
