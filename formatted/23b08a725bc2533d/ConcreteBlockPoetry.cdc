import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

pub contract ConcreteBlockPoetry{ 
    pub event NewPoem(poem: String)
    
    pub struct interface IPoetryLogic{ 
        pub fun generatePoem(blockID: [UInt8; 32]): String{} 
    }
    
    pub struct PoetryLogic: IPoetryLogic{ 
        pub fun generatePoem(blockID: [UInt8; 32]): String{ 
            var poem = ""
            var i = 0
            while i < 32{ 
                poem = poem.concat(self.toAlphabet(blockID[i]!))
                i = i + 1
            }
            return poem
        }
        
        // Based on the frequency of typical English sentences
        priv fun toAlphabet(_ num: UInt8): String{ 
            if num < 27{ 
                return "E"
            }
            if num < 46{ 
                return "T"
            }
            if num < 63{ 
                return "A"
            }
            if num < 79{ 
                return "O"
            }
            if num < 94{ 
                return "I"
            }
            if num < 108{ 
                return "N"
            }
            if num < 121{ 
                return "S"
            }
            if num < 134{ 
                return "H"
            }
            if num < 147{ 
                return "R"
            }
            if num < 156{ 
                return "D"
            }
            if num < 164{ 
                return "L"
            }
            if num < 170{ 
                return "C"
            }
            if num < 175{ 
                return "U"
            }
            if num < 180{ 
                return "M"
            }
            if num < 185{ 
                return "W"
            }
            if num < 190{ 
                return "F"
            }
            if num < 195{ 
                return "G"
            }
            if num < 200{ 
                return "Y"
            }
            if num < 205{ 
                return "P"
            }
            if num < 208{ 
                return "B"
            }
            if num < 211{ 
                return "V"
            }
            if num < 213{ 
                return "K"
            }
            if num < 214{ 
                return "J"
            }
            if num < 215{ 
                return "X"
            }
            if num < 216{ 
                return "Q"
            }
            if num < 217{ 
                return "Z"
            }
            return " "
        }
    }
    
    pub resource interface PoetryCollectionPublic{ 
        pub var poems: @{UFix64: [AnyResource]}
    }
    
    pub resource PoetryCollection: PoetryCollectionPublic{ 
        pub var poems: @{UFix64: [AnyResource]}
        
        init(){ 
            self.poems <-{} 
        }
        
        destroy(){ 
            destroy self.poems
        }
        
        pub fun writePoem(poetryLogic:{ IPoetryLogic}){ 
            let poem = poetryLogic.generatePoem(blockID: getCurrentBlock().id)
            self.poems[getCurrentBlock().timestamp] <-! <-ConcreteAlphabets.newText(poem)
            emit NewPoem(poem: poem)
        }
    }
    
    pub fun createEmptyPoetryCollection(): @PoetryCollection{ 
        return <-create PoetryCollection()
    }
}
