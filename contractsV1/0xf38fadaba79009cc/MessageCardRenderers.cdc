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

	import MessageCard from "./MessageCard.cdc"

access(all)
contract MessageCardRenderers{ 
	access(all)
	struct SvgPartsRenderer: MessageCard.IRenderer{ 
		access(all)
		let svgParts: [String]
		
		access(all)
		let replaceKeyAndParamKeys:{ String: String}
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun render(params:{ String: AnyStruct}): MessageCard.RenderResult{ 
			return MessageCard.RenderResult(dataType: "svg", data: self.generateSvg(params: params), extraData: self.extraData)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun generateSvg(params:{ String: AnyStruct}): String{ 
			var svg = ""
			for svgPart in self.svgParts{ 
				let paramKey = self.replaceKeyAndParamKeys[svgPart]
				if paramKey != nil{ 
					svg = svg.concat(params[paramKey!] != nil ? params[paramKey!]! as! String : "")
				} else{ 
					svg = svg.concat(svgPart)
				}
			}
			return svg
		}
		
		init(svgParts: [String], replaceKeyAndParamKeys:{ String: String}, extraData:{ String: AnyStruct}){ 
			self.svgParts = svgParts
			self.replaceKeyAndParamKeys = replaceKeyAndParamKeys
			self.extraData = extraData
		}
	}
}
