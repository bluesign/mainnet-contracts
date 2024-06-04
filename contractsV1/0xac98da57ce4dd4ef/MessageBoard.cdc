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
contract MessageBoard{ 
	// The path to the Admin object in this contract's storage
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	struct Post{ 
		access(all)
		let timestamp: UFix64
		
		access(all)
		let message: String
		
		access(all)
		let from: Address
		
		init(timestamp: UFix64, message: String, from: Address){ 
			self.timestamp = timestamp
			self.message = message
			self.from = from
		}
	}
	
	// Records 100 latest messages
	access(all)
	var posts: [Post]
	
	// Emitted when a post is made
	access(all)
	event Posted(timestamp: UFix64, message: String, from: Address)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun _post(message: String, from: Address){ 
		pre{ 
			message.length <= 140:
				"Message too long"
		}
		let _post = Post(timestamp: getCurrentBlock().timestamp, message: message, from: from)
		self.posts.append(_post)
		
		// Keeps only the latest 100 messages
		if self.posts.length > 100{ 
			self.posts.removeFirst()
		}
		emit Posted(timestamp: getCurrentBlock().timestamp, message: message, from: from)
	}
	
	// Check current messages
	access(TMP_ENTITLEMENT_OWNER)
	fun getPosts(): [Post]{ 
		return self.posts
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deletePost(index: UInt64){ 
			MessageBoard.posts.remove(at: index)
		}
	}
	
	init(){ 
		self.adminStoragePath = /storage/admin
		self.posts = []
		self.account.storage.save(<-create Admin(), to: self.adminStoragePath)
	}
}
