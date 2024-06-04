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

	import Ashes from "./Ashes.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all)
contract AshesMessageBoard{ 
	access(all)
	event messagePosted(boardID: UInt64, ashSerial: UInt64, payload: String, encoding: String)
	
	access(all)
	resource interface PublicMessageBoard{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getMessages(ashSerials: [UInt64]):{ UInt64: AshesMessageBoard.Message}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getConfig(): BoardConfig
		
		access(TMP_ENTITLEMENT_OWNER)
		fun publishMesasge(ash: @Ashes.Ash, payload: String, encoding: String): @Ashes.Ash
	}
	
	access(all)
	struct Message{ 
		access(all)
		var ashSerial: UInt64?
		
		access(all)
		var momentID: UInt64?
		
		access(all)
		var momentData: TopShot.MomentData?
		
		access(all)
		var payload: String?
		
		access(all)
		var encoding: String?
		
		access(all)
		var paused: Bool
		
		access(all)
		var sizeLimit: UInt32
		
		access(all)
		var pristine: Bool
		
		access(all)
		var meta:{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkCanPost(payload: String, encoding: String){ 
			// message exists
			if self.paused{ 
				panic("message paused")
			}
			if !self.pristine{ 
				panic("message not pristine")
			}
			if payload.length + encoding.length > Int(self.sizeLimit){ 
				panic("message size too big")
			}
		}
		
		init(sizeLimit: UInt32){ 
			self.sizeLimit = sizeLimit
			self.paused = false
			self.pristine = true
			self.ashSerial = nil
			self.payload = nil
			self.encoding = nil
			self.momentData = nil
			self.momentID = nil
			self.meta ={} 
		}
	}
	
	access(all)
	struct BoardConfig{ 
		access(all)
		var defaultMessageSizeLimit: UInt32
		
		access(all)
		var canPostMessage: Bool
		
		init(defaultMessageSizeLimit: UInt32){ 
			self.defaultMessageSizeLimit = defaultMessageSizeLimit
			self.canPostMessage = false
		}
	}
	
	access(all)
	resource Board: PublicMessageBoard{ 
		access(self)
		var messages:{ UInt64: Message}
		
		access(self)
		var conf: BoardConfig
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMessages(ashSerials: [UInt64]):{ UInt64: Message}{ 
			let res:{ UInt64: Message} ={} 
			for ashSerial in ashSerials{ 
				res[ashSerial] = self.messages[ashSerial]!
			}
			return res
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getConfig(): BoardConfig{ 
			return self.conf
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setConfig(conf: BoardConfig){ 
			self.conf = conf
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun publishMesasge(ash: @Ashes.Ash, payload: String, encoding: String): @Ashes.Ash{ 
			let ashSerial = ash.ashSerial
			let message = self.getOrCreateMessage(ashSerial: ashSerial)
			if !self.conf.canPostMessage{ 
				panic("posting is closed")
			}
			message.checkCanPost(payload: payload, encoding: encoding)
			message.payload = payload
			message.encoding = encoding
			message.ashSerial = ashSerial
			message.momentID = ash.id
			message.momentData = ash.momentData
			message.pristine = false
			self.messages[ashSerial] = message
			emit messagePosted(boardID: self.uuid, ashSerial: ashSerial, payload: payload, encoding: encoding)
			return <-ash
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMessage(ashSerial: UInt64, message: Message){ 
			self.messages[ashSerial] = message
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOrCreateMessage(ashSerial: UInt64): Message{ 
			var message = self.messages[ashSerial]
			if message == nil{ 
				message = Message(sizeLimit: self.conf.defaultMessageSizeLimit)
			}
			return message!
		}
		
		init(){ 
			self.messages ={} 
			self.conf = BoardConfig(defaultMessageSizeLimit: 120)
		}
	}
	
	init(){ 
		self.account.storage.save<@Board>(<-create Board(), to: /storage/MessageBoard1)
		var capability_1 =
			self.account.capabilities.storage.issue<&{PublicMessageBoard}>(/storage/MessageBoard1)
		self.account.capabilities.publish(capability_1, at: /public/MessageBoard1)
	}
}
