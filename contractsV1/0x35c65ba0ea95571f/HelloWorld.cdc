access(all)
contract HelloWorld{ 
	access(all)
	var greeting: String
	
	access(all)
	fun changeGreeting(newGreeting: String){ 
		self.greeting = newGreeting
	}
	
	init(){ 
		self.greeting = "This is just a test contract."
	}
}
