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
contract FlowContractAudits{ 
	
	// Event that is emitted when a new Auditor resource is created
	access(all)
	event AuditorCreated()
	
	// Event that is emitted when a new contract audit voucher is created
	access(all)
	event VoucherCreated(
		address: Address?,
		recurrent: Bool,
		expiryBlockHeight: UInt64?,
		codeHash: String
	)
	
	// Event that is emitted when a contract audit voucher is used
	access(all)
	event VoucherUsed(address: Address, key: String, recurrent: Bool, expiryBlockHeight: UInt64?)
	
	// Event that is emitted when a contract audit voucher is removed
	access(all)
	event VoucherRemoved(key: String, recurrent: Bool, expiryBlockHeight: UInt64?)
	
	// Dictionary of all vouchers
	access(contract)
	var vouchers:{ String: AuditVoucher}
	
	// The storage path for the admin resource
	access(all)
	let AdminStoragePath: StoragePath
	
	// The storage Path for auditors' AuditorProxy
	access(all)
	let AuditorProxyStoragePath: StoragePath
	
	// The public path for auditors' AuditorProxy capability
	access(all)
	let AuditorProxyPublicPath: PublicPath
	
	// Single audit voucher that is used for contract deployment
	access(all)
	struct AuditVoucher{ 
		
		// Address of the account the voucher is intended for
		// If nil, the contract can be deployed to any account
		access(all)
		let address: Address?
		
		// If false, the voucher will be removed after first use
		access(all)
		let recurrent: Bool
		
		// If non-nil, the voucher won't be valid after the expiry block height
		access(all)
		let expiryBlockHeight: UInt64?
		
		// Hash of contract code
		access(all)
		let codeHash: String
		
		init(address: Address?, recurrent: Bool, expiryBlockHeight: UInt64?, codeHash: String){ 
			self.address = address
			self.recurrent = recurrent
			self.expiryBlockHeight = expiryBlockHeight
			self.codeHash = codeHash
		}
	}
	
	// Returns all current vouchers
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllVouchers():{ String: AuditVoucher}{ 
		return self.vouchers
	}
	
	// Get the associated dictionary key for given address and codeHash
	access(TMP_ENTITLEMENT_OWNER)
	fun generateVoucherKey(address: Address?, codeHash: String): String{ 
		if address != nil{ 
			return (address!).toString().concat("-").concat(codeHash)
		}
		return "any-".concat(codeHash)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hashContractCode(_ code: String): String{ 
		return String.encodeHex(HashAlgorithm.SHA3_256.hash(code.utf8))
	}
	
	// Auditors can create new vouchers and remove them
	access(all)
	resource Auditor{ 
		
		// Create new voucher with contract code
		access(TMP_ENTITLEMENT_OWNER)
		fun addVoucher(address: Address?, recurrent: Bool, expiryOffset: UInt64?, code: String){ 
			let codeHash = FlowContractAudits.hashContractCode(code)
			self.addVoucherHashed(
				address: address,
				recurrent: recurrent,
				expiryOffset: expiryOffset,
				codeHash: codeHash
			)
		}
		
		// Create new voucher with hashed contract code
		access(TMP_ENTITLEMENT_OWNER)
		fun addVoucherHashed(
			address: Address?,
			recurrent: Bool,
			expiryOffset: UInt64?,
			codeHash: String
		){ 
			
			// calculate expiry block height based on expiryOffset
			var expiryBlockHeight: UInt64? = nil
			if expiryOffset != nil{ 
				expiryBlockHeight = getCurrentBlock().height + expiryOffset!
			}
			let key = FlowContractAudits.generateVoucherKey(address: address, codeHash: codeHash)
			
			// if a voucher with the same key exists, remove it first
			FlowContractAudits.deleteVoucher(key)
			let voucher =
				AuditVoucher(
					address: address,
					recurrent: recurrent,
					expiryBlockHeight: expiryBlockHeight,
					codeHash: codeHash
				)
			FlowContractAudits.vouchers.insert(key: key, voucher)
			emit VoucherCreated(
				address: address,
				recurrent: recurrent,
				expiryBlockHeight: expiryBlockHeight,
				codeHash: codeHash
			)
		}
		
		// Remove a voucher with given key
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteVoucher(key: String){ 
			FlowContractAudits.deleteVoucher(key)
		}
	}
	
	// Used by admin to set the Auditor capability
	access(all)
	resource interface AuditorProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setAuditorCapability(_ cap: Capability<&FlowContractAudits.Auditor>): Void
	}
	
	// The auditor account will have audit access through AuditorProxy
	// This enables the admin account to revoke access
	// See https://docs.onflow.org/cadence/design-patterns/#capability-revocation
	access(all)
	resource AuditorProxy: AuditorProxyPublic{ 
		access(self)
		var auditorCapability: Capability<&Auditor>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAuditorCapability(_ cap: Capability<&Auditor>){ 
			self.auditorCapability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addVoucher(address: Address?, recurrent: Bool, expiryOffset: UInt64?, code: String){ 
			((self.auditorCapability!).borrow()!).addVoucher(address: address, recurrent: recurrent, expiryOffset: expiryOffset, code: code)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addVoucherHashed(address: Address?, recurrent: Bool, expiryOffset: UInt64?, codeHash: String){ 
			((self.auditorCapability!).borrow()!).addVoucherHashed(address: address, recurrent: recurrent, expiryOffset: expiryOffset, codeHash: codeHash)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteVoucher(key: String){ 
			((self.auditorCapability!).borrow()!).deleteVoucher(key: key)
		}
		
		init(){ 
			self.auditorCapability = nil
		}
	}
	
	// Can be called by anyone but needs a capability to function
	access(TMP_ENTITLEMENT_OWNER)
	fun createAuditorProxy(): @AuditorProxy{ 
		return <-create AuditorProxy()
	}
	
	access(all)
	resource Administrator{ 
		
		// Creates new Auditor
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAuditor(): @Auditor{ 
			emit AuditorCreated()
			return <-create Auditor()
		}
		
		// Checks all vouchers and removes expired ones
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanupExpiredVouchers(){ 
			for key in FlowContractAudits.vouchers.keys{ 
				let v = FlowContractAudits.vouchers[key]!
				if v.expiryBlockHeight != nil{ 
					if getCurrentBlock().height > v.expiryBlockHeight!{ 
						FlowContractAudits.deleteVoucher(key)
					}
				}
			}
		}
		
		// For testing
		access(TMP_ENTITLEMENT_OWNER)
		fun useVoucherForDeploy(address: Address, code: String): Bool{ 
			return FlowContractAudits.useVoucherForDeploy(address: address, code: code)
		}
	}
	
	// This function will be called by the FVM on contract deploy/update
	access(contract)
	fun useVoucherForDeploy(address: Address, code: String): Bool{ 
		let codeHash = FlowContractAudits.hashContractCode(code)
		var key = FlowContractAudits.generateVoucherKey(address: address, codeHash: codeHash)
		
		// first check for voucher based on target account
		// if not found check for any account
		if !FlowContractAudits.vouchers.containsKey(key){ 
			key = FlowContractAudits.generateVoucherKey(address: nil, codeHash: codeHash)
			if !FlowContractAudits.vouchers.containsKey(key){ 
				return false
			}
		}
		let v = FlowContractAudits.vouchers[key]!
		
		// ensure contract code matches the voucher
		if v.codeHash != codeHash{ 
			return false
		}
		
		// if expiryBlockHeight is set, check the current block height
		// and remove/expire the voucher if not within the acceptable range
		if v.expiryBlockHeight != nil{ 
			if getCurrentBlock().height > v.expiryBlockHeight!{ 
				FlowContractAudits.deleteVoucher(key)
				return false
			}
		}
		
		// remove the voucher if not recurrent
		if !v.recurrent{ 
			FlowContractAudits.deleteVoucher(key)
		}
		emit VoucherUsed(
			address: address,
			key: key,
			recurrent: v.recurrent,
			expiryBlockHeight: v.expiryBlockHeight
		)
		return true
	}
	
	// Helper function to remove a voucher with given key
	access(contract)
	fun deleteVoucher(_ key: String){ 
		let v = FlowContractAudits.vouchers.remove(key: key)
		if v != nil{ 
			emit VoucherRemoved(key: key, recurrent: (v!).recurrent, expiryBlockHeight: (v!).expiryBlockHeight)
		}
	}
	
	init(){ 
		self.vouchers ={} 
		self.AdminStoragePath = /storage/flowContractAuditVouchersAdmin
		self.AuditorProxyStoragePath = /storage/flowContractAuditVouchersAuditorProxy
		self.AuditorProxyPublicPath = /public/flowContractAuditVouchersAuditorProxy
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
