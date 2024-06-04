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
contract LogOnLogOff{ 
	
	// Declare a public field of type String.
	//
	// All fields must be initialized in the init() function.
	access(all)
	enum LogType: UInt8{ 
		access(all)
		case logOff
		
		access(all)
		case logOn
	}
	
	access(self)
	var email: String
	
	access(self)
	var name: String
	
	access(self)
	var surName: String
	
	access(self)
	var logType: LogType
	
	access(self)
	var transactionTime: String
	
	access(self)
	var transactionTimeNumber: UInt256
	
	// The init() function is required if the contract contains any fields.
	init(){ 
		self.email = ""
		self.name = ""
		self.surName = ""
		self.logType = LogType.logOn
		self.transactionTime = ""
		self.transactionTimeNumber = 0
	}
	
	// Public function that returns our friendly greeting!
	access(self)
	fun getEmail(): String{ 
		return self.email
	}
	
	access(self)
	fun getName(): String{ 
		return self.name
	}
	
	access(self)
	fun getSurname(): String{ 
		return self.surName
	}
	
	access(all)
	fun set(
		email: String,
		name: String,
		surname: String,
		logtype: UInt8,
		transactionTime: String,
		transactionTimeNumber: UInt256
	){ 
		self.email = email
		self.name = name
		self.surName = surname
		var selectedLog = LogType.logOn
		if LogType.logOn.rawValue == logtype{ 
			selectedLog = LogType.logOn
		} else if LogType.logOff.rawValue == logtype{ 
			selectedLog = LogType.logOff
		}
		self.logType = selectedLog
		self.transactionTime = transactionTime
		self.transactionTimeNumber = transactionTimeNumber
	}
}
