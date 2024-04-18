import TestImport from "../0xea57707519a77b05/TestImport.cdc"

pub contract Test{ 
    pub var x: TestImport.TestStruct
    
    init(){ 
        self.x = TestImport.TestStruct()
    }
}
