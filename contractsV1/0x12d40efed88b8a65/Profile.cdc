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

	//Wow! You are viewing LimitlessCube Profile contract.
access(all)
contract Profile{ 
	access(all)
	let ProfilePublicPath: PublicPath
	
	access(all)
	let ProfileStoragePath: StoragePath
	
	//Profile created event
	access(all)
	event ProfileCreated(
		accountAddress: Address,
		displayName: String,
		username: String,
		description: String,
		avatar: String,
		coverPhoto: String,
		email: String,
		links:{ 
			String: String
		}
	)
	
	access(all)
	struct UserProfile{ 
		access(all)
		let address: Address
		
		access(all)
		let displayName: String
		
		access(all)
		let username: String
		
		access(all)
		let description: String
		
		access(all)
		let email: String
		
		access(all)
		let avatar: String
		
		access(all)
		let coverPhoto: String
		
		access(all)
		let links:{ String: String}
		
		init(
			address: Address,
			displayName: String,
			username: String,
			description: String,
			email: String,
			avatar: String,
			coverPhoto: String,
			links:{ 
				String: String
			}
		){ 
			self.address = address
			self.displayName = displayName
			self.username = username
			self.description = description
			self.email = email
			self.avatar = avatar
			self.coverPhoto = coverPhoto
			self.links = links
		}
	}
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplayName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAvatar(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCoverPhoto(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLinks():{ String: String}
		
		//TODO: create another method to deposit with message
		access(TMP_ENTITLEMENT_OWNER)
		fun asProfile(): UserProfile
	}
	
	access(all)
	resource interface Owner{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setDisplayName(_ val: String): Void{ 
			pre{ 
				val.length <= 100:
					"displayName must be 100 or less characters"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUsername(_ val: String){ 
			pre{ 
				val.length <= 16:
					"username must be 16 or less characters"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Description must be 255 characters or less"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setEmail(_ val: String){ 
			pre{ 
				val.length <= 100:
					"Email must be 100 characters or less"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAvatar(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Avatar must be 255 characters or less"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCoverPhoto(_ val: String){ 
			pre{ 
				val.length <= 255:
					"CoverPhoto must be 255 characters or less"
			}
		}
	}
	
	access(all)
	resource User: Public, Owner{ 
		access(self)
		var displayName: String
		
		access(self)
		var username: String
		
		access(self)
		var description: String
		
		access(self)
		var email: String
		
		access(self)
		var avatar: String
		
		access(self)
		var coverPhoto: String
		
		access(self)
		var links:{ String: String}
		
		init(displayName: String, username: String, description: String, email: String, links:{ String: String}){ 
			self.displayName = displayName
			self.username = username
			self.description = description
			self.email = email
			self.avatar = "https://avatars.onflow.org/avatar/ghostnote"
			self.coverPhoto = "https://avatars.onflow.org/avatar/ghostnote"
			self.links = links
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun asProfile(): UserProfile{ 
			return UserProfile(address: (self.owner!).address, displayName: self.getDisplayName(), username: self.getUsername(), description: self.getDescription(), email: self.getEmail(), avatar: self.getAvatar(), coverPhoto: self.getCoverPhoto(), links: self.getLinks())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplayName(): String{ 
			return self.displayName
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUsername(): String{ 
			return self.username
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEmail(): String{ 
			return self.email
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAvatar(): String{ 
			return self.avatar
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCoverPhoto(): String{ 
			return self.coverPhoto
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLinks():{ String: String}{ 
			return self.links
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDisplayName(_ val: String){ 
			self.displayName = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setUsername(_ val: String){ 
			self.displayName = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAvatar(_ val: String){ 
			self.avatar = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCoverPhoto(_ val: String){ 
			self.coverPhoto = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ val: String){ 
			self.description = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setEmail(_ val: String){ 
			self.email = val
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setLinks(_ val:{ String: String}){ 
			self.links = val
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun find(_ address: Address): &{Profile.Public}{ 
		return getAccount(address).capabilities.get<&{Profile.Public}>(Profile.ProfilePublicPath)
			.borrow()!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createUser(
		accountAddress: Address,
		displayName: String,
		username: String,
		description: String,
		avatar: String,
		coverPhoto: String,
		email: String,
		links:{ 
			String: String
		}
	): @Profile.User{ 
		pre{ 
			displayName.length <= 100:
				"displayName must be 100 or less characters"
			username.length <= 16:
				"username must be 16 or less characters"
			description.length <= 255:
				"Descriptions must be 255 or less characters"
			email.length <= 100:
				"Descriptions must be 100 or less characters"
			avatar.length <= 255:
				"Descriptions must be 255 or less characters"
			coverPhoto.length <= 255:
				"Descriptions must be 255 or less characters"
		}
		let profile <-
			create Profile.User(
				displayName: displayName,
				username: username,
				description: description,
				email: email,
				links: links
			)
		emit ProfileCreated(
			accountAddress: accountAddress,
			displayName: displayName,
			username: username,
			description: description,
			avatar: avatar,
			coverPhoto: coverPhoto,
			email: email,
			links: links
		)
		return <-profile
	}
	
	init(){ 
		self.ProfilePublicPath = /public/LCubeUserProfile
		self.ProfileStoragePath = /storage/LCubeUserProfile
	}
}
