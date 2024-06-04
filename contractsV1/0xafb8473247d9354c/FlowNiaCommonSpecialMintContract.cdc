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
contract FlowNiaCommonSpecialMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var whitelist:{ Address: Bool}
	
	access(all)
	var extraFields:{ String: AnyStruct}
	
	init(){ 
		self.whitelist ={} 
		self.extraFields ={} 
		self.AdminStoragePath = /storage/FlowNiaCommonSpecialMintContractAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setFields(fields:{ String: AnyStruct}){ 
			for key in fields.keys{ 
				if key == "whitelist"{ 
					FlowNiaCommonSpecialMintContract.whitelist = fields[key] as!{ Address: Bool}? ??{} 
				} else if key == "whitelistToAdd"{ 
					let whitelistToAdd = fields[key] as!{ Address: Bool}? ??{} 
					for k in whitelistToAdd.keys{ 
						FlowNiaCommonSpecialMintContract.whitelist[k] = whitelistToAdd[k]!
					}
				} else{ 
					FlowNiaCommonSpecialMintContract.extraFields[key] = fields[key]
				}
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun preMint(_ signer: AuthAccount, tokenIDs: [UInt64]){ 
		let bl = signer.borrow<&{NonFungibleToken.Provider}>(from: FlowNia.CollectionStoragePath)
		if tokenIDs.length != 6{ 
			panic("should input exactly 6 tokens")
		}
		for id in tokenIDs{ 
			if id >= 3000 && id <= 9999{ 
				let token <- (bl!).withdraw(withdrawID: id)
				destroy token
			} else{ 
				panic("should input tokens 3000~9999")
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun paymentMint(
		_ signer: AuthAccount,
		tokenIDs: [
			UInt64
		],
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		var opened = self.extraFields["opened"] as! Bool? ?? false
		var startTime = self.extraFields["startTime"] as! UFix64?
		var endTime = self.extraFields["endTime"] as! UFix64?
		var currentTokenId = UInt64(self.extraFields["currentTokenId"] as! Number? ?? 0)
		var maxTokenId = UInt64(self.extraFields["maxTokenId"] as! Number? ?? 0)
		if !opened{ 
			panic("sale closed")
		}
		if !(startTime == nil || startTime! <= getCurrentBlock().timestamp){ 
			panic("sale not started yet")
		}
		if !(endTime == nil || endTime! > getCurrentBlock().timestamp){ 
			panic("sale already ended")
		}
		if !(currentTokenId <= maxTokenId){ 
			panic("all minted")
		}
		self.preMint(signer, tokenIDs: tokenIDs)
		let minter =
			self.account.storage.borrow<&FlowNia.NFTMinter>(from: FlowNia.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		if currentTokenId == 0{ 
			currentTokenId = FlowNia.totalSupply
		}
		
		// metadata code here
		minter.mintNFT(id: currentTokenId, recipient: recipient, metadata: metadata)
		self.extraFields["currentTokenId"] = currentTokenId + 1
	}
}
