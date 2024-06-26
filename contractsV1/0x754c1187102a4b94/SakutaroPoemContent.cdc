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

	//
//  _____		 _			_
// /  ___|	   | |		  | |
// \ `--.   __ _ | | __ _   _ | |_   __ _  _ __   ___
//  `--. \ / _` || |/ /| | | || __| / _` || '__| / _ \
// /\__/ /| (_| ||   < | |_| || |_ | (_| || |   | (_) |
// \____/  \__,_||_|\_\ \__,_| \__| \__,_||_|	\___/
//
//
import Base64Util from "./Base64Util.cdc"

access(all)
contract SakutaroPoemContent{ 
	access(all)
	let name: String
	
	access(all)
	let description: String
	
	access(self)
	let poems: [Poem]
	
	access(all)
	struct Poem{ 
		access(all)
		let title: String
		
		access(all)
		let body: String
		
		access(all)
		let ipfsCid: String
		
		init(title: String, body: String, ipfsCid: String){ 
			self.title = title
			self.body = body
			self.ipfsCid = ipfsCid
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSvg(): String{ 
			var svg = ""
			svg = svg.concat(
					"<svg width=\"400\" height=\"400\" viewBox=\"0, 0, 400, 400\" xmlns=\"http://www.w3.org/2000/svg\">"
				)
			svg = svg.concat(
					"<defs><linearGradient id=\"grad1\" x1=\"0%\" y1=\"50%\"><stop offset=\"0%\" stop-color=\"#0f2350\">"
				)
			svg = svg.concat(
					"<animate id=\"a1\" attributeName=\"stop-color\" values=\"#0f2350; #6a5acd\" begin=\"0; a2.end\" dur=\"3s\" />"
				)
			svg = svg.concat(
					"<animate id=\"a2\" attributeName=\"stop-color\" values=\"#6a5acd; #0f2350\" begin=\"a1.end\" dur=\"3s\" /></stop><stop offset=\"100%\" stop-color=\"#6a5acd\" >"
				)
			svg = svg.concat(
					"<animate id=\"a3\" attributeName=\"stop-color\" values=\"#6a5acd; #0f2350\" begin=\"0; a4.end\" dur=\"3s\" />"
				)
			svg = svg.concat(
					"<animate id=\"a4\" attributeName=\"stop-color\" values=\"#0f2350; #6a5acd\" begin=\"a3.end\" dur=\"3s\" /></stop></linearGradient></defs>"
				)
			svg = svg.concat(
					"<style type=\"text/css\">p {font-family: serif; color: white;}</style>"
				)
			svg = svg.concat("<rect width=\"400\" height=\"400\" fill=\"url(#grad1)\" />")
			svg = svg.concat(
					"<foreignObject x=\"25\" y=\"15\" width=\"350\" height=\"370\"><p class=\"shadow\" xmlns=\"http://www.w3.org/1999/xhtml\">"
				)
			svg = svg.concat(self.title)
			svg = svg.concat("</p><p xmlns=\"http://www.w3.org/1999/xhtml\">")
			svg = svg.concat(self.body)
			svg = svg.concat(
					"</p><p style=\"padding-top: 1em\" xmlns=\"http://www.w3.org/1999/xhtml\">"
				)
			svg = svg.concat("\u{2015} \u{8429}\u{539f} \u{6714}\u{592a}\u{90ce}")
			svg = svg.concat("</p></foreignObject></svg>")
			return svg
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSvgBase64(): String{ 
			return "data:image/svg+xml;base64,".concat(Base64Util.encode(self.getSvg()))
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPoem(_ poemID: UInt32): Poem?{ 
		return self.poems[poemID]
	}
	
	init(){ 
		self.name = "Sakutaro Poem"
		self
			.description = "Thirty-nine poems from Sakutaro Hagiwara's late self-selected collection \"Shukumei\" have been inscribed on Blockchain as full-onchain NFTs. The content of this NFT changes depending on the owner."
		self.poems = [
				Poem(
					title: "\u{3042}\u{3042}\u{56fa}\u{3044}\u{6c37}\u{3092}\u{7834}\u{3064}\u{3066}",
					body: "\u{3042}\u{3042}\u{56fa}\u{3044}\u{6c37}\u{3092}\u{7834}\u{3064}\u{3066}\u{7a81}\u{9032}\u{3059}\u{308b}\u{3001}\u{4e00}\u{3064}\u{306e}\u{5bc2}\u{3057}\u{3044}\u{5e06}\u{8239}\u{3088}\u{3002}\u{3042}\u{306e}\u{9ad8}\u{3044}\u{7a7a}\u{306b}\u{3072}\u{308b}\u{304c}\u{3078}\u{308b}\u{3001}\u{6d6a}\u{6d6a}\u{306e}\u{56fa}\u{9ad4}\u{3057}\u{305f}\u{5370}\u{8c61}\u{304b}\u{3089}\u{3001}\u{305d}\u{306e}\u{9694}\u{96e2}\u{3057}\u{305f}\u{5730}\u{65b9}\u{306e}\u{7269}\u{4f98}\u{3057}\u{3044}\u{51ac}\u{306e}\u{5149}\u{7dda}\u{304b}\u{3089}\u{3001}\u{3042}\u{306f}\u{308c}\u{306b}\u{7164}\u{307c}\u{3051}\u{3066}\u{898b}\u{3048}\u{308b}\u{5c0f}\u{3055}\u{306a}\u{9ed2}\u{3044}\u{7375}\u{9be8}\u{8239}\u{3088}\u{3002}\u{5b64}\u{7368}\u{306a}\u{74b0}\u{5883}\u{306e}\u{6d77}\u{306b}\u{6f02}\u{6cca}\u{3059}\u{308b}\u{8239}\u{306e}\u{7f85}\u{91dd}\u{304c}\u{3001}\u{4e00}\u{3064}\u{306e}\u{92ed}\u{3069}\u{3044}<ruby><rb>\u{610f}\u{5fd7}\u{306e}\u{5c16}\u{89d2}</rb><rp>\u{ff08}</rp><rt>\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}</rt><rp>\u{ff09}</rp></ruby>\u{304c}\u{3001}\u{3042}\u{3042}\u{5982}\u{4f55}\u{306b}\u{56fa}\u{3044}\u{51ac}\u{306e}\u{6c37}\u{3092}\u{7a81}\u{304d}\u{7834}\u{3064}\u{3066}\u{9a40}\u{9032}\u{3059}\u{308b}\u{3053}\u{3068}\u{3088}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{829d}\u{751f}\u{306e}\u{4e0a}\u{3067}",
					body: "\u{82e5}\u{8349}\u{306e}\u{82bd}\u{304c}\u{840c}\u{3048}\u{308b}\u{3084}\u{3046}\u{306b}\u{3001}\u{3053}\u{306e}\u{65e5}\u{7576}\u{308a}\u{306e}\u{3088}\u{3044}\u{829d}\u{751f}\u{306e}\u{4e0a}\u{3067}\u{306f}\u{3001}\u{601d}\u{60f3}\u{304c}\u{5f8c}\u{304b}\u{3089}\u{5f8c}\u{304b}\u{3089}\u{3068}\u{6210}\u{9577}\u{3057}\u{3066}\u{304f}\u{308b}\u{3002}\u{3051}\u{308c}\u{3069}\u{3082}\u{305d}\u{308c}\u{3089}\u{306e}\u{601d}\u{60f3}\u{306f}\u{3001}\u{79c1}\u{306b}\u{307e}\u{3067}\u{4f55}\u{306e}\u{4ea4}\u{6e09}\u{304c}\u{3042}\u{3089}\u{3046}\u{305e}\u{3002}\u{79c1}\u{306f}\u{305f}\u{3060}\u{9752}\u{7a7a}\u{3092}\u{773a}\u{3081}\u{3066}\u{5c45}\u{305f}\u{3044}\u{3002}\u{3042}\u{306e}\u{84bc}\u{5929}\u{306e}\u{5922}\u{306e}\u{4e2d}\u{306b}\u{6eb6}\u{3051}\u{3066}\u{3057}\u{307e}\u{3075}\u{3084}\u{3046}\u{306a}\u{3001}\u{3055}\u{3046}\u{3044}\u{3075}\u{601d}\u{60f3}\u{306e}\u{5e7b}\u{60f3}\u{3060}\u{3051}\u{3092}\u{80b2}\u{304f}\u{307f}\u{305f}\u{3044}\u{306e}\u{3060}\u{3002}\u{79c1}\u{81ea}\u{8eab}\u{306e}\u{60c5}\u{7dd2}\u{306e}\u{5f71}\u{3067}\u{3001}\u{306a}\u{3064}\u{304b}\u{3057}\u{3044}\u{7dd1}\u{9670}\u{306e}\u{5922}\u{3092}\u{3064}\u{304f}\u{308b}\u{3084}\u{3046}\u{306a}\u{3001}\u{305d}\u{308c}\u{3089}\u{306e}\u{300c}\u{60c5}\u{8abf}\u{3042}\u{308b}\u{601d}\u{60f3}\u{300d}\u{3060}\u{3051}\u{3092}\u{8a9e}\u{308a}\u{305f}\u{3044}\u{306e}\u{3060}\u{3002}\u{7a7a}\u{98db}\u{3076}\u{5c0f}\u{9ce5}\u{3088}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{820c}\u{306e}\u{306a}\u{3044}\u{771e}\u{7406}",
					body: "\u{3068}\u{3042}\u{308b}\u{5e7b}\u{71c8}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{9752}\u{767d}\u{3044}\u{96ea}\u{306e}\u{964d}\u{308a}\u{3064}\u{3082}\u{3064}\u{3066}\u{3090}\u{308b}\u{3001}\u{3057}\u{3065}\u{304b}\u{306a}\u{3057}\u{3065}\u{304b}\u{306a}\u{666f}\u{8272}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{79c1}\u{306f}\u{4e00}\u{3064}\u{306e}\u{771e}\u{7406}\u{3092}\u{3064}\u{304b}\u{3093}\u{3060}\u{3002}\u{7269}\u{8a00}\u{3075}\u{3053}\u{3068}\u{306e}\u{3067}\u{304d}\u{306a}\u{3044}\u{3001}\u{6c38}\u{9060}\u{306b}\u{6c38}\u{9060}\u{306b}\u{3046}\u{3089}\u{60b2}\u{3057}\u{3052}\u{306a}\u{3001}\u{79c1}\u{306f}\u{300c}\u{820c}\u{306e}\u{306a}\u{3044}\u{771e}\u{7406}\u{300d}\u{3092}\u{611f}\u{3058}\u{305f}\u{3002}\u{666f}\u{8272}\u{306e}\u{3001}\u{5e7b}\u{71c8}\u{306e}\u{3001}\u{96ea}\u{306e}\u{3064}\u{3082}\u{308b}\u{5f71}\u{3092}\u{904e}\u{304e}\u{53bb}\u{3064}\u{3066}\u{884c}\u{304f}\u{3001}\u{3055}\u{3073}\u{3057}\u{3044}\u{9752}\u{732b}\u{306e}<ruby><rb>\u{50cf}</rb><rp>\u{ff08}</rp><rt>\u{304b}\u{305f}\u{3061}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{304b}\u{3093}\u{3058}\u{305f}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6148}\u{60b2}",
					body: "\u{98a8}\u{7434}\u{306e}<ruby><rb>\u{93ad}\u{9b42}\u{6a02}</rb><rp>\u{ff08}</rp><rt>\u{308c}\u{304f}\u{308c}\u{3048}\u{3080}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{304d}\u{304f}\u{3084}\u{3046}\u{306b}\u{3001}\u{51a5}\u{60f3}\u{306e}\u{539a}\u{3044}\u{58c1}\u{306e}\u{5f71}\u{3067}\u{3001}\u{975c}\u{304b}\u{306b}\u{6e67}\u{304d}\u{3042}\u{304c}\u{3064}\u{3066}\u{304f}\u{308b}\u{9ed2}\u{3044}\u{611f}\u{60c5}\u{3002}\u{60c5}\u{617e}\u{306e}\u{5f37}\u{3044}\u{60f1}\u{307f}\u{3092}\u{6291}\u{3078}\u{3001}\u{679c}\u{6562}\u{306a}\u{3044}\u{904b}\u{547d}\u{3078}\u{306e}\u{53db}\u{9006}\u{3084}\u{3001}\u{4f55}\u{3068}\u{3044}\u{3075}\u{3053}\u{3068}\u{3082}\u{306a}\u{3044}\u{751f}\u{6d3b}\u{306e}\u{6697}\u{6101}\u{3084}\u{3001}\u{3044}\u{3089}\u{3044}\u{3089}\u{3057}\u{305f}\u{5fc3}\u{306e}\u{7126}\u{71e5}\u{3084}\u{3092}\u{5fd8}\u{308c}\u{3055}\u{305b}\u{3001}\u{5b89}\u{3089}\u{304b}\u{306a}\u{5b89}\u{3089}\u{304b}\u{306a}\u{5be2}\u{81fa}\u{306e}\u{4e0a}\u{3067}\u{3001}\u{9748}\u{9b42}\u{306e}\u{6df1}\u{307f}\u{3042}\u{308b}\u{7720}\u{308a}\u{3092}\u{3055}\u{305d}\u{3075}\u{3084}\u{3046}\u{306a}\u{3001}\u{4e00}\u{3064}\u{306e}\u{529b}\u{3042}\u{308b}\u{975c}\u{304b}\u{306a}\u{611f}\u{60c5}\u{3002}\u{305d}\u{308c}\u{306f}\u{751f}\u{6d3b}\u{306e}\u{75b2}\u{308c}\u{305f}\u{8584}\u{66ae}\u{306b}\u{3001}\u{97ff}\u{677f}\u{306e}\u{920d}\u{3044}\u{3046}\u{306a}\u{308a}\u{3092}\u{305f}\u{3066}\u{308b}\u{3001}\u{5927}\u{304d}\u{306a}\u{5e45}\u{306e}\u{3042}\u{308b}\u{975c}\u{304b}\u{306a}\u{611f}\u{60c5}\u{3002}\u{2015}\u{2015}\u{4f5b}\u{9640}\u{306e}\u{6559}\u{3078}\u{305f}\u{6148}\u{60b2}\u{306e}\u{54f2}\u{5b78}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{79cb}\u{6674}",
					body: "\u{7267}\u{5834}\u{306e}\u{725b}\u{304c}\u{8349}\u{3092}\u{98df}\u{3064}\u{3066}\u{3090}\u{308b}\u{306e}\u{3092}\u{307f}\u{3066}\u{3001}\u{9591}\u{6563}\u{3084}\u{6020}\u{60f0}\u{306e}\u{8da3}\u{5473}\u{3092}\u{89e3}\u{3057}\u{306a}\u{3044}\u{307b}\u{3069}\u{3001}\u{305d}\u{308c}\u{307b}\u{3069}<ruby><rb>\u{8fd1}\u{4ee3}\u{7684}\u{306b}\u{306a}\u{3064}\u{3066}\u{3057}\u{307e}\u{3064}\u{305f}</rb><rp>\u{ff08}</rp><rt>\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}</rt><rp>\u{ff09}</rp></ruby>\u{4eba}\u{4eba}\u{306b}\u{307e}\u{3067}\u{3001}\u{79c1}\u{306f}\u{3044}\u{304b}\u{306a}\u{308b}\u{6703}\u{8a71}\u{3092}\u{3082}\u{3055}\u{3051}\u{308b}\u{3067}\u{3042}\u{3089}\u{3046}\u{3002}\u{79c1}\u{306e}\u{808c}\u{306b}\u{3057}\u{307f}\u{8fbc}\u{3093}\u{3067}\u{304f}\u{308b}\u{3001}\u{3053}\u{306e}\u{79cb}\u{65e5}\u{548c}\u{306e}\u{7269}\u{5026}\u{3044}\u{7720}\u{305f}\u{3055}\u{306b}\u{5c31}\u{3044}\u{3066}\u{3001}\u{3053}\u{306e}\u{53e4}\u{98a8}\u{306a}\u{308b}\u{79c1}\u{306e}\u{601d}\u{60f3}\u{306e}\u{60c5}\u{8abf}\u{306b}\u{5c31}\u{3044}\u{3066}\u{3001}\u{3053}\u{306e}\u{4e0a}\u{3082}\u{306f}\u{3084}\u{8a9e}\u{3089}\u{306a}\u{3044}\u{3067}\u{3042}\u{3089}\u{3046}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{9678}\u{6a4b}\u{3092}\u{6e21}\u{308b}",
					body: "\u{6182}\u{9b31}\u{306b}\u{6c88}\u{307f}\u{306a}\u{304c}\u{3089}\u{3001}\u{3072}\u{3068}\u{308a}\u{5bc2}\u{3057}\u{304f}\u{9678}\u{6a4b}\u{3092}\u{6e21}\u{3064}\u{3066}\u{884c}\u{304f}\u{3002}\u{304b}\u{3064}\u{3066}\u{4f55}\u{7269}\u{306b}\u{3055}\u{3078}\u{59a5}\u{5354}\u{305b}\u{3056}\u{308b}\u{3001}\u{4f55}\u{7269}\u{306b}\u{3055}\u{3078}\u{5b89}\u{6613}\u{305b}\u{3056}\u{308b}\u{3001}\u{3053}\u{306e}\u{4e00}\u{3064}\u{306e}\u{611f}\u{60c5}\u{3092}\u{3069}\u{3053}\u{3078}\u{884c}\u{304b}\u{3046}\u{304b}\u{3002}\u{843d}\u{65e5}\u{306f}\u{5730}\u{5e73}\u{306b}\u{4f4e}\u{304f}\u{3001}\u{74b0}\u{5883}\u{306f}\u{6012}\u{308a}\u{306b}\u{71c3}\u{3048}\u{3066}\u{308b}\u{3002}\u{4e00}\u{5207}\u{3092}\u{618e}\u{60e1}\u{3057}\u{3001}\u{7c89}\u{788e}\u{3057}\u{3001}\u{53db}\u{9006}\u{3057}\u{3001}\u{5632}\u{7b11}\u{3057}\u{3001}\u{65ac}\u{5978}\u{3057}\u{3001}\u{6575}\u{613e}\u{3059}\u{308b}\u{3001}\u{3053}\u{306e}\u{4e00}\u{500b}\u{306e}\u{9ed2}\u{3044}\u{5f71}\u{3092}\u{30de}\u{30f3}\u{30c8}\u{306b}\u{3064}\u{3064}\u{3093}\u{3067}\u{3001}\u{3072}\u{3068}\u{308a}\u{5bc2}\u{3057}\u{304f}\u{9678}\u{6a4b}\u{3092}\u{6e21}\u{3064}\u{3066}\u{884c}\u{304f}\u{3002}\u{304b}\u{306e}\u{9ad8}\u{3044}\u{67b6}\u{7a7a}\u{306e}\u{6a4b}\u{3092}\u{8d8a}\u{3048}\u{3066}\u{3001}\u{306f}\u{308b}\u{304b}\u{306e}\u{5e7b}\u{71c8}\u{306e}\u{5e02}\u{8857}\u{306b}\u{307e}\u{3067}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6d99}\u{3050}\u{307e}\u{3057}\u{3044}\u{5915}\u{66ae}",
					body: "\u{3053}\u{308c}\u{3089}\u{306e}\u{5915}\u{66ae}\u{306f}\u{6d99}\u{3050}\u{307e}\u{3057}\u{304f}\u{3001}\u{79c1}\u{306e}\u{66f8}\u{9f4b}\u{306b}\u{8a2a}\u{308c}\u{3066}\u{304f}\u{308b}\u{3002}\u{601d}\u{60f3}\u{306f}\u{60c5}\u{8abf}\u{306e}\u{5f71}\u{306b}\u{306c}\u{308c}\u{3066}\u{3001}\u{611f}\u{3058}\u{306e}\u{3088}\u{3044}\u{6e29}\u{96c5}\u{306e}\u{8272}\u{5408}\u{3092}\u{5e36}\u{3073}\u{3066}\u{898b}\u{3048}\u{308b}\u{3002}\u{3042}\u{3042}\u{3044}\u{304b}\u{306b}\u{4eca}\u{306e}\u{79c1}\u{306b}\u{307e}\u{3067}\u{3001}\u{4e00}\u{3064}\u{306e}\u{60e0}\u{307e}\u{308c}\u{305f}\u{5fb3}\u{306f}\u{306a}\u{3044}\u{304b}\u{3002}\u{4f55}\u{7269}\u{306e}\u{5351}\u{52a3}\u{306b}\u{3059}\u{3089}\u{3001}\u{4f55}\u{7269}\u{306e}\u{865a}\u{50de}\u{306b}\u{3059}\u{3089}\u{3001}\u{3042}\u{3078}\u{3066}\u{9ad8}\u{8cb4}\u{306e}\u{5bdb}\u{5bb9}\u{3092}\u{793a}\u{3057}\u{5f97}\u{308b}\u{3084}\u{3046}\u{306a}\u{3001}\u{4e00}\u{3064}\u{306e}\u{7a69}\u{3084}\u{304b}\u{306b}\u{3057}\u{3066}\u{9591}\u{96c5}\u{306a}\u{308b}\u{5fb3}\u{306f}\u{306a}\u{3044}\u{304b}\u{3002}\u{2015}\u{2015}\u{79c1}\u{3092}\u{3057}\u{3066}\u{7368}\u{308a}\u{5bc2}\u{3057}\u{304f}\u{3001}\u{4eca}\u{65e5}\u{306e}\u{5915}\u{66ae}\u{306e}\u{7a7a}\u{306b}\u{9ed8}\u{601d}\u{305b}\u{3057}\u{3081}\u{3088}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5730}\u{7403}\u{3092}\u{8df3}\u{8e8d}\u{3057}\u{3066}",
					body: "\u{305f}\u{3057}\u{304b}\u{306b}\u{79c1}\u{306f}\u{3001}\u{3042}\u{308b}\u{4e00}\u{3064}\u{306e}\u{7279}\u{7570}\u{306a}\u{624d}\u{80fd}\u{3092}\u{6301}\u{3064}\u{3066}\u{3090}\u{308b}\u{3002}\u{3051}\u{308c}\u{3069}\u{3082}\u{305d}\u{308c}\u{304c}\u{4e01}\u{5ea6}<ruby><rb>\u{3042}\u{3066}\u{306f}\u{307e}\u{308b}</rb><rp>\u{ff08}</rp><rt>\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}</rt><rp>\u{ff09}</rp></ruby>\u{3084}\u{3046}\u{306a}\u{3001}\u{3069}\u{3093}\u{306a}\u{7279}\u{5225}\u{306a}\u{300c}\u{4ed5}\u{4e8b}\u{300d}\u{3082}\u{4eca}\u{65e5}\u{306e}\u{5730}\u{7403}\u{306e}\u{4e0a}\u{306b}\u{6709}\u{308a}\u{306f}\u{3057}\u{306a}\u{3044}\u{3002}\u{3080}\u{3057}\u{308d}\u{79c1}\u{3092}\u{3057}\u{3066}\u{3001}\u{5730}\u{7403}\u{3092}\u{9060}\u{304f}\u{5708}\u{5916}\u{306b}\u{8df3}\u{8e8d}\u{305b}\u{3057}\u{3081}\u{3088}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{591c}\u{6c7d}\u{8eca}\u{306e}\u{7a93}\u{3067}",
					body: "\u{591c}\u{6c7d}\u{8eca}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{96fb}\u{71c8}\u{306f}\u{6697}\u{304f}\u{3001}\u{6c88}\u{9b31}\u{3057}\u{305f}\u{7a7a}\u{6c23}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{4eba}\u{4eba}\u{306f}\u{6df1}\u{3044}\u{7720}\u{308a}\u{306b}\u{843d}\u{3061}\u{3066}\u{3090}\u{308b}\u{3002}\u{4e00}\u{4eba}\u{8d77}\u{304d}\u{3066}\u{7a93}\u{3092}\u{3072}\u{3089}\u{3051}\u{3070}\u{3001}\u{591c}\u{98a8}\u{306f}\u{3064}\u{3081}\u{305f}\u{304f}\u{808c}\u{306b}\u{3075}\u{308c}\u{3001}\u{95c7}\u{591c}\u{306e}\u{6697}\u{9ed2}\u{306a}\u{91ce}\u{539f}\u{3092}\u{98db}\u{3076}\u{3001}\u{3057}\u{304d}\u{308a}\u{306b}\u{98db}\u{3076}\u{706b}\u{87f2}\u{3092}\u{307f}\u{308b}\u{3002}\u{3042}\u{3042}\u{3053}\u{306e}\u{771e}\u{3064}\u{6697}\u{306a}\u{6050}\u{308d}\u{3057}\u{3044}\u{666f}\u{8272}\u{3092}\u{8cab}\u{901a}\u{3059}\u{308b}\u{ff01}\u{3000}\u{6df1}\u{591c}\u{306e}\u{8f5f}\u{8f5f}\u{3068}\u{3044}\u{3075}\u{97ff}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{3044}\u{3065}\u{3053}\u{3078}\u{3001}\u{3044}\u{3065}\u{3053}\u{3078}\u{3001}\u{79c1}\u{306e}\u{591c}\u{6c7d}\u{8eca}\u{306f}\u{884c}\u{304b}\u{3046}\u{3068}\u{3059}\u{308b}\u{306e}\u{304b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6625}\u{306e}\u{304f}\u{308b}\u{6642}",
					body: "\u{6247}\u{3082}\u{3064}\u{82e5}\u{3044}\u{5a18}\u{3089}\u{3001}\u{6625}\u{306e}\u{5c4f}\u{98a8}\u{306e}\u{524d}\u{306b}\u{5c45}\u{3066}\u{3001}\u{541b}\u{306e}\u{3057}\u{306a}\u{3084}\u{304b}\u{306a}\u{80a9}\u{3092}\u{3059}\u{3079}\u{3089}\u{305b}\u{3001}\u{8276}\u{3081}\u{304b}\u{3057}\u{3044}\u{66f2}\u{7dda}\u{306f}\u{8db3}\u{306b}\u{304b}\u{3089}\u{3080}\u{3002}\u{6247}\u{3082}\u{3064}\u{82e5}\u{3044}\u{5a18}\u{3089}\u{3001}\u{541b}\u{306e}\u{7b11}\u{984f}\u{306b}\u{60c5}\u{3092}\u{3075}\u{304f}\u{3081}\u{3088}\u{3001}\u{6625}\u{306f}\u{4f86}\u{3089}\u{3093}\u{3068}\u{3059}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6975}\u{5149}\u{5730}\u{65b9}\u{304b}\u{3089}",
					body: "<ruby><rb>\u{6d77}\u{8c79}</rb><rp>\u{ff08}</rp><rt>\u{3042}\u{3056}\u{3089}\u{3057}</rt><rp>\u{ff09}</rp></ruby>\u{306e}\u{3084}\u{3046}\u{306b}\u{3001}\u{6975}\u{5149}\u{306e}\u{898b}\u{3048}\u{308b}\u{6c37}\u{306e}\u{4e0a}\u{3067}\u{3001}\u{307c}\u{3093}\u{3084}\u{308a}\u{3068}\u{300c}\u{81ea}\u{5206}\u{3092}\u{5fd8}\u{308c}\u{3066}\u{300d}\u{5750}\u{3064}\u{3066}\u{3090}\u{305f}\u{3044}\u{3002}\u{305d}\u{3053}\u{306b}\u{6642}\u{52ab}\u{304c}\u{3059}\u{304e}\u{53bb}\u{3064}\u{3066}\u{884c}\u{304f}\u{3002}\u{665d}\u{591c}\u{306e}\u{306a}\u{3044}\u{6975}\u{5149}\u{5730}\u{65b9}\u{306e}\u{3001}\u{3044}\u{3064}\u{3082}\u{66ae}\u{308c}\u{65b9}\u{306e}\u{3084}\u{3046}\u{306a}\u{5149}\u{7dda}\u{304c}\u{3001}\u{920d}\u{304f}\u{60b2}\u{3057}\u{3052}\u{306b}\u{5e7d}\u{6ec5}\u{3059}\u{308b}\u{3068}\u{3053}\u{308d}\u{3002}\u{3042}\u{3042}\u{305d}\u{306e}\u{9060}\u{3044}\u{5317}\u{6975}\u{5708}\u{306e}\u{6c37}\u{306e}\u{4e0a}\u{3067}\u{3001}\u{307c}\u{3093}\u{3084}\u{308a}\u{3068}\u{6d77}\u{8c79}\u{306e}\u{3084}\u{3046}\u{306b}\u{5750}\u{3064}\u{3066}\u{5c45}\u{305f}\u{3044}\u{3002}\u{6c38}\u{9060}\u{306b}\u{3001}\u{6c38}\u{9060}\u{306b}\u{3001}\u{81ea}\u{5206}\u{3092}\u{5fd8}\u{308c}\u{3066}\u{3001}\u{601d}\u{60df}\u{306e}\u{307b}\u{306e}\u{6697}\u{3044}\u{6d77}\u{306b}\u{6d6e}\u{3076}\u{3001}\u{4e00}\u{3064}\u{306e}\u{4f98}\u{3057}\u{3044}\u{5e7b}\u{8c61}\u{3092}\u{773a}\u{3081}\u{3066}\u{5c45}\u{305f}\u{3044}\u{306e}\u{3067}\u{3059}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{65b7}\u{6a4b}",
					body: "\u{591c}\u{9053}\u{3092}\u{8d70}\u{308b}\u{6c7d}\u{8eca}\u{307e}\u{3067}\u{3001}\u{4e00}\u{3064}\u{306e}\u{8d64}\u{3044}\u{71c8}\u{706b}\u{3092}\u{793a}\u{305b}\u{3088}\u{3002}\u{4eca}\u{305d}\u{3053}\u{306b}\u{5371}\u{96aa}\u{304c}\u{3042}\u{308b}\u{3002}\u{65b7}\u{6a4b}\u{ff01}\u{3000}\u{65b7}\u{6a4b}\u{ff01}\u{3000}\u{3042}\u{3042}\u{60b2}\u{9cf4}\u{306f}\u{98a8}\u{3092}\u{3064}\u{3093}\u{3056}\u{304f}\u{3002}\u{3060}\u{308c}\u{304c}\u{305d}\u{308c}\u{3092}\u{77e5}\u{308b}\u{304b}\u{3002}\u{7cbe}\u{795e}\u{306f}\u{95c7}\u{306e}\u{66e0}\u{91ce}\u{3092}\u{3072}\u{305f}\u{8d70}\u{308b}\u{3002}\u{6025}\u{884c}\u{3057}\u{3001}\u{6025}\u{884c}\u{3057}\u{3001}\u{6025}\u{884c}\u{3057}\u{3001}\u{5f7c}\u{306e}\u{60b2}\u{5287}\u{306e}\u{7d42}\u{9a5b}\u{3078}\u{3068}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{904b}\u{547d}\u{3078}\u{306e}\u{5fcd}\u{8fb1}",
					body: "\u{3068}\u{306f}\u{3044}\u{3078}\u{74b0}\u{5883}\u{306e}\u{95c7}\u{3092}\u{7a81}\u{7834}\u{3059}\u{3079}\u{304d}\u{3001}\u{3069}\u{3093}\u{306a}\u{529b}\u{304c}\u{305d}\u{3053}\u{306b}\u{3042}\u{308b}\u{304b}\u{3002}\u{9f52}\u{304c}\u{307f}\u{3066}\u{3053}\u{3089}\u{3078}\u{3088}\u{3002}\u{3053}\u{3089}\u{3078}\u{3088}\u{3002}\u{3053}\u{3089}\u{3078}\u{3088}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5bc2}\u{5be5}\u{306e}\u{5ddd}\u{908a}",
					body: "\u{53e4}\u{9a5b}\u{306e}\u{3001}\u{67f3}\u{306e}\u{3042}\u{308b}\u{5ddd}\u{306e}\u{5cb8}\u{3067}\u{3001}\u{304b}\u{308c}\u{306f}\u{4f55}\u{3092}\u{91e3}\u{3089}\u{3046}\u{3068}\u{3059}\u{308b}\u{306e}\u{304b}\u{3002}\u{3084}\u{304c}\u{3066}\u{751f}\u{6d3b}\u{306e}\u{8584}\u{66ae}\u{304c}\u{304f}\u{308b}\u{307e}\u{3067}\u{3001}\u{305d}\u{3093}\u{306a}\u{306b}\u{3082}\u{9577}\u{3044}\u{9593}\u{3001}\u{91dd}\u{306e}\u{306a}\u{3044}\u{91e3}\u{7aff}\u{3067}\u{2026}\u{2026}\u{3002}\u{300c}\u{5426}\u{300d}\u{3068}\u{305d}\u{306e}\u{652f}\u{90a3}\u{4eba}\u{304c}\u{7b54}\u{3078}\u{305f}\u{3002}\u{300c}\u{9b5a}\u{306e}\u{7f8e}\u{3057}\u{304f}\u{8d70}\u{308b}\u{3092}\u{773a}\u{3081}\u{3088}\u{3001}\u{6c34}\u{306e}\u{975c}\u{304b}\u{306b}\u{884c}\u{304f}\u{3092}\u{773a}\u{3081}\u{3088}\u{3002}\u{3044}\u{304b}\u{306b}\u{541b}\u{306f}\u{3053}\u{306e}\u{975c}\u{8b10}\u{3092}\u{597d}\u{307e}\u{306a}\u{3044}\u{304b}\u{3002}\u{3053}\u{306e}\u{98a8}\u{666f}\u{306e}\u{8070}\u{660e}\u{306a}\u{60c5}\u{8da3}\u{3092}\u{3002}\u{3080}\u{3057}\u{308d}\u{79c1}\u{306f}\u{3001}\u{7d42}\u{65e5}<ruby><rb>\u{91e3}\u{308a}\u{5f97}\u{306a}\u{3044}</rb><rp>\u{ff08}</rp><rt>\u{30fb}\u{30fb}\u{30fb}\u{30fb}\u{30fb}</rt><rp>\u{ff09}</rp></ruby>\u{3053}\u{3068}\u{3092}\u{5e0c}\u{671b}\u{3057}\u{3066}\u{3090}\u{308b}\u{3002}\u{3055}\u{308c}\u{3070}\u{65e5}\u{7576}\u{308a}\u{597d}\u{3044}\u{5bc2}\u{5be5}\u{306e}\u{5cb8}\u{908a}\u{306b}\u{5750}\u{3057}\u{3066}\u{3001}\u{79c1}\u{306e}\u{3069}\u{3093}\u{306a}\u{74b0}\u{5883}\u{3092}\u{3082}\u{4e82}\u{3059}\u{306a}\u{304b}\u{308c}\u{3002}\u{300d}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{8239}\u{5ba4}\u{304b}\u{3089}",
					body: "\u{5d50}\u{3001}\u{5d50}\u{3001}\u{6d6a}\u{3001}\u{6d6a}\u{3001}\u{5927}\u{6d6a}\u{3001}\u{5927}\u{6d6a}\u{3001}\u{5927}\u{6d6a}\u{3002}\u{50be}\u{3080}\u{304f}\u{5730}\u{5e73}\u{7dda}\u{3001}\u{4e0a}\u{6607}\u{3059}\u{308b}\u{5730}\u{5e73}\u{7dda}\u{3001}\u{843d}\u{3061}\u{304f}\u{308b}\u{5730}\u{5e73}\u{7dda}\u{3002}\u{304c}\u{3061}\u{3084}\u{304c}\u{3061}\u{3084}\u{3001}\u{304c}\u{3061}\u{3084}\u{304c}\u{3061}\u{3084}\u{3002}\u{4e0a}\u{7532}\u{677f}\u{3078}\u{3001}\u{4e0a}\u{7532}\u{677f}\u{3078}\u{3002}<ruby><rb>\u{9396}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30a8}\u{30f3}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{5377}\u{3051}\u{3001}<ruby><rb>\u{9396}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30a8}\u{30f3}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{5377}\u{3051}\u{3002}\u{7a81}\u{9032}\u{3059}\u{308b}\u{3001}\u{7a81}\u{9032}\u{3059}\u{308b}\u{6c34}\u{592b}\u{3089}\u{3002}\u{8239}\u{5ba4}\u{306e}\u{7a93}\u{3001}\u{7a93}\u{3001}\u{7a93}\u{3001}\u{7a93}\u{3002}\u{50be}\u{3080}\u{304f}\u{5730}\u{5e73}\u{7dda}\u{3001}\u{4e0a}\u{6607}\u{3059}\u{308b}\u{5730}\u{5e73}\u{7dda}\u{3002}<ruby><rb>\u{9396}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30a8}\u{30f3}</rt><rp>\u{ff09}</rp></ruby>\u{3001}<ruby><rb>\u{9396}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30a8}\u{30f3}</rt><rp>\u{ff09}</rp></ruby>\u{3001}<ruby><rb>\u{9396}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30a8}\u{30f3}</rt><rp>\u{ff09}</rp></ruby>\u{3002}\u{98a8}\u{3001}\u{98a8}\u{3001}\u{98a8}\u{3002}\u{6c34}\u{3001}\u{6c34}\u{3001}\u{6c34}\u{3002}<ruby><rb>\u{8239}\u{7a93}</rb><rp>\u{ff08}</rp><rt>\u{30cf}\u{30c4}\u{30c1}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{9589}\u{3081}\u{308d}\u{3002}<ruby><rb>\u{8239}\u{7a93}</rb><rp>\u{ff08}</rp><rt>\u{30cf}\u{30c4}\u{30c1}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{9589}\u{3081}\u{308d}\u{3002}\u{53f3}\u{8237}\u{3078}\u{3001}\u{5de6}\u{8237}\u{3078}\u{3002}\u{6d6a}\u{3001}\u{6d6a}\u{3001}\u{6d6a}\u{3002}\u{307b}\u{3072}\u{3086}\u{30fc}\u{308b}\u{3002}\u{307b}\u{3072}\u{3086}\u{30fc}\u{308b}\u{3002}\u{307b}\u{3072}\u{3086}\u{30fc}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{8a18}\u{61b6}\u{3092}\u{6368}\u{3066}\u{308b}",
					body: "\u{68ee}\u{304b}\u{3089}\u{304b}\u{3078}\u{308b}\u{3068}\u{304d}\u{3001}\u{79c1}\u{306f}\u{5e3d}\u{5b50}\u{3092}\u{306c}\u{304e}\u{3059}\u{3066}\u{305f}\u{3002}\u{3042}\u{3042}\u{3001}\u{8a18}\u{61b6}\u{3002}\u{6050}\u{308d}\u{3057}\u{304f}\u{7834}\u{308c}\u{3061}\u{304e}\u{3064}\u{305f}\u{8a18}\u{61b6}\u{3002}\u{307f}\u{3058}\u{3081}\u{306a}\u{3001}\u{6ce5}\u{6c34}\u{306e}\u{4e2d}\u{306b}\u{8150}\u{3064}\u{305f}\u{8a18}\u{61b6}\u{3002}\u{3055}\u{3073}\u{3057}\u{3044}\u{96e8}\u{666f}\u{306e}\u{9053}\u{306b}\u{3075}\u{308b}\u{3078}\u{308b}\u{79c1}\u{306e}\u{5e3d}\u{5b50}\u{3002}\u{80cc}\u{5f8c}\u{306b}\u{6368}\u{3066}\u{3066}\u{884c}\u{304f}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{60c5}\u{7dd2}\u{3088}\u{ff01}\u{3000}\u{541b}\u{306f}\u{6b78}\u{3089}\u{3056}\u{308b}\u{304b}",
					body: "\u{66f8}\u{751f}\u{306f}\u{753a}\u{306b}\u{884c}\u{304d}\u{3001}\u{5de5}\u{5834}\u{306e}\u{4e0b}\u{3092}\u{901a}\u{308a}\u{3001}\u{6a5f}\u{95dc}\u{8eca}\u{306e}\u{9cf4}\u{308b}\u{97ff}\u{3092}\u{807d}\u{3044}\u{305f}\u{3002}\u{706b}\u{592b}\u{306e}\u{8d70}\u{308a}\u{3001}\u{8eca}\u{8f2a}\u{306e}\u{5efb}\u{308a}\u{3001}\u{7fa4}\u{9d09}\u{306e}\u{55a7}\u{865f}\u{3059}\u{308b}\u{5df7}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{306f}\u{3084}\u{4e00}\u{3064}\u{306e}\u{80e1}\u{5f13}\u{306f}\u{8377}\u{9020}\u{3055}\u{308c}\u{3001}\u{8ca8}\u{8eca}\u{306b}\u{7a4d}\u{307e}\u{308c}\u{3001}\u{3055}\u{3046}\u{3057}\u{3066}\u{6e2f}\u{306e}\u{5009}\u{5eab}\u{306e}\u{65b9}\u{3078}\u{3001}\u{7a0e}\u{95dc}\u{306e}\u{9580}\u{3092}\u{304f}\u{3050}\u{3064}\u{3066}\u{884c}\u{3064}\u{305f}\u{3002}<br/>\u{5341}\u{6708}\u{4e0b}\u{65ec}\u{3002}\u{66f8}\u{751f}\u{306f}\u{98ef}\u{3092}\u{98df}\u{306f}\u{3046}\u{3068}\u{3057}\u{3066}\u{3001}\u{67af}\u{308c}\u{305f}\u{829d}\u{8349}\u{306e}\u{5009}\u{5eab}\u{306e}\u{5f71}\u{306b}\u{3001}\u{97f3}\u{6a02}\u{306e}\u{5fcd}\u{3073}\u{5c45}\u{308a}\u{3001}\u{87cb}\u{87c0}\u{306e}\u{3084}\u{3046}\u{306b}\u{9cf4}\u{304f}\u{306e}\u{3092}\u{807d}\u{3044}\u{305f}\u{3002}<br/>\u{2015}\u{2015}\u{60c5}\u{7dd2}\u{3088}\u{3001}\u{541b}\u{306f}\u{6b78}\u{3089}\u{3056}\u{308b}\u{304b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6e2f}\u{306e}\u{96dc}\u{8ca8}\u{5e97}\u{3067}",
					body: "\u{3053}\u{306e}\u{92cf}\u{306e}\u{69d3}\u{529b}\u{3067}\u{3082}\u{3001}\u{5973}\u{306e}\u{9306}\u{3073}\u{3064}\u{3044}\u{305f}<ruby><rb>\u{9285}\u{724c}</rb><rp>\u{ff08}</rp><rt>\u{30e1}\u{30c0}\u{30eb}</rt><rp>\u{ff09}</rp></ruby>\u{304c}\u{5207}\u{308c}\u{306a}\u{3044}\u{306e}\u{304b}\u{3002}\u{6c34}\u{592b}\u{3088}\u{ff01}\u{3000}\u{6c5d}\u{306e}<ruby><rb>\u{96b1}\u{8863}</rb><rp>\u{ff08}</rp><rt>\u{304b}\u{304f}\u{3057}</rt><rp>\u{ff09}</rp></ruby>\u{306e}\u{9322}\u{3092}\u{304b}\u{305e}\u{3078}\u{3066}\u{3001}\u{7121}\u{7528}\u{306e}\u{60c5}\u{71b1}\u{3092}\u{6368}\u{3066}\u{3066}\u{3057}\u{307e}\u{3078}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{93e1}",
					body: "\u{93e1}\u{306e}\u{3046}\u{3057}\u{308d}\u{3078}\u{5efb}\u{3064}\u{3066}\u{307f}\u{3066}\u{3082}\u{3001}\u{300c}\u{79c1}\u{300d}\u{306f}\u{305d}\u{3053}\u{306b}\u{5c45}\u{306a}\u{3044}\u{306e}\u{3067}\u{3059}\u{3088}\u{3002}\u{304a}\u{5b43}\u{3055}\u{3093}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{72d0}",
					body: "\u{898b}\u{3088}\u{ff01}\u{3000}\u{5f7c}\u{306f}\u{98a8}\u{306e}\u{3084}\u{3046}\u{306b}\u{4f86}\u{308b}\u{3002}\u{305d}\u{306e}\u{984d}\u{306f}\u{6182}\u{9b31}\u{306b}\u{9752}\u{3056}\u{3081}\u{3066}\u{3090}\u{308b}\u{3002}\u{8033}\u{306f}\u{3059}\u{308b}\u{3069}\u{304f}\u{5207}\u{3064}\u{7acb}\u{3061}\u{3001}\u{307e}\u{306a}\u{3058}\u{308a}\u{306f}\u{6012}\u{306b}\u{88c2}\u{3051}\u{3066}\u{3090}\u{308b}\u{3002}<br/>\u{541b}\u{3088}\u{ff01}\u{3000}<ruby><rb>\u{72e1}\u{667a}</rb><rp>\u{ff08}</rp><rt>\u{30fb}\u{30fb}</rt><rp>\u{ff09}</rp></ruby>\u{306e}\u{304b}\u{304f}\u{306e}\u{5982}\u{304d}\u{7f8e}\u{3057}\u{304d}\u{8868}\u{60c5}\u{3092}\u{3069}\u{3053}\u{306b}\u{898b}\u{305f}\u{304b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5439}\u{96ea}\u{306e}\u{4e2d}\u{3067}",
					body: "\u{55ae}\u{306b}\u{5b64}\u{7368}\u{3067}\u{3042}\u{308b}\u{3070}\u{304b}\u{308a}\u{3067}\u{306a}\u{3044}\u{3002}\u{6575}\u{3092}\u{4ee5}\u{3066}\u{5145}\u{305f}\u{3055}\u{308c}\u{3066}\u{3090}\u{308b}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{9283}\u{5668}\u{5e97}\u{306e}\u{524d}\u{3067}",
					body: "\u{660e}\u{308b}\u{3044}\u{785d}\u{5b50}\u{6238}\u{306e}\u{5e97}\u{306e}\u{4e2d}\u{3067}\u{3001}\u{4e00}\u{3064}\u{306e}\u{78e8}\u{304b}\u{308c}\u{305f}\u{9283}\u{5668}\u{3055}\u{3078}\u{3082}\u{3001}\u{706b}\u{85e5}\u{3092}\u{88dd}\u{586b}\u{3057}\u{3066}\u{306a}\u{3044}\u{306e}\u{3067}\u{3042}\u{308b}\u{3002}\u{2015}\u{2015}\u{4f55}\u{305f}\u{308b}\u{865a}\u{5984}\u{305e}\u{3002}<ruby><rb>\u{61f6}\u{723e}</rb><rp>\u{ff08}</rp><rt>\u{3089}\u{3093}\u{3058}</rt><rp>\u{ff09}</rp></ruby>\u{3068}\u{3057}\u{3066}\u{7b11}\u{3078}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{865a}\u{6578}\u{306e}\u{864e}",
					body: "\u{535a}\u{5f92}\u{7b49}\u{96c6}\u{307e}\u{308a}\u{3001}\u{6295}\u{3052}\u{3064}\u{3051}\u{3089}\u{308c}\u{305f}\u{308b}\u{751f}\u{6daf}\u{306e}<ruby><rb>\u{6a5f}\u{56e0}</rb><rp>\u{ff08}</rp><rt>\u{30c1}\u{30e4}\u{30f3}\u{30b9}</rt><rp>\u{ff09}</rp></ruby>\u{306e}\u{4e0a}\u{3067}\u{3001}\u{865a}\u{6578}\u{306e}\u{60c5}\u{71b1}\u{3092}\u{8ced}\u{3051}\u{5408}\u{3064}\u{3066}\u{3090}\u{308b}\u{3002}\u{307f}\u{306a}\u{5147}\u{66b4}\u{306e}\u{3064}\u{3089}<ruby><rb>\u{9b42}</rb><rp>\u{ff08}</rp><rt>\u{3060}\u{307e}\u{3057}\u{3072}</rt><rp>\u{ff09}</rp></ruby>\u{3002}<ruby><rb>\u{4ec1}\u{7fa9}</rb><rp>\u{ff08}</rp><rt>\u{3058}\u{3093}\u{304e}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{69cb}\u{3078}\u{3001}\u{864e}\u{306e}\u{3084}\u{3046}\u{306a}\u{7a7a}\u{6d1e}\u{306b}\u{5c45}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{81ea}\u{7136}\u{306e}\u{4e2d}\u{3067}",
					body: "\u{8352}\u{5be5}\u{3068}\u{3057}\u{305f}\u{5c71}\u{306e}\u{4e2d}\u{8179}\u{3067}\u{3001}\u{58c1}\u{306e}\u{3084}\u{3046}\u{306b}\u{6c88}\u{9ed8}\u{3057}\u{3066}\u{3090}\u{308b}\u{3001}\u{4e00}\u{306e}\u{5de8}\u{5927}\u{306a}\u{308b}\u{8033}\u{3092}\u{898b}\u{305f}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{89f8}\u{624b}\u{3042}\u{308b}\u{7a7a}\u{9593}",
					body: "\u{5bbf}\u{547d}\u{7684}\u{306a}\u{308b}\u{6771}\u{6d0b}\u{306e}\u{5efa}\u{7bc9}\u{306f}\u{3001}\u{305d}\u{306e}\u{5c4b}\u{6839}\u{306e}\u{4e0b}\u{3067}\u{5fcd}\u{5f9e}\u{3057}\u{306a}\u{304c}\u{3089}\u{3001}<ruby><rb>\u{750d}</rb><rp>\u{ff08}</rp><rt>\u{3044}\u{3089}\u{304b}</rt><rp>\u{ff09}</rp></ruby>\u{306b}\u{65bc}\u{3066}\u{6012}\u{308a}\u{7acb}\u{3064}\u{3066}\u{3090}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5927}\u{4f5b}",
					body: "\u{305d}\u{306e}\u{5185}\u{90e8}\u{306b}\u{69cb}\u{9020}\u{306e}\u{652f}\u{67f1}\u{3092}\u{6301}\u{3061}\u{3001}\u{6697}\u{3044}\u{68af}\u{5b50}\u{3068}\u{7d93}\u{6587}\u{3092}\u{85cf}\u{3059}\u{308b}\u{4f5b}\u{9640}\u{3088}\u{ff01}\u{3000}\u{6d77}\u{3088}\u{308a}\u{3082}\u{9060}\u{304f}\u{3001}\u{4eba}\u{755c}\u{306e}\u{4f4f}\u{3080}\u{4e16}\u{754c}\u{3092}\u{8d8a}\u{3048}\u{3066}\u{3001}\u{6307}\u{306e}\u{3084}\u{3046}\u{306b}\u{5c28}\u{5927}\u{306a}\u{308c}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5bb6}",
					body: "\u{4eba}\u{304c}\u{5bb6}\u{306e}\u{4e2d}\u{306b}\u{4f4f}\u{3093}\u{3067}\u{308b}\u{306e}\u{306f}\u{3001}\u{5730}\u{4e0a}\u{306e}\u{60b2}\u{3057}\u{3044}\u{98a8}\u{666f}\u{3067}\u{3042}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{9ed2}\u{3044}\u{6d0b}\u{5098}",
					body: "\u{6182}\u{9b31}\u{306e}\u{9577}\u{3044}\u{67c4}\u{304b}\u{3089}\u{3001}\u{96e8}\u{304c}\u{3057}\u{3068}\u{3057}\u{3068}\u{3068}<ruby><rb>\u{6ef4}</rb><rp>\u{ff08}</rp><rt>\u{3057}\u{3065}\u{304f}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{3057}\u{3066}\u{3090}\u{308b}\u{3002}\u{771e}\u{9ed2}\u{306e}\u{5927}\u{304d}\u{306a}\u{6d0b}\u{5098}\u{ff01}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6050}\u{308d}\u{3057}\u{304d}\u{4eba}\u{5f62}\u{829d}\u{5c45}",
					body: "\u{7406}\u{9aee}\u{5e97}\u{306e}\u{9752}\u{3044}\u{7a93}\u{304b}\u{3089}\u{3001}\u{8471}\u{306e}\u{3084}\u{3046}\u{306b}\u{7a81}\u{304d}\u{51fa}\u{3059}\u{68cd}\u{68d2}\u{3002}\u{305d}\u{3044}\u{3064}\u{306e}\u{99ac}\u{9e7f}\u{3089}\u{3057}\u{3044}\u{6a5f}\u{68b0}\u{4ed5}\u{639b}\u{3067}\u{3001}\u{5922}\u{4e2d}\u{306b}\u{306a}\u{3050}\u{3089}\u{308c}\u{3001}\u{306a}\u{3050}\u{3089}\u{308c}\u{3066}\u{5c45}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{9f52}\u{3092}\u{3082}\u{3066}\u{308b}\u{610f}\u{5fd7}",
					body: "\u{610f}\u{5fd7}\u{ff01}\u{3000}\u{305d}\u{306f}\u{5915}\u{66ae}\u{306e}\u{6d77}\u{3088}\u{308a}\u{3057}\u{3066}\u{3001}\u{9c76}\u{306e}\u{5982}\u{304f}\u{306b}\u{6cf3}\u{304e}\u{4f86}\u{308a}\u{3001}\u{9f52}\u{3092}\u{4ee5}\u{3066}\u{8089}\u{306b}\u{565b}\u{307f}\u{3064}\u{3051}\u{308a}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5efa}\u{7bc9}\u{306e} Nostalgia",
					body: "\u{5efa}\u{7bc9}\u{2015}\u{2015}\u{7279}\u{306b}\u{7fa4}\u{5718}\u{3057}\u{305f}\u{5efa}\u{7bc9}\u{2015}\u{2015}\u{306e}\u{6a23}\u{5f0f}\u{306f}\u{3001}\u{7a7a}\u{306e}\u{7a79}\u{7abf}\u{306b}\u{5c0d}\u{3057}\u{3066}\u{69cb}\u{60f3}\u{3055}\u{308c}\u{306d}\u{3070}\u{306a}\u{3089}\u{306c}\u{3002}\u{5373}\u{3061}\u{5207}\u{65b7}\u{3055}\u{308c}\u{305f}\u{308b}\u{7403}\u{306e}\u{5f27}\u{5f62}\u{306b}\u{5c0d}\u{3057}\u{3066}\u{3001}\u{69cd}\u{72b6}\u{306e}\u{5782}\u{76f4}\u{7dda}\u{3084}\u{3001}\u{5713}\u{9310}\u{5f62}\u{3084}\u{306e}\u{4ea4}\u{932f}\u{305b}\u{308b}\u{69cb}\u{60f3}\u{3092}\u{7528}\u{610f}\u{3059}\u{3079}\u{304d}\u{3067}\u{3042}\u{308b}\u{3002}<br/>\u{3053}\u{306e}\u{84bc}\u{7a7a}\u{306e}\u{4e0b}\u{306b}\u{65bc}\u{3051}\u{308b}\u{3001}\u{9060}\u{65b9}\u{306e}\u{90fd}\u{6703}\u{306e}\u{5370}\u{8c61}\u{3068}\u{3057}\u{3066}\u{3001}\u{304a}\u{307b}\u{3080}\u{306d}\u{306e}\u{5efa}\u{7bc9}\u{306f}\u{4e00}\u{3064}\u{306e}\u{91cd}\u{8981}\u{306a}\u{610f}\u{5320}\u{3092}\u{5fd8}\u{308c}\u{3066}\u{3090}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{7236}",
					body: "\u{7236}\u{306f}\u{6c38}\u{9060}\u{306b}\u{60b2}\u{58ef}\u{3067}\u{3042}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6575}",
					body: "\u{6575}\u{306f}\u{5e38}\u{306b}\u{54c4}\u{7b11}\u{3057}\u{3066}\u{3090}\u{308b}\u{3002}\u{3055}\u{3046}\u{3067}\u{3082}\u{306a}\u{3051}\u{308c}\u{3070}\u{3001}\u{4f55}\u{8005}\u{306e}\u{8868}\u{8c61}\u{304c}\u{6012}\u{3089}\u{305b}\u{308b}\u{306e}\u{304b}\u{ff1f}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{7269}\u{8cea}\u{306e}\u{611f}\u{60c5}",
					body: "\u{6a5f}\u{68b0}\u{4eba}\u{9593}\u{306b}\u{3082}\u{3057}\u{611f}\u{60c5}\u{304c}\u{3042}\u{308b}\u{3068}\u{3059}\u{308c}\u{3070}\u{ff1f}\u{3000}\u{7121}\u{9650}\u{306e}\u{54c0}\u{50b7}\u{306e}\u{307b}\u{304b}\u{306e}\u{4f55}\u{8005}\u{3067}\u{3082}\u{306a}\u{3044}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{7269}\u{9ad4}",
					body: "\u{79c1}\u{304c}\u{3082}\u{3057}\u{7269}\u{9ad4}\u{3067}\u{3042}\u{3089}\u{3046}\u{3068}\u{3082}\u{3001}\u{795e}\u{306f}\u{518d}\u{5ea6}\u{6717}\u{3089}\u{304b}\u{306b}\u{7b11}\u{3072}\u{306f}\u{3057}\u{306a}\u{3044}\u{3002}\u{3042}\u{3042}\u{3001}\u{7434}\u{306e}\u{97f3}\u{304c}\u{807d}\u{3048}\u{3066}\u{4f86}\u{308b}\u{3002}\u{2015}\u{2015}\u{5c0f}\u{3055}\u{306a}\u{4e00}\u{3064}\u{306e}<ruby><rb>\u{502b}\u{7406}</rb><rp>\u{ff08}</rp><rt>\u{30e2}\u{30e9}\u{30eb}</rt><rp>\u{ff09}</rp></ruby>\u{304c}\u{3001}\u{55aa}\u{5931}\u{3057}\u{3066}\u{3057}\u{307e}\u{3064}\u{305f}\u{306e}\u{3060}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{9f8d}",
					body: "\u{9f8d}\u{306f}\u{5e1d}\u{738b}\u{306e}\u{6b32}\u{671b}\u{3092}\u{8c61}\u{5fb4}\u{3057}\u{3066}\u{3090}\u{308b}\u{3002}\u{6b0a}\u{529b}\u{306e}\u{7965}\u{96f2}\u{306b}\u{4e58}\u{3064}\u{3066}\u{5c45}\u{306a}\u{304c}\u{3089}\u{3001}\u{5e38}\u{306b}\u{61a4}\u{307b}\u{308d}\u{3057}\u{3044}\u{605a}\u{6012}\u{306b}\u{71c3}\u{3048}\u{3001}\u{4e0d}\u{65b7}\u{306e}\u{722d}\u{9b2a}\u{306e}\u{305f}\u{3081}\u{306b}\u{7259}\u{3092}\u{3080}\u{3044}\u{3066}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6a4b}",
					body: "\u{3059}\u{3079}\u{3066}\u{306e}\u{6a4b}\u{306f}\u{3001}\u{4e00}\u{3064}\u{306e}\u{5efa}\u{7bc9}\u{610f}\u{5320}\u{3057}\u{304b}\u{6301}\u{3064}\u{3066}\u{3090}\u{306a}\u{3044}\u{3002}\u{6642}\u{9593}\u{3092}\u{7a7a}\u{9593}\u{306e}\u{4e0a}\u{306b}\u{67b6}\u{3051}\u{3001}\u{6216}\u{308b}\u{5922}\u{5e7b}\u{7684}\u{306a}\u{4e00}\u{3064}\u{306e}<ruby><rb>\u{89c0}\u{5ff5}</rb><rp>\u{ff08}</rp><rt>\u{30a4}\u{30c7}\u{30a2}</rt><rp>\u{ff09}</rp></ruby>\u{3092}\u{3001}\u{73fe}\u{5be6}\u{7684}\u{306b}\u{8fa8}\u{8b49}\u{3059}\u{308b}\u{3053}\u{3068}\u{306e}\u{71b1}\u{610f}\u{3067}\u{3042}\u{308b}\u{3002}<br/>\u{6a4b}\u{3068}\u{306f}\u{2015}\u{2015}\u{5922}\u{3092}\u{67b6}\u{7a7a}\u{3057}\u{305f}\u{6578}\u{5b78}\u{3067}\u{3042}\u{308b}\u{3002}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{5c71}\u{4e0a}\u{306e}\u{7948}",
					body: "\u{591a}\u{304f}\u{306e}\u{5148}\u{5929}\u{7684}\u{306e}\u{8a69}\u{4eba}\u{3084}\u{85dd}\u{8853}\u{5bb6}\u{7b49}\u{306f}\u{3001}\u{5f7c}\u{7b49}\u{306e}\u{5bbf}\u{547d}\u{3065}\u{3051}\u{3089}\u{308c}\u{305f}\u{4ed5}\u{4e8b}\u{306b}\u{5c0d}\u{3057}\u{3066}\u{3001}\u{3042}\u{306e}\u{60b2}\u{75db}\u{306a}\u{8036}\u{8607}\u{306e}\u{7948}\u{3092}\u{3088}\u{304f}\u{77e5}\u{3064}\u{3066}\u{308b}\u{3002}\u{300c}\u{795e}\u{3088}\u{ff01}\u{3000}\u{3082}\u{3057}\u{5fa1}\u{5fc3}\u{306b}\u{9069}\u{3075}\u{306a}\u{3089}\u{3070}\u{3001}\u{3053}\u{306e}\u{82e6}\u{304d}\u{9152}\u{76c3}\u{3092}\u{96e2}\u{3057}\u{7d66}\u{3078}\u{3002}\u{3055}\u{308c}\u{3069}\u{723e}\u{306b}\u{3057}\u{3066}\u{6b32}\u{3059}\u{308b}\u{306a}\u{3089}\u{3070}\u{3001}\u{5fa1}\u{5fc3}\u{306e}\u{307e}\u{307e}\u{306b}\u{7232}\u{3057}\u{7d66}\u{3078}\u{3002}\u{300d}",
					ipfsCid: ""
				),
				Poem(
					title: "\u{6230}\u{5834}\u{3067}\u{306e}\u{5e7b}\u{60f3}",
					body: "\u{6a5f}\u{95dc}\u{9283}\u{3088}\u{308a}\u{3082}\u{60b2}\u{3057}\u{3052}\u{306b}\u{3001}\u{7e4b}\u{7559}\u{6c23}\u{7403}\u{3088}\u{308a}\u{3082}\u{6182}\u{9b31}\u{306b}\u{3001}\u{70b8}\u{88c2}\u{5f48}\u{3088}\u{308a}\u{3082}\u{6b98}\u{5fcd}\u{306b}\u{3001}\u{6bd2}\u{74e6}\u{65af}\u{3088}\u{308a}\u{3082}\u{6c88}\u{75db}\u{306b}\u{3001}\u{66f3}\u{706b}\u{5f48}\u{3088}\u{308a}\u{3082}\u{84bc}\u{767d}\u{304f}\u{3001}\u{5927}\u{7832}\u{3088}\u{308a}\u{3082}\u{30ed}\u{30de}\u{30f3}\u{30c1}\u{30c4}\u{30af}\u{306b}\u{3001}\u{7159}\u{5e55}\u{3088}\u{308a}\u{3082}\u{5bc2}\u{3057}\u{3052}\u{306b}\u{3001}\u{9283}\u{706b}\u{306e}\u{767d}\u{304f}\u{9583}\u{3081}\u{304f}\u{3084}\u{3046}\u{306a}\u{8a69}\u{304c}\u{66f8}\u{304d}\u{305f}\u{3044}\u{ff01}",
					ipfsCid: ""
				)
			]
	}
}
