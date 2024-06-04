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

	/**

# This contract stores some commonly used paths & library functions for PriceOracle

# Author Increment Labs

*/

access(all)
contract OracleConfig{ 
	// Admin resource stored in every PriceOracle contract
	access(all)
	let OracleAdminPath: StoragePath
	
	// Reader public interface exposed in every PriceOracle contract
	access(all)
	let OraclePublicInterface_ReaderPath: PublicPath
	
	// Feeder public interface exposed in every PriceOracle contract
	access(all)
	let OraclePublicInterface_FeederPath: PublicPath
	
	// Recommended storage path of reader's certificate
	access(all)
	let ReaderCertificateStoragePath: StoragePath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun sortUFix64List(list: [UFix64]): [UFix64]{ 
		let len = list.length
		var preIndex = 0
		var current = 0.0
		var i = 1
		while i < len{ 
			preIndex = i - 1
			current = list[i]
			while preIndex >= 0 && list[preIndex] > current{ 
				list[preIndex + 1] = list[preIndex]
				preIndex = preIndex - 1
			}
			list[preIndex + 1] = current
			i = i + 1
		}
		return list
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun sortUInt64List(list: [UInt64]): [UInt64]{ 
		let len = list.length
		var preIndex = 0
		var current: UInt64 = 0
		var i = 1
		while i < len{ 
			preIndex = i - 1
			current = list[i]
			while preIndex >= 0 && list[preIndex] > current{ 
				list[preIndex + 1] = list[preIndex]
				preIndex = preIndex - 1
			}
			list[preIndex + 1] = current
			i = i + 1
		}
		return list
	}
	
	init(){ 
		self.OracleAdminPath = /storage/increment_oracle_admin
		self.OraclePublicInterface_ReaderPath = /public/increment_oracle_reader_public
		self.OraclePublicInterface_FeederPath = /public/increment_oracle_feeder_public
		self.ReaderCertificateStoragePath = /storage/increment_oracle_reader_certificate
	}
}
