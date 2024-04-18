pub contract Logger{ 
    pub event logged(msg: String, data:{ String: String}?)
    
    // Public function that returns our friendly greeting!
    pub fun log(msg: String, data:{ String: String}?){ 
        emit logged(msg: msg, data: data)
    }
}
