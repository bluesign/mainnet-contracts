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
contract Components{ 
	access(all)
	let AdminPath: StoragePath
	
	access(all)
	struct Colors{ 
		access(all)
		let accessories: String
		
		access(all)
		let clothing: String
		
		access(all)
		let hair: String
		
		access(all)
		let hat: String
		
		access(all)
		let facialHair: String
		
		access(all)
		let background: String
		
		access(all)
		let skin: String
		
		init(
			_ accessories: String,
			_ clothing: String,
			_ hair: String,
			_ hat: String,
			_ facialHair: String,
			_ bg: String,
			_ skin: String
		){ 
			self.accessories = accessories
			self.clothing = clothing
			self.hair = hair
			self.hat = hat
			self.facialHair = facialHair
			self.background = bg
			self.skin = skin
		}
	}
	
	access(all)
	struct interface Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Components.Component}}, colors: Components.Colors): String
	}
	
	access(all)
	struct Accessories: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "accessories_".concat(self.name))!) ?? panic("accessory not found")
			switch self.name{ 
				case "eyepatch":
					return content[0]
				default:
					return content[0].concat(colors.accessories).concat(content[1])
			}
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Clothing: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "clothing_".concat(self.name))!) ?? panic("clothing not found")
			switch self.name{ 
				case "graphicShirt":
					if let graphic = components["clothingGraphic"]{ 
						return content[0].concat(colors.clothing).concat(content[1]).concat(graphic.build(components: components, colors: colors)).concat(content[2])
					}
					return content[0].concat(colors.clothing).concat(content[1])
				default:
					return content[0].concat(colors.clothing).concat(content[1])
			}
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct ClothingGraphic: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "clothingGraphic_".concat(self.name))!) ?? panic("clothing not found")
			return content[0]
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Eyebrows: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "eyebrows_".concat(self.name))!) ?? panic("eyebrows not found")
			return content[0]
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Eyes: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "eyes_".concat(self.name))!) ?? panic("eyes not found")
			return content[0]
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct FacialHair: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "facialHair_".concat(self.name))!) ?? panic("facialHair not found")
			return content[0].concat(colors.facialHair).concat(content[1])
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Mouth: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "mouth_".concat(self.name))!) ?? panic("mouth not found")
			return content[0]
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Nose: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "nose_".concat(self.name))!) ?? panic("nose not found")
			return content[0]
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Style: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "style_".concat(self.name))!) ?? panic("style not found")
			let base = (components["base"]!).build(components: components, colors: colors)
			switch self.name{ 
				case "circle":
					return content[0].concat(colors.background).concat(content[1]).concat(base).concat(content[2])
				case "default":
					return base
			}
			return ""
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Top: Component{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(components:{ String:{ Component}}, colors: Colors): String{ 
			let content = Components.account.storage.borrow<&[String]>(from: StoragePath(identifier: "top_".concat(self.name))!) ?? panic("top not found")
			switch self.name{ 
				case "hat":
					return content[0].concat(colors.hat).concat(content[1])
				case "hijab":
					return content[0].concat(colors.hat).concat(content[1])
				case "turban":
					return content[0].concat(colors.hat).concat(content[1])
				case "winterHat1":
					return content[0].concat(colors.hat).concat(content[1])
				case "winterHat2":
					return content[0].concat(colors.hat).concat(content[1])
				case "winterHat3":
					return content[0].concat(colors.hat).concat(content[1])
				case "winterHat4":
					return content[0].concat(colors.hat).concat(content[1])
				default:
					return content[0].concat(colors.hair).concat(content[1])
			}
		}
		
		init(_ n: String){ 
			self.name = n
		}
	}
	
	access(all)
	struct Renderer{ 
		access(all)
		let components:{ String:{ Component}}
		
		access(all)
		let colors: Colors
		
		access(all)
		let flattened:{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun build(): String{ 
			let content =
				Components.account.storage.borrow<&[String]>(
					from: StoragePath(identifier: "base_".concat("default"))!
				)
				?? panic("base not found")
			let document =
				Components.account.storage.borrow<&[String]>(
					from: StoragePath(identifier: "document_default")!
				)
				?? panic("document not found")
			let tmp =
				content[0].concat(self.colors.skin).concat(content[1]).concat(
					self.components["clothing"]?.build(
						components: self.components,
						colors: self.colors
					)
					?? ""
				).concat(content[2]).concat(
					self.components["mouth"]?.build(
						components: self.components,
						colors: self.colors
					)
					?? ""
				).concat(content[3]).concat(
					self.components["nose"]?.build(components: self.components, colors: self.colors)
					?? ""
				).concat(content[4]).concat(
					self.components["eyes"]?.build(components: self.components, colors: self.colors)
					?? ""
				).concat(content[5]).concat(
					self.components["eyebrows"]?.build(
						components: self.components,
						colors: self.colors
					)
					?? ""
				).concat(content[6]).concat(
					self.components["top"]?.build(components: self.components, colors: self.colors)
					?? ""
				).concat(content[7]).concat(
					self.components["facialHair"]?.build(
						components: self.components,
						colors: self.colors
					)
					?? ""
				).concat(content[8]).concat(
					self.components["accessories"]?.build(
						components: self.components,
						colors: self.colors
					)
					?? ""
				).concat(content[9])
			return document[0].concat(tmp).concat(document[1])
		}
		
		init(components:{ String:{ Component}}, colors: Colors){ 
			self.components = components
			self.colors = colors
			self.flattened ={} 
			for k in self.components.keys{ 
				self.flattened[k] = (self.components[k]!).name
			}
			self.flattened["accessoriesColor"] = self.colors.accessories
			self.flattened["clothingColor"] = self.colors.clothing
			self.flattened["hairColor"] = self.colors.hair
			self.flattened["hatColor"] = self.colors.hat
			self.flattened["facialColor"] = self.colors.facialHair
			self.flattened["backgroundColor"] = self.colors.background
			self.flattened["skinColor"] = self.colors.skin
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		let options:{ String:{ String: Bool}}
		
		access(all)
		let colors:{ String: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createRandom(): Renderer{ 
			let c: [String] = []
			var count = 0
			while count < 7{ 
				count = count + 1
				c.append(self.colors.keys[revertibleRandom<UInt64>() % UInt64(self.colors.keys.length)])
			}
			let colors = Colors(c[0], c[1], c[2], c[3], c[4], c[5], c[6])
			let components:{ String:{ Component}} ={} 
			let clothing = Clothing(self.rollOption(segment: "clothing"))
			components["clothing"] = clothing
			if clothing.name == "graphicShirt"{ 
				components["clothingGraphic"] = ClothingGraphic(self.rollOption(segment: "clothingGraphic"))
			}
			components["mouth"] = Mouth(self.rollOption(segment: "mouth"))
			components["nose"] = Nose(self.rollOption(segment: "nose"))
			components["eyes"] = Eyes(self.rollOption(segment: "eyes"))
			components["eyebrows"] = Eyebrows(self.rollOption(segment: "eyebrows"))
			components["top"] = Top(self.rollOption(segment: "top"))
			components["facialHair"] = FacialHair(self.rollOption(segment: "facialHair"))
			components["accessories"] = Accessories(self.rollOption(segment: "accessories"))
			return Renderer(components: components, colors: colors)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun rollOption(segment: String): String{ 
			let keys = (self.options[segment]!).keys
			return keys[revertibleRandom<UInt64>() % UInt64(keys.length)]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerContent(component: String, name: String, content: [String]){ 
			let storagePath = StoragePath(identifier: component.concat("_").concat(name))!
			Components.account.storage.save(content, to: storagePath)
			if self.options[component] == nil{ 
				self.options[component] ={ name: true}
			} else{ 
				let tmp = self.options[component]!
				tmp[name] = true
				self.options[component] = tmp
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addColor(_ c: String){ 
			self.colors.insert(key: c, true)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeColor(_ c: String){ 
			self.colors.remove(key: c)
		}
		
		init(){ 
			self.colors ={} 
			self.options ={} 
		}
	}
	
	init(){ 
		self.AdminPath = /storage/ComponentsAdmin
		let admin <- create Admin()
		let colors =
			[
				"Red",
				"Blue",
				"Green",
				"Yellow",
				"Orange",
				"Purple",
				"Pink",
				"Brown",
				"Black",
				"White",
				"Gray",
				"Cyan",
				"Magenta",
				"Teal",
				"Maroon",
				"Navy",
				"Olive",
				"Turquoise",
				"Gold",
				"Silver",
				"Indigo",
				"Lavender",
				"Coral",
				"Salmon",
				"Plum"
			]
		for c in colors{ 
			admin.addColor(c)
		}
		self.account.storage.save(<-admin, to: self.AdminPath)
	}
}
