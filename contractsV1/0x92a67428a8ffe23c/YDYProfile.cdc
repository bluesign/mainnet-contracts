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
contract YDYProfile{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserData():{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getWorkoutIDs(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getWorkoutData(id: String):{ String: String}
		
		access(contract)
		fun updateUserData(key: String, value: String)
		
		access(contract)
		fun addWorkoutData(workout:{ String: String})
		
		access(contract)
		fun updateWorkoutData(id: String, key: String, value: String)
	}
	
	access(all)
	resource User: Public{ 
		access(all)
		var userData:{ String: String}
		
		access(all)
		var workoutData:{ String:{ String: String}}
		
		init(){ 
			self.userData ={} 
			self.workoutData ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserData():{ String: String}{ 
			return self.userData
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getWorkoutIDs(): [String]{ 
			return self.workoutData.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getWorkoutData(id: String):{ String: String}{ 
			return self.workoutData[id] ?? panic("No workout with this ID exists for user")
		}
		
		access(contract)
		fun updateUserData(key: String, value: String){ 
			self.userData[key] = value
		}
		
		access(contract)
		fun addWorkoutData(workout:{ String: String}){ 
			var id = workout["session_id"] ?? panic("No session_id in workout data")
			self.workoutData[id] = workout
		}
		
		access(contract)
		fun updateWorkoutData(id: String, key: String, value: String){ 
			var workout = self.workoutData[id] ?? panic("No workout with this ID exists for user")
			workout[key] = value
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createUser(): @User{ 
		return <-create User()
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateDataOfUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			key: String,
			value: String
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.updateUserData(key: key, value: value)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addWorkoutDataToUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			data:{ 
				String: String
			}
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.addWorkoutData(workout: data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateWorkoutDataOfUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			id: String,
			key: String,
			value: String
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.updateWorkoutData(id: id, key: key, value: value)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun superFunction(receiverAddress: Address, nft_id: UInt64){} 
	}
	
	init(){ 
		self.publicPath = /public/YDYProfile
		self.storagePath = /storage/YDYProfile
		self.adminStoragePath = /storage/YDYAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.adminStoragePath)
	}
}
