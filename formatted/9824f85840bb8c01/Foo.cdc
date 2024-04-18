pub contract Foo{ 
    pub resource Vault{} 
    
    pub var temp: @Vault?
    
    init(){ 
        self.temp <- nil
    }
    
    pub fun doubler(): @Vault{ 
        destroy <-create R()
        var doubled <- self.temp <- nil
        return <-doubled!
    }
    
    pub resource R{ 
        pub var bounty: @Vault
        
        pub var dummy: @Vault
        
        init(){ 
            self.bounty <- create Vault()
            self.dummy <- create Vault()
        }
        
        pub fun swap(){ 
            self.bounty <-> self.dummy
        }
        
        destroy(){ 
            // Nested resource is moved here once
            var bounty <- self.bounty
            
            // Nested resource is again moved here. This one should fail.
            self.swap()
            destroy bounty
            destroy self.dummy
        }
    }
}
