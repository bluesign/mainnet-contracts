/**
> Author: FIXeS World <https://fixes.world/>

# FRC20TradingRecord

TODO: Add description

*/

import Fixes from "./Fixes.cdc"

import FRC20Indexer from "./FRC20Indexer.cdc"

import FRC20FTShared from "./FRC20FTShared.cdc"

pub contract FRC20TradingRecord{ 
    pub        /* --- Events --- */
        /// Event emitted when the contract is initialized
        event ContractInitialized()
    
    pub event              
              /// Event emitted when a record is created
              RecordCreated(
        recorder: Address,
        storefront: Address,
        buyer: Address,
        seller: Address,
        tick: String,
        dealAmount: UFix64,
        dealPrice: UFix64,
        dealPricePerMint: UFix64
    )
    
    /* --- Variable, Enums and Structs --- */    pub let TradingRecordsStoragePath: StoragePath
    
    pub let TradingRecordsPublicPath: PublicPath
    
    /* --- Interfaces & Resources --- *//// The struct containing the transaction record
    ///
    pub struct TransactionRecord{ 
        pub let storefront: Address
        
        pub let buyer: Address
        
        pub let seller: Address
        
        pub let tick: String
        
        pub let dealAmount: UFix64
        
        pub let dealPrice: UFix64
        
        pub let dealPricePerMint: UFix64
        
        pub let timestamp: UInt64
        
        init(
            storefront: Address,
            buyer: Address,
            seller: Address,
            tick: String,
            dealAmount: UFix64,
            dealPrice: UFix64,
            dealPricePerMint: UFix64
        ){ 
            self.storefront = storefront
            self.buyer = buyer
            self.seller = seller
            self.tick = tick
            self.dealAmount = dealAmount
            self.dealPrice = dealPrice
            self.dealPricePerMint = dealPricePerMint
            self.timestamp = UInt64(getCurrentBlock().timestamp)
        }
        
        pub fun getDealPricePerToken(): UFix64{ 
            return self.dealPrice / self.dealAmount
        }
    }
    
    /// The struct containing the trading status
    ///
    pub struct TradingStatus{ 
        pub var dealFloorPricePerToken: UFix64
        
        pub var dealFloorPricePerMint: UFix64
        
        pub var dealCeilingPricePerToken: UFix64
        
        pub var dealCeilingPricePerMint: UFix64
        
        pub var dealAmount: UFix64
        
        pub var volume: UFix64
        
        pub var sales: UInt64
        
        init(){ 
            self.dealFloorPricePerToken = 0.0
            self.dealFloorPricePerMint = 0.0
            self.dealCeilingPricePerToken = 0.0
            self.dealCeilingPricePerMint = 0.0
            self.dealAmount = 0.0
            self.volume = 0.0
            self.sales = 0
        }
        
        access(contract) fun updateByNewRecord(
            _ recordRef: &TransactionRecord
        ){ 
            // update the trading price
            let dealPricePerToken = recordRef.getDealPricePerToken()
            let dealPricePerMint = recordRef.dealPricePerMint
            
            // update the floor price per token
            if self.dealFloorPricePerToken == 0.0
            || dealPricePerToken < self.dealFloorPricePerToken{ 
                self.dealFloorPricePerToken = dealPricePerToken
            }
            // update the floor price per mint
            if self.dealFloorPricePerMint == 0.0
            || dealPricePerMint < self.dealFloorPricePerMint{ 
                self.dealFloorPricePerMint = dealPricePerMint
            }
            // update the ceiling price per token
            if dealPricePerToken > self.dealCeilingPricePerToken{ 
                self.dealCeilingPricePerToken = dealPricePerToken
            }
            // update the ceiling price per mint
            if dealPricePerMint > self.dealCeilingPricePerMint{ 
                self.dealCeilingPricePerMint = dealPricePerMint
            }
            // update the deal amount
            self.dealAmount = self.dealAmount + recordRef.dealAmount
            // update the volume
            self.volume = self.volume + recordRef.dealPrice
            // update the sales
            self.sales = self.sales + 1
        }
    }
    
    /// The interface for viewing the trading status
    ///
    pub resource interface TradingStatusViewer{ 
        pub fun getStatus(): TradingStatus{} 
    }
    
    /// The resource containing the trading status
    ///
    pub resource BasicRecord: TradingStatusViewer{ 
        pub let status: TradingStatus
        
        init(){ 
            self.status = TradingStatus()
        }
        
        pub fun getStatus(): TradingStatus{ 
            return self.status
        }
        
        access(contract) fun updateByNewRecord(_ recordRef: &TransactionRecord){ 
            self.status.updateByNewRecord(recordRef)
        }
    }
    
    /// The interface for viewing the daily records
    ///
    pub resource interface DailyRecordsPublic{ 
        pub            /// Get the length of the records
            fun getRecordLength(): UInt64{} 
        
        /// Get the records of the page
        pub fun getRecords(page: Int, pageSize: Int): [TransactionRecord]{} 
        
        /// Available minutes
        pub fun getMintesWithStatus(): [UInt64]{} 
        
        /// Get the trading status
        pub fun borrowMinutesStatus(_ time: UInt64): &BasicRecord{
            TradingStatusViewer
        }?{} 
        
        /// Get the buyer addresses
        pub fun getBuyerAddresses(): [Address]{} 
        
        /// Get the trading volume of the address
        pub fun getAddressBuyVolume(_ addr: Address): UFix64?{} 
        
        /// Get the seller addresses
        pub fun getSellerAddresses(): [Address]{} 
        
        /// Get the trading volume of the address
        pub fun getAddressSellVolume(_ addr: Address): UFix64?{} 
    }
    
    /// The resource containing the daily records
    //
    pub resource DailyRecords: DailyRecordsPublic, TradingStatusViewer{ 
        /// The date of the records, in seconds
        pub let date: UInt64
        
        /// The trading status of the day
        pub let status: TradingStatus
        
        /// Deal records, sorted by timestamp, descending
        access(contract) let records: [TransactionRecord]
        
        /// Minute => TradingStatus
        priv let minutes: @{UInt64: BasicRecord}
        
        // Address => TradingVolume
        priv let buyerVolumes:{ Address: UFix64}
        
        // Address => TradingVolume
        priv let sellerVolumes:{ Address: UFix64}
        
        init(date: UInt64){ 
            self.date = date
            self.status = TradingStatus()
            self.records = []
            self.minutes <-{} 
            self.buyerVolumes ={} 
            self.sellerVolumes ={} 
        }
        
        /// @deprecated after Cadence 1.0
        destroy(){ 
            destroy self.minutes
        }
        
        /** Public methods */        pub fun getRecordLength(): UInt64{ 
            return UInt64(self.records.length)
        }
        
        pub fun getRecords(page: Int, pageSize: Int): [TransactionRecord]{ 
            var start = page * pageSize
            if start < 0{ 
                start = 0
            } else if start > self.records.length{ 
                return []
            }
            var end = start + pageSize
            if end > self.records.length{ 
                end = self.records.length
            }
            return self.records.slice(from: start, upTo: end)
        }
        
        pub fun getStatus(): TradingStatus{ 
            return self.status
        }
        
        /// Available minutes
        ///
        pub fun getMintesWithStatus(): [UInt64]{ 
            return self.minutes.keys
        }
        
        /// Get the trading status
        ///
        pub fun borrowMinutesStatus(_ time: UInt64): &BasicRecord{TradingStatusViewer}?{ 
            let minuteTime = self.convertToMinute(time)
            return &self.minutes[minuteTime] as &BasicRecord{TradingStatusViewer}?
        }
        
        /// Get the buyer addresses
        pub fun getBuyerAddresses(): [Address]{ 
            return self.buyerVolumes.keys
        }
        
        /// Get the trading volume of the address
        pub fun getAddressBuyVolume(_ addr: Address): UFix64?{ 
            return self.buyerVolumes[addr]
        }
        
        /// Get the seller addresses
        pub fun getSellerAddresses(): [Address]{ 
            return self.sellerVolumes.keys
        }
        
        /// Get the trading volume of the address
        pub fun getAddressSellVolume(_ addr: Address): UFix64?{ 
            return self.sellerVolumes[addr]
        }
        
        /** Internal Methods */        access(contract) fun addRecord(record: TransactionRecord){ 
            // timestamp is in seconds, not milliseconds
            let timestamp = record.timestamp
            // ensure the timestamp is in the same day
            if timestamp / 86400 != self.date / 86400{ 
                return // DO NOT PANIC
            }
            let recorder = self.owner?.address
            if recorder == nil{ 
                return // DO NOT PANIC
            }
            let recordRef = &record as &TransactionRecord
            // update the trading status
            let statusRef = self.borrowStatus()
            statusRef.updateByNewRecord(recordRef)
            
            // update the minutes
            let minuteTime = self.convertToMinute(timestamp)
            var minuteRecordsRef = self.borrowMinute(minuteTime)
            if minuteRecordsRef == nil{ 
                self.minutes[minuteTime] <-! create BasicRecord()
                minuteRecordsRef = self.borrowMinute(minuteTime)
            }
            if minuteRecordsRef != nil{ 
                (minuteRecordsRef!).updateByNewRecord(recordRef)
            }
            
            // record detailed trading volume
            self.buyerVolumes[record.buyer] = (self.buyerVolumes[record.buyer] ?? 0.0) + record.dealPrice
            self.sellerVolumes[record.seller] = (self.sellerVolumes[record.seller] ?? 0.0) + record.dealPrice
            
            // add the record, sorted by timestamp, descending
            self.records.insert(at: 0, record)
            
            // emit the event
            emit RecordCreated(recorder: recorder!, storefront: record.storefront, buyer: record.buyer, seller: record.seller, tick: record.tick, dealAmount: record.dealAmount, dealPrice: record.dealPrice, dealPricePerMint: record.dealPricePerMint)
        }
        
        priv fun convertToMinute(_ time: UInt64): UInt64{ 
            return time - time % 60
        }
        
        priv fun borrowStatus(): &TradingStatus{ 
            return &self.status as &TradingStatus
        }
        
        priv fun borrowMinute(_ time: UInt64): &BasicRecord?{ 
            let minuteTime = self.convertToMinute(time)
            return &self.minutes[minuteTime] as &BasicRecord?
        }
    }
    
    pub resource interface TradingRecordsPublic{ 
        pub            // ---- Public Methods ----
            fun isSharedRecrds(): Bool{} 
        
        pub fun getTickerName(): String?{} 
        
        pub fun getMarketCap(): UFix64?{} 
        
        pub fun borrowDailyRecords(_ date: UInt64): &DailyRecords{
            DailyRecordsPublic,
            TradingStatusViewer
        }?{} 
        
        // ---- 2x Traders Points ----
        pub fun getTraders(): [Address]{} 
        
        pub fun getTradersPoints(_ addr: Address): UFix64{} 
        
        // ---- 10x Traders Points ----
        pub fun get10xTraders(): [Address]{} 
        
        pub fun get10xTradersPoints(_ addr: Address): UFix64{} 
        
        // ---- 100x Traders  Points ----
        pub fun get100xTraders(): [Address]{} 
        
        pub fun get100xTradersPoints(_ addr: Address): UFix64{} 
    }
    
    /// The resource containing the trading volume
    ///
    pub resource TradingRecords:
        TradingRecordsPublic,
        TradingStatusViewer,
        FRC20FTShared.TransactionHook{
    
        priv let tick: String?
        
        /// Trading status
        priv let status: TradingStatus
        
        /// Date => DailyRecords
        priv let dailyRecords: @{UInt64: DailyRecords}
        
        // > 2x traders address => Points
        priv let traderPoints:{ Address: UFix64}
        
        /// > 10x traders address => Points
        priv let traders10xBenchmark:{ Address: UFix64}
        
        /// > 100x traders address => Points
        priv let traders100xBenchmark:{ Address: UFix64}
        
        init(_ tick: String?){ 
            self.tick = tick
            self.dailyRecords <-{} 
            self.status = TradingStatus()
            self.traderPoints ={} 
            self.traders10xBenchmark ={} 
            self.traders100xBenchmark ={} 
        }
        
        /// @deprecated after Cadence 1.0
        destroy(){ 
            destroy self.dailyRecords
        }
        
        pub fun getStatus(): TradingStatus{ 
            return self.status
        }
        
        pub fun isSharedRecrds(): Bool{ 
            return self.tick == nil
        }
        
        /// Get the ticker name
        ///
        pub fun getTickerName(): String?{ 
            return self.tick
        }
        
        /// @deprecated
        pub fun getMarketCap(): UFix64?{ 
            return nil
        }
        
        /// Get the public daily records
        ///
        pub fun borrowDailyRecords(_ date: UInt64): &DailyRecords{
            DailyRecordsPublic,
            TradingStatusViewer
        }?{ 
            return self.borrowDailyRecordsPriv(date)
        }
        
        // ---- Traders Points ----
        
        /// Get the 2x traders
        ///
        pub fun getTraders(): [Address]{ 
            return self.traderPoints.keys
        }
        
        /// Get the 2x traders points
        ///
        pub fun getTradersPoints(_ addr: Address): UFix64{ 
            return self.traderPoints[addr] ?? 0.0
        }
        
        /// Get the 10x traders
        ///
        pub fun get10xTraders(): [Address]{ 
            return self.traders10xBenchmark.keys
        }
        
        /// Get the 10x traders points
        ///
        pub fun get10xTradersPoints(_ addr: Address): UFix64{ 
            return self.traders10xBenchmark[addr] ?? 0.0
        }
        
        /// Get the 100x traders
        ///
        pub fun get100xTraders(): [Address]{ 
            return self.traders100xBenchmark.keys
        }
        
        /// Get the 100x traders points
        ///
        pub fun get100xTradersPoints(_ addr: Address): UFix64{ 
            return self.traders100xBenchmark[addr] ?? 0.0
        }
        
        // --- FRC20FTShared.TransactionHook ---
        
        /// The method that is invoked when the transaction is executed
        /// Before try-catch is deployed, please ensure that there will be no panic inside the method.
        ///
        access(account) fun onDeal(
            storefront: Address,
            listingId: UInt64,
            seller: Address,
            buyer: Address,
            tick: String,
            dealAmount: UFix64,
            dealPrice: UFix64,
            totalAmountInListing: UFix64
        ){ 
            if self.owner == nil{ 
                return // DO NOT PANIC
            }
            let frc20Indexer = FRC20Indexer.getIndexer()
            let meta = frc20Indexer.getTokenMeta(tick: tick)
            if meta == nil{ 
                return // DO NOT PANIC
            }
            let newRecord =
                TransactionRecord(
                    storefront: storefront,
                    buyer: buyer,
                    seller: seller,
                    tick: tick,
                    dealAmount: dealAmount,
                    dealPrice: dealPrice,
                    dealPricePerMint: (meta!).limit / dealAmount * dealPrice
                )
            self.addRecord(record: newRecord)
        }
        
        /** Internal Methods */        access(contract) fun addRecord(record: TransactionRecord){ 
            // if tick is not nil, check the ticker name
            if self.tick != nil && self.tick != record.tick{ 
                return // DO NOT PANIC
            }
            
            // timestamp is in seconds, not milliseconds
            let timestamp = record.timestamp
            let date = self.convertToDate(timestamp)
            var dailyRecordsRef = self.borrowDailyRecordsPriv(date)
            if dailyRecordsRef == nil{ 
                self.dailyRecords[date] <-! create DailyRecords(date: date)
                dailyRecordsRef = self.borrowDailyRecordsPriv(date)
            }
            if dailyRecordsRef == nil{ 
                return // DO NOT PANIC
            }
            
            // update the trading status
            let statusRef = self.borrowStatus()
            statusRef.updateByNewRecord(&record as &TransactionRecord)
            (             
             // add to the daily records
             dailyRecordsRef!).addRecord(record: record)
            
            /// calculate the traders points
            let frcIndexer = FRC20Indexer.getIndexer()
            let tokenMeta = frcIndexer.getTokenMeta(tick: record.tick)
            if tokenMeta == nil{ 
                return // DO NOT PANIC
            }
            var benchmarkValue = frcIndexer.getBenchmarkValue(tick: record.tick)
            if benchmarkValue == 0.0{ 
                benchmarkValue = 0.00000001
            }
            let benchmarkPrice = benchmarkValue * record.dealAmount
            let mintAmount = record.dealAmount / (tokenMeta!).limit
            // Check if buyer / seller are an 2x traders
            if record.dealPrice > benchmarkPrice * 2.0{ 
                let points = 1.0 * record.dealPrice / benchmarkPrice * mintAmount
                // earn trading points = 2x points
                self.traderPoints[record.buyer] = (self.traderPoints[record.buyer] ?? 0.0) + points
                self.traderPoints[record.seller] = (self.traderPoints[record.seller] ?? 0.0) + points
            }
            // Check if buyer / seller are an 10x traders, if yes, add extra points
            if record.dealPrice > benchmarkPrice * 10.0{ 
                let points = 5.0 * (record.dealPrice - benchmarkPrice * 10.0) / benchmarkPrice * mintAmount
                // earn trading points = 10x points + 2x points
                self.traders10xBenchmark[record.buyer] = (self.traders10xBenchmark[record.buyer] ?? 0.0) + points
                self.traders10xBenchmark[record.seller] = (self.traders10xBenchmark[record.seller] ?? 0.0) + points
                // add to the 2x traders points
                self.traderPoints[record.buyer] = (self.traderPoints[record.buyer] ?? 0.0) + points
                self.traderPoints[record.seller] = (self.traderPoints[record.seller] ?? 0.0) + points
            }
            // Check if buyer / seller are an 100x traders, if yes, add extra points
            if record.dealPrice > benchmarkPrice * 100.0{ 
                let points = 10.0 * (record.dealPrice - benchmarkPrice * 100.0) / benchmarkPrice * mintAmount
                // earn trading points = 100x points + 10x points + 2x points
                self.traders100xBenchmark[record.buyer] = (self.traders100xBenchmark[record.buyer] ?? 0.0) + points
                self.traders100xBenchmark[record.seller] = (self.traders100xBenchmark[record.seller] ?? 0.0) + points
                // add to the 10x traders points
                self.traders10xBenchmark[record.buyer] = (self.traders10xBenchmark[record.buyer] ?? 0.0) + points
                self.traders10xBenchmark[record.seller] = (self.traders10xBenchmark[record.seller] ?? 0.0) + points
                // add to the 2x traders points
                self.traderPoints[record.buyer] = (self.traderPoints[record.buyer] ?? 0.0) + points
                self.traderPoints[record.seller] = (self.traderPoints[record.seller] ?? 0.0) + points
            }
        // Log for debug
        // log("Trading Point For Buyer<".concat(record.buyer.toString()).concat(">: ").concat(self.traderPoints[record.buyer]?.toString() ?? "0.0"))
        // log("Trading Point For Seller<".concat(record.seller.toString()).concat(">: ").concat(self.traderPoints[record.seller]?.toString() ?? "0.0"))
        }
        
        access(contract) fun borrowStatus(): &TradingStatus{ 
            return &self.status as &TradingStatus
        }
        
        priv fun borrowDailyRecordsPriv(_ time: UInt64): &DailyRecords?{ 
            let date = self.convertToDate(time)
            return &self.dailyRecords[date] as &DailyRecords?
        }
        
        priv fun convertToDate(_ time: UInt64): UInt64{ 
            // date is up to the timestamp of UTC 00:00:00
            return time - time % 86400
        }
    }
    
    /** ---– Public methods ---- *//// The helper method to get the market resource reference
    ///
    pub fun borrowTradingRecords(_ addr: Address): &TradingRecords{
        TradingRecordsPublic,
        TradingStatusViewer
    }?{ 
        return getAccount(addr).getCapability<
            &TradingRecords{TradingRecordsPublic, TradingStatusViewer}
        >(self.TradingRecordsPublicPath).borrow()
    }
    
    /// Create a trading records resource
    ///
    pub fun createTradingRecords(_ tick: String?): @TradingRecords{ 
        return <-create TradingRecords(tick)
    }
    
    init(){ 
        let recordsIdentifier =
            "FRC20TradingRecords_".concat(self.account.address.toString())
        self.TradingRecordsStoragePath = StoragePath(
                identifier: recordsIdentifier
            )!
        self.TradingRecordsPublicPath = PublicPath(
                identifier: recordsIdentifier
            )!
        
        // Register the hooks
        FRC20FTShared.registerHookType(
            Type<@FRC20TradingRecord.TradingRecords>()
        )
        emit ContractInitialized()
    }
}
