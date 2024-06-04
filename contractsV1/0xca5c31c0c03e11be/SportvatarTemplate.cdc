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

	/*

 This contract defines the Sportvatar Templates and the Collection to manage them.
 Sportvatar Templates are the building blocks (lego bricks) of the final Sportvatar,

 Templates are NOT using the NFT standard and will be always linked only to the contract's owner account.

 Templates are organized in Series, Layers and have maximum mint number along with some other variables.

 */

access(all)
contract SportvatarTemplate{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Counter for all the Templates ever minted
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalSeriesSupply: UInt64
	
	//These counters will keep track of how many Components were minted for each Template
	access(contract)
	let totalMintedComponents:{ UInt64: UInt64}
	
	access(contract)
	let totalMintedCollectibles:{ UInt64: UInt64}
	
	access(contract)
	let lastComponentMintedAt:{ UInt64: UFix64}
	
	// Event to notify about the Template creation
	access(all)
	event ContractInitialized()
	
	access(all)
	event Created(
		id: UInt64,
		name: String,
		series: UInt64,
		layer: UInt32,
		maxMintableComponents: UInt64
	)
	
	access(all)
	event CreatedSeries(id: UInt64, name: String, maxMintable: UInt64)
	
	access(all)
	struct Layer{ 
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let isAccessory: Bool
		
		init(id: UInt32, name: String, isAccessory: Bool){ 
			self.id = id
			self.name = name
			self.isAccessory = isAccessory
		}
	}
	
	access(all)
	resource interface PublicSeries{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let svgPrefix: String
		
		access(all)
		let svgSuffix: String
		
		access(contract)
		let layers:{ UInt32: Layer}
		
		access(contract)
		let colors:{ UInt32: String}
		
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		let maxMintable: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLayers():{ UInt32: SportvatarTemplate.Layer}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getColors():{ UInt32: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}
	}
	
	// The Series resource implementing the public interface as well
	access(all)
	resource Series: PublicSeries{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let svgPrefix: String
		
		access(all)
		let svgSuffix: String
		
		access(contract)
		let layers:{ UInt32: Layer}
		
		access(contract)
		let colors:{ UInt32: String}
		
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		let maxMintable: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLayers():{ UInt32: Layer}{ 
			return self.layers
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getColors():{ UInt32: String}{ 
			return self.colors
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		init(name: String, description: String, svgPrefix: String, svgSuffix: String, layers:{ UInt32: Layer}, colors:{ UInt32: String}, metadata:{ String: String}, maxMintable: UInt64){ 
			// increments the counter and stores it as the ID
			SportvatarTemplate.totalSeriesSupply = SportvatarTemplate.totalSeriesSupply + UInt64(1)
			self.id = SportvatarTemplate.totalSeriesSupply
			self.name = name
			self.description = description
			self.svgPrefix = svgPrefix
			self.svgSuffix = svgSuffix
			self.layers = layers
			self.colors = colors
			self.metadata = metadata
			self.maxMintable = maxMintable
		}
	}
	
	// The public interface providing the SVG and all the other 
	// metadata like name, series, layer, etc.
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let series: UInt64
		
		access(all)
		let layer: UInt32
		
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		let rarity: String
		
		access(all)
		let sport: String
		
		access(all)
		let svg: String
		
		access(all)
		let maxMintableComponents: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
	}
	
	// The Template resource implementing the public interface as well
	access(all)
	resource Template: Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let series: UInt64
		
		access(all)
		let layer: UInt32
		
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		let rarity: String
		
		access(all)
		let sport: String
		
		access(all)
		let svg: String
		
		access(all)
		let maxMintableComponents: UInt64
		
		// Initialize a Template with all the necessary data
		init(name: String, description: String, series: UInt64, layer: UInt32, metadata:{ String: String}, rarity: String, sport: String, svg: String, maxMintableComponents: UInt64){ 
			// increments the counter and stores it as the ID
			SportvatarTemplate.totalSupply = SportvatarTemplate.totalSupply + UInt64(1)
			self.id = SportvatarTemplate.totalSupply
			self.name = name
			self.description = description
			self.series = series
			self.layer = layer
			self.metadata = metadata
			self.rarity = rarity
			self.sport = sport
			self.svg = svg
			self.maxMintableComponents = maxMintableComponents
		}
	}
	
	// Standard CollectionPublic interface that can also borrow Component Templates
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeriesIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowTemplate(id: UInt64): &{SportvatarTemplate.Public}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSeries(id: UInt64): &{SportvatarTemplate.PublicSeries}?
	}
	
	// The main Collection that manages the Templates and that implements also the Public interface
	access(all)
	resource Collection: CollectionPublic{ 
		// Dictionary of Component Templates
		access(all)
		var ownedTemplates: @{UInt64: SportvatarTemplate.Template}
		
		access(all)
		var ownedSeries: @{UInt64: SportvatarTemplate.Series}
		
		init(){ 
			self.ownedTemplates <-{} 
			self.ownedSeries <-{} 
		}
		
		// deposit takes a Component Template and adds it to the collections dictionary
		// and adds the ID to the id array
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(template: @SportvatarTemplate.Template){ 
			let id: UInt64 = template.id
			
			// add the new Component Template to the dictionary which removes the old one
			let oldTemplate <- self.ownedTemplates[id] <- template
			destroy oldTemplate
		}
		
		// deposit takes a Series and adds it to the collections dictionary
		// and adds the ID to the id array
		access(TMP_ENTITLEMENT_OWNER)
		fun depositSeries(series: @SportvatarTemplate.Series){ 
			let id: UInt64 = series.id
			
			// add the new Component Template to the dictionary which removes the old one
			let oldTemplate <- self.ownedSeries[id] <- series
			destroy oldTemplate
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.ownedTemplates.keys
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeriesIDs(): [UInt64]{ 
			return self.ownedSeries.keys
		}
		
		// borrowTemplate returns a borrowed reference to a Component Template
		// so that the caller can read data and call methods from it.
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowTemplate(id: UInt64): &{SportvatarTemplate.Public}?{ 
			if self.ownedTemplates[id] != nil{ 
				let ref = (&self.ownedTemplates[id] as &SportvatarTemplate.Template?)!
				return ref as! &SportvatarTemplate.Template
			} else{ 
				return nil
			}
		}
		
		// borrowTemplate returns a borrowed reference to a Component Template
		// so that the caller can read data and call methods from it.
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSeries(id: UInt64): &{SportvatarTemplate.PublicSeries}?{ 
			if self.ownedSeries[id] != nil{ 
				let ref = (&self.ownedSeries[id] as &SportvatarTemplate.Series?)!
				return ref as! &SportvatarTemplate.Series
			} else{ 
				return nil
			}
		}
	}
	
	// This function can only be called by the account owner to create an empty Collection
	access(account)
	fun createEmptyCollection(): @SportvatarTemplate.Collection{ 
		return <-create Collection()
	}
	
	// This struct is used to send a data representation of the Templates
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct SeriesData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let svgPrefix: String
		
		access(all)
		let svgSuffix: String
		
		access(all)
		let layers:{ UInt32: Layer}
		
		access(all)
		let colors:{ UInt32: String}
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let maxMintable: UInt64
		
		access(all)
		let totalMintedCollectibles: UInt64
		
		init(
			id: UInt64,
			name: String,
			description: String,
			svgPrefix: String,
			svgSuffix: String,
			layers:{ 
				UInt32: Layer
			},
			colors:{ 
				UInt32: String
			},
			metadata:{ 
				String: String
			},
			maxMintable: UInt64
		){ 
			self.id = id
			self.name = name
			self.description = description
			self.svgPrefix = svgPrefix
			self.svgSuffix = svgSuffix
			self.layers = layers
			self.colors = colors
			self.metadata = metadata
			self.maxMintable = maxMintable
			self.totalMintedCollectibles = SportvatarTemplate.getTotalMintedCollectibles(
					series: id
				)!
		}
	}
	
	// This struct is used to send a data representation of the Templates 
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct TemplateData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let series: UInt64
		
		access(all)
		let layer: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let rarity: String
		
		access(all)
		let sport: String
		
		access(all)
		let svg: String?
		
		access(all)
		let maxMintableComponents: UInt64
		
		access(all)
		let totalMintedComponents: UInt64
		
		access(all)
		let lastComponentMintedAt: UFix64
		
		init(
			id: UInt64,
			name: String,
			description: String,
			series: UInt64,
			layer: UInt32,
			metadata:{ 
				String: String
			},
			rarity: String,
			sport: String,
			svg: String?,
			maxMintableComponents: UInt64
		){ 
			self.id = id
			self.name = name
			self.description = description
			self.series = series
			self.layer = layer
			self.metadata = metadata
			self.rarity = rarity
			self.sport = sport
			self.svg = svg
			self.maxMintableComponents = maxMintableComponents
			self.totalMintedComponents = SportvatarTemplate.getTotalMintedComponents(id: id)!
			self.lastComponentMintedAt = SportvatarTemplate.getLastComponentMintedAt(id: id)!
		}
	}
	
	// Get all the Component Templates from the account. 
	// We hide the SVG field because it might be too big to execute in a script
	access(TMP_ENTITLEMENT_OWNER)
	fun getTemplates(): [TemplateData]{ 
		var templateData: [TemplateData] = []
		if let templateCollection =
			self.account.capabilities.get<&{SportvatarTemplate.CollectionPublic}>(
				self.CollectionPublicPath
			).borrow<&{SportvatarTemplate.CollectionPublic}>(){ 
			for id in templateCollection.getIDs(){ 
				var template = templateCollection.borrowTemplate(id: id)
				templateData.append(TemplateData(id: id, name: (template!).name, description: (template!).description, series: (template!).series, layer: (template!).layer, metadata: (template!).metadata, rarity: (template!).rarity, sport: (template!).sport, svg: nil, maxMintableComponents: (template!).maxMintableComponents))
			}
		}
		return templateData
	}
	
	// Get all the Series from the account.
	// We hide the SVG field because it might be too big to execute in a script
	access(TMP_ENTITLEMENT_OWNER)
	fun getSeriesAll(): [SeriesData]{ 
		var seriesData: [SeriesData] = []
		if let templateCollection =
			self.account.capabilities.get<&{SportvatarTemplate.CollectionPublic}>(
				self.CollectionPublicPath
			).borrow<&{SportvatarTemplate.CollectionPublic}>(){ 
			for id in templateCollection.getSeriesIDs(){ 
				var series = templateCollection.borrowSeries(id: id)
				seriesData.append(SeriesData(id: id, name: (series!).name, description: (series!).description, svgPrefix: (series!).svgPrefix, svgSuffix: (series!).svgSuffix, layers: (series!).layers, colors: (series!).colors, metadata: (series!).metadata, maxMintable: (series!).maxMintable))
			}
		}
		return seriesData
	}
	
	// Gets a specific Template from its ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getTemplate(id: UInt64): TemplateData?{ 
		if let templateCollection =
			self.account.capabilities.get<&{SportvatarTemplate.CollectionPublic}>(
				self.CollectionPublicPath
			).borrow<&{SportvatarTemplate.CollectionPublic}>(){ 
			if let template = templateCollection.borrowTemplate(id: id){ 
				return TemplateData(id: id, name: (template!).name, description: (template!).description, series: (template!).series, layer: (template!).layer, metadata: (template!).metadata, rarity: (template!).rarity, sport: (template!).sport, svg: (template!).svg, maxMintableComponents: (template!).maxMintableComponents)
			}
		}
		return nil
	}
	
	// Gets the SVG of a specific Template from its ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getTemplateSvg(id: UInt64): String?{ 
		if let templateCollection =
			self.account.capabilities.get<&{SportvatarTemplate.CollectionPublic}>(
				self.CollectionPublicPath
			).borrow<&{SportvatarTemplate.CollectionPublic}>(){ 
			if let template = templateCollection.borrowTemplate(id: id){ 
				return (template!).svg
			}
		}
		return nil
	}
	
	// Gets a specific Series from its ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getSeries(id: UInt64): SeriesData?{ 
		if let templateCollection =
			self.account.capabilities.get<&{SportvatarTemplate.CollectionPublic}>(
				self.CollectionPublicPath
			).borrow<&{SportvatarTemplate.CollectionPublic}>(){ 
			if let series = templateCollection.borrowSeries(id: id){ 
				return SeriesData(id: id, name: (series!).name, description: (series!).description, svgPrefix: (series!).svgPrefix, svgSuffix: (series!).svgSuffix, layers: (series!).layers, colors: (series!).colors, metadata: (series!).metadata, maxMintable: (series!).maxMintable)
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isCollectibleLayerAccessory(layer: UInt32, series: UInt64): Bool{ 
		let series = SportvatarTemplate.getSeries(id: series)!
		if let layer = series.layers[layer]{ 
			if layer.isAccessory{ 
				return true
			}
		}
		return false
	}
	
	// Returns the amount of minted Components for a specific Template
	access(TMP_ENTITLEMENT_OWNER)
	fun getTotalMintedComponents(id: UInt64): UInt64?{ 
		return SportvatarTemplate.totalMintedComponents[id]
	}
	
	// Returns the amount of minted Collectibles for a specific Series
	access(TMP_ENTITLEMENT_OWNER)
	fun getTotalMintedCollectibles(series: UInt64): UInt64?{ 
		return SportvatarTemplate.totalMintedCollectibles[series]
	}
	
	// Returns the timestamp of the last time a Component for a specific Template was minted
	access(TMP_ENTITLEMENT_OWNER)
	fun getLastComponentMintedAt(id: UInt64): UFix64?{ 
		return SportvatarTemplate.lastComponentMintedAt[id]
	}
	
	// This function is used within the contract to set the new counter for each Template
	access(account)
	fun setTotalMintedComponents(id: UInt64, value: UInt64){ 
		SportvatarTemplate.totalMintedComponents[id] = value
	}
	
	// This function is used within the contract to set the new counter for each Template
	access(account)
	fun increaseTotalMintedComponents(id: UInt64){ 
		let totMintedComponents: UInt64? = SportvatarTemplate.totalMintedComponents[id]
		if totMintedComponents != nil{ 
			SportvatarTemplate.totalMintedComponents[id] = totMintedComponents! + UInt64(1)
		}
	}
	
	// This function is used within the contract to set the new counter for each Series
	access(account)
	fun setTotalMintedCollectibles(series: UInt64, value: UInt64){ 
		SportvatarTemplate.totalMintedCollectibles[series] = value
	}
	
	// This function is used within the contract to set the new counter for each Template
	access(account)
	fun increaseTotalMintedCollectibles(series: UInt64){ 
		let totMintedCollectibles: UInt64? = SportvatarTemplate.totalMintedCollectibles[series]
		if totMintedCollectibles != nil{ 
			SportvatarTemplate.totalMintedCollectibles[series] = totMintedCollectibles! + UInt64(1)
		}
	}
	
	// This function is used within the contract to set the timestamp 
	// when a Component for a specific Template was minted
	access(account)
	fun setLastComponentMintedAt(id: UInt64, value: UFix64){ 
		SportvatarTemplate.lastComponentMintedAt[id] = value
	}
	
	access(account)
	fun createTemplate(
		name: String,
		description: String,
		series: UInt64,
		layer: UInt32,
		metadata:{ 
			String: String
		},
		rarity: String,
		sport: String,
		svg: String,
		maxMintableComponents: UInt64
	): @SportvatarTemplate.Template{ 
		var newTemplate <-
			create Template(
				name: name,
				description: description,
				series: series,
				layer: layer,
				metadata: metadata,
				rarity: rarity,
				sport: sport,
				svg: svg,
				maxMintableComponents: maxMintableComponents
			)
		
		// Emits the Created event to notify about the new Template
		emit Created(
			id: newTemplate.id,
			name: newTemplate.name,
			series: newTemplate.series,
			layer: newTemplate.layer,
			maxMintableComponents: newTemplate.maxMintableComponents
		)
		
		// Set the counter for the minted Components of this Template to 0
		SportvatarTemplate.setTotalMintedComponents(id: newTemplate.id, value: UInt64(0))
		SportvatarTemplate.setLastComponentMintedAt(id: newTemplate.id, value: UFix64(0))
		return <-newTemplate
	}
	
	access(account)
	fun createSeries(
		name: String,
		description: String,
		svgPrefix: String,
		svgSuffix: String,
		layers:{ 
			UInt32: Layer
		},
		colors:{ 
			UInt32: String
		},
		metadata:{ 
			String: String
		},
		maxMintable: UInt64
	): @SportvatarTemplate.Series{ 
		var newSeries <-
			create Series(
				name: name,
				description: description,
				svgPrefix: svgPrefix,
				svgSuffix: svgSuffix,
				layers: layers,
				colors: colors,
				metadata: metadata,
				maxMintable: maxMintable
			)
		
		// Emits the Created event to notify about the new Template
		emit CreatedSeries(
			id: newSeries.id,
			name: newSeries.name,
			maxMintable: newSeries.maxMintable
		)
		
		// Set the counter for the minted Collectibles of this Series to 0
		SportvatarTemplate.setTotalMintedCollectibles(series: newSeries.id, value: UInt64(0))
		return <-newSeries
	}
	
	init(){ 
		self.CollectionPublicPath = /public/SportvatarTemplateCollection
		self.CollectionStoragePath = /storage/SportvatarTemplateCollection
		
		// Initialize the total supply
		self.totalSupply = 0
		self.totalSeriesSupply = 0
		self.totalMintedComponents ={} 
		self.totalMintedCollectibles ={} 
		self.lastComponentMintedAt ={} 
		self.account.storage.save<@SportvatarTemplate.Collection>(
			<-SportvatarTemplate.createEmptyCollection(),
			to: SportvatarTemplate.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&SportvatarTemplate.Collection>(
				SportvatarTemplate.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: SportvatarTemplate.CollectionPublicPath)
		emit ContractInitialized()
	}
}
