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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc" //Mainnet address: 0x1d7e57aa55817448


import FungibleToken from "./../../standardsV1/FungibleToken.cdc" //Mainnet address: 0xf233dcee88fe0abe


import MetadataViews from "./../../standardsV1/MetadataViews.cdc" //Mainnet address: 0x1d7e57aa55817448


// TODO: change to your account which deploy ChainIDEShildNFT
import ChainIDEShieldNFT from "./ChainIDEShieldNFT.cdc"

access(all)
contract ChainIDEShieldNFTMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale
	
	access(all)
	struct Sale{ 
		access(all)
		var price: UFix64
		
		access(all)
		var receiver: Address
		
		init(price: UFix64, receiver: Address){ 
			self.price = price
			self.receiver = receiver
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun paymentMint(
		payment: @{FungibleToken.Vault},
		amount: Int,
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			amount <= 10:
				"amount should less equal than 10 in per mint"
			payment.balance == self.sale.price! * UFix64(amount):
				"payment vault does not contain requested price"
		}
		let receiver =
			getAccount(self.sale.receiver).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowTokenReceiver
			).borrow()
			?? panic("Could not get receiver reference to Flow Token")
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&ChainIDEShieldNFT.NFTMinter>(
				from: ChainIDEShieldNFT.MinterStoragePath
			)!
		var index = 0
		let types = ["bronze", "silver", "gold", "platinum"]
		while index < amount{ 
			minter.mintNFT(recipient: recipient, type: types[revertibleRandom<UInt64>() % 4])
			index = index + 1
		}
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setSale(price: UFix64, receiver: Address){ 
			ChainIDEShieldNFTMintContract.sale = Sale(price: price, receiver: receiver)
		}
	}
	
	init(price: UFix64, receiver: Address){ 
		self.sale = Sale(price: price, receiver: receiver)
		self.AdminStoragePath = /storage/ChainIDEShieldNFTMintAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
