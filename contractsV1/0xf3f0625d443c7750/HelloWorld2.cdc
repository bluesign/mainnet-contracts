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

	// HelloWorldResource.cdc
//
// This is a variation of the HelloWorld contract that introduces the concept of
// resources, a new form of linear type that is unique to Cadence. Resources can be
// used to create a secure model of digital ownership.
//
// Learn more about resources in this tutorial: https://docs.onflow.org/docs/hello-world
access(all)
contract HelloWorld2{ 
	// Declare a resource that only includes one function.
	access(all)
	resource HelloAsset{ 
		// A transaction can call this function to get the "Hello, World!"
		// message from the resource.
		access(TMP_ENTITLEMENT_OWNER)
		fun hello(): String{ 
			return "Hello, World!"
		}
	}
	
	init(){ 
		// Use the create built-in function to create a new instance
		// of the HelloAsset resource
		let newHello <- create HelloAsset()
		// We can do anything in the init function, including accessing
		// the storage of the account that this contract is deployed to.
		//
		// Here we are storing the newly created HelloAsset resource
		// in the private account storage 
		// by specifying a custom path to the resource
		// make sure the path is specific!
		self.account.storage.save(<-newHello, to: /storage/HelloAssetTutorial)
		log("HelloAsset created and stored")
	}
}
