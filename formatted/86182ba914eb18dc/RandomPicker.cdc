pub contract RandomPicker{ 
    pub var totalSelections: UInt64
    
    priv let extra:{ String: AnyStruct}
    
    priv let additions: @{String: AnyResource}
    
    pub let AdminStoragePath: StoragePath
    
    pub let AdminPublicPath: PublicPath // Public path for accessing giveaway details
    
    pub event GiveawayResult(selectedWinner: String, giveawayId: UInt64)
    
    pub event GiveawayWinners(selectedWinners: [SelectedWinner])
    
    pub event SelectionCreated(giveawayId: UInt64)
    
    pub event SelectionReset(giveawayId: UInt64)
    
    pub struct SelectedWinner{ 
        pub let string: String
        
        pub let timestamp: UFix64
        
        init(string: String, timestamp: UFix64){ 
            self.string = string
            self.timestamp = timestamp
        }
    }
    
    pub resource SelectionDetails{ 
        pub let id: UInt64
        
        pub var strings: [String]
        
        pub var winners: [String]
        
        pub var startRange: UInt64
        
        pub var endRange: UInt64
        
        pub var selectedWinners: [SelectedWinner]
        
        pub var allowMultipleSelections: Bool
        
        pub var isNumbers: Bool
        
        // Function to check if the selected string already exists
        access(contract) fun stringExists(selectedString: String): Bool{ 
            for selected in self.winners{ 
                if selected == selectedString{ 
                    return true
                }
            }
            return false
        }
        
        access(contract) fun getUniqueRandomString(
            startRange: UInt64,
            endRange: UInt64
        ): String{ 
            var uniqueString: String = ""
            var selectedIndex: UInt64 = 0
            var isUnique: Bool = false
            while !isUnique{ 
                selectedIndex = self.getRandom(min: startRange, max: endRange)
                uniqueString = selectedIndex.toString()
                isUnique = !self.stringExists(selectedString: uniqueString)
            }
            return uniqueString
        }
        
        access(contract) fun viewResult(){ 
            emit GiveawayWinners(selectedWinners: self.selectedWinners)
        }
        
        access(contract) fun selectString(): SelectedWinner{ 
            if self.isNumbers{ 
                if self.allowMultipleSelections{ 
                    let selectedIndex: UInt64 = self.getRandom(min: self.startRange, max: self.endRange)
                    let selectedWinnerInfo = SelectedWinner(string: selectedIndex.toString(), timestamp: getCurrentBlock().timestamp)
                    self.selectedWinners.append(selectedWinnerInfo)
                    emit GiveawayResult(selectedWinner: selectedIndex.toString(), giveawayId: self.id)
                    return selectedWinnerInfo
                } else if self.allowMultipleSelections == false && self.startRange != 0 && self.endRange != 0{ 
                    if self.winners.length == Int(self.endRange - self.startRange){ 
                        panic("No strings left to select.")
                    }
                    let uniqueString = self.getUniqueRandomString(startRange: self.startRange, endRange: self.endRange)
                    let selectedWinnerInfo = SelectedWinner(string: uniqueString, timestamp: getCurrentBlock().timestamp)
                    self.selectedWinners.append(selectedWinnerInfo)
                    self.winners.append(uniqueString)
                    emit GiveawayResult(selectedWinner: uniqueString, giveawayId: self.id)
                    return selectedWinnerInfo
                } else{ 
                    if self.strings.length == 0{ 
                        panic("No strings left to select.")
                    }
                    let selectedIndex: UInt64 = self.getRandom(min: 0, max: UInt64(self.strings.length - 1))
                    let selectedString: String = self.strings[Int(selectedIndex)]
                    let selectedWinnerInfo = SelectedWinner(string: selectedString, timestamp: getCurrentBlock().timestamp)
                    self.selectedWinners.append(selectedWinnerInfo)
                    self.strings.remove(at: Int(selectedIndex))
                    emit GiveawayResult(selectedWinner: selectedString, giveawayId: self.id)
                    return selectedWinnerInfo
                }
            } else{ 
                if self.strings.length == 0{ 
                    panic("No strings left to select.")
                }
                let selectedIndex: UInt64 = self.getRandom(min: 0, max: UInt64(self.strings.length - 1))
                let selectedString: String = self.strings[Int(selectedIndex)]
                let selectedWinnerInfo = SelectedWinner(string: selectedString, timestamp: getCurrentBlock().timestamp)
                self.selectedWinners.append(selectedWinnerInfo)
                if !self.allowMultipleSelections{ 
                    self.strings.remove(at: Int(selectedIndex))
                }
                emit GiveawayResult(selectedWinner: selectedString, giveawayId: self.id)
                return selectedWinnerInfo
            }
        }
        
        access(contract) fun getRandom(min: UInt64, max: UInt64): UInt64{ 
            let randomNumber: UInt64 = revertibleRandom() // Replace with your actual random number generator
            return randomNumber % (max + 1 - min) + min
        }
        
        init(
            strings: [
                String
            ],
            allowMultipleSelections: Bool,
            startRange: UInt64,
            endRange: UInt64,
            isNumbers: Bool
        ){ 
            self.id = RandomPicker.totalSelections
            self.strings = strings
            self.selectedWinners = []
            self.startRange = startRange
            self.endRange = endRange
            self.winners = []
            self.allowMultipleSelections = allowMultipleSelections
            self.isNumbers = isNumbers
            RandomPicker.totalSelections = RandomPicker.totalSelections + 1
        }
    }
    
    pub resource interface IAdminPublic{ 
        pub fun borrowSelectionDetails(
            selectionId: UInt64
        ): &SelectionDetails?{} 
    }
    
    pub resource Admin: IAdminPublic{ 
        pub let selectionHistory: @{UInt64: SelectionDetails}
        
        pub fun createSelection(strings: [String], allowMultipleSelections: Bool, startRange: UInt64, endRange: UInt64, isNumbers: Bool): UInt64{ 
            let newSelectionDetails: @SelectionDetails <- create SelectionDetails(strings: strings, allowMultipleSelections: allowMultipleSelections, startRange: startRange, endRange: endRange, isNumbers: isNumbers)
            let giveawayId: UInt64 = newSelectionDetails.id
            self.selectionHistory[giveawayId] <-! newSelectionDetails
            return giveawayId
        }
        
        pub fun selectString(giveawayId: UInt64, newGiveaway: Bool, strings: [String], allowMultipleSelections: Bool, startRange: UInt64, endRange: UInt64, isNumbers: Bool): SelectedWinner?{ 
            if newGiveaway{ 
                let newSelectionDetails: @SelectionDetails <- create SelectionDetails(strings: strings, allowMultipleSelections: allowMultipleSelections, startRange: startRange, endRange: endRange, isNumbers: isNumbers)
                let giveawayIdNew: UInt64 = newSelectionDetails.id
                self.selectionHistory[giveawayIdNew] <-! newSelectionDetails
                let selectionDetails = &self.selectionHistory[giveawayIdNew] as &SelectionDetails?
                return selectionDetails?.selectString()
            } else{ 
                let selectionDetails = self.borrowSelectionDetails(selectionId: giveawayId)
                return selectionDetails?.selectString()
            }
        }
        
        pub fun viewResult(giveawayId: UInt64){ 
            let selectionDetails = self.borrowSelectionDetails(selectionId: giveawayId)
            selectionDetails?.viewResult()
        }
        
        pub fun borrowSelectionDetails(selectionId: UInt64): &SelectionDetails?{ 
            return &self.selectionHistory[selectionId] as &SelectionDetails?
        }
        
        init(){ 
            self.selectionHistory <-{} 
        }
        
        destroy(){ 
            destroy self.selectionHistory
        }
    }
    
    pub fun borrowAdmin(): &Admin{ 
        return self.account.borrow<&RandomPicker.Admin>(
            from: self.AdminStoragePath
        )!
    }
    
    init(){ 
        self.totalSelections = 0
        self.extra ={} 
        self.additions <-{} 
        self.AdminStoragePath = /storage/RandomPickerAdmin
        self.AdminPublicPath = /public/RandomPickerAdminPublic
        let admin: @Admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)
        self.account.link<&RandomPicker.Admin{RandomPicker.IAdminPublic}>(
            self.AdminPublicPath,
            target: self.AdminStoragePath
        )
    }
}
