access(all)
contract Words{ 
	access(account)
	let syllables:{ String: Int}
	
	access(account)
	let uncompress:{ String: String}
	
	init(){ 
		self.syllables ={ 
				"END": 0,
				"START": 0,
				"\n": 0,
				"the": 1,
				"I": 1,
				"to": 1,
				"and": 1,
				"a": 1,
				"of": 1,
				"you": 1,
				"in": 1,
				"my": 1,
				"is": 1,
				"for": 1,
				"me": 1,
				"it": 1,
				"that": 1,
				"on": 1,
				"with": 1,
				"this": 1,
				"be": 1,
				"so": 1,
				"but": 1,
				"not": 1,
				"he": 1,
				"all": 1,
				"have": 1,
				"was": 1,
				"I'm": 1,
				"his": 1,
				"are": 1,
				"they": 1,
				"your": 1,
				"at": 1,
				"just": 1,
				"like": 1,
				"as": 1,
				"when": 1,
				"we": 1,
				"her": 1,
				"what": 1,
				"if": 1,
				"from": 1,
				"one": 1,
				"no": 1,
				"do": 1,
				"will": 1,
				"up": 1,
				"love": 1,
				"now": 1,
				"don't": 1,
				"out": 1,
				"can": 1,
				"she": 1,
				"get": 1,
				"how": 1,
				"day": 1,
				"know": 1,
				"by": 1,
				"who": 1,
				"people": 2,
				"go": 1,
				"there": 1,
				"time": 1,
				"him": 1,
				"it's": 1,
				"about": 2,
				"never": 2,
				"then": 1,
				"really": 2,
				"or": 1,
				"good": 1,
				"more": 1,
				"them": 1,
				"see": 1,
				"their": 1,
				"life": 1,
				"an": 1,
				"had": 1,
				"has": 1,
				"would": 1,
				"want": 1,
				"make": 1,
				"am": 1,
				"only": 2,
				"back": 1,
				"still": 1,
				"too": 1,
				"why": 1,
				"here": 1,
				"some": 1,
				"man": 1,
				"come": 1,
				"going": 2,
				"said": 1,
				"been": 1,
				"let": 1,
				"night": 1,
				"can't": 1,
				"than": 1,
				"need": 1,
				"ever": 2,
				"much": 1,
				"think": 1,
				"were": 1,
				"thy": 1,
				"way": 1,
				"down": 1,
				"our": 2,
				"again": 2,
				"always": 2,
				"someone": 2,
				"even": 2,
				"God": 1,
				"heart": 1,
				"got": 1,
				"us": 1,
				"say": 1,
				"did": 1,
				"today": 2,
				"thou": 1,
				"where": 1,
				"right": 1,
				"shit": 1,
				"take": 1,
				"feel": 1,
				"should": 1,
				"well": 1,
				"shall": 1,
				"over": 2,
				"wanna": 2,
				"before": 2,
				"off": 1,
				"could": 1,
				"last": 1,
				"happy": 2,
				"new": 1,
				"things": 1,
				"thee": 1,
				"yet": 1,
				"work": 1,
				"into": 2,
				"long": 1,
				"away": 2,
				"through": 1,
				"these": 1,
				"first": 1,
				"May": 1,
				"better": 2,
				"gonna": 2,
				"little": 2,
				"best": 1,
				"give": 1,
				"I've": 1,
				"every": 3,
				"tell": 1,
				"world": 1,
				"look": 1,
				"thing": 1,
				"its": 1,
				"because": 2,
				"being": 2,
				"must": 1,
				"eyes": 1,
				"home": 1,
				"you're": 1,
				"lol": 1,
				"I'll": 1,
				"made": 1,
				"great": 1,
				"nothing": 2,
				"old": 1,
				"year": 1,
				"that's": 1,
				"many": 2,
				"im": 1,
				"such": 1,
				"morning": 2,
				"which": 1,
				"myself": 2,
				"upon": 2,
				"keep": 1,
				"after": 2,
				"sleep": 1,
				"something": 2,
				"hope": 1,
				"fuck": 1,
				"other": 2,
				"came": 1,
				"while": 1,
				"thought": 1,
				"find": 1,
				"very": 2,
				"done": 1,
				"oh": 1,
				"hate": 1,
				"face": 1,
				"own": 1,
				"two": 1,
				"getting": 2,
				"men": 1,
				"end": 1,
				"light": 1,
				"once": 1,
				"please": 1,
				"does": 1,
				"any": 2,
				"hand": 1,
				"friends": 1,
				"bad": 1,
				"u": 1,
				"those": 1,
				"didn't": 2,
				"head": 1,
				"trying": 2,
				"stop": 1,
				"next": 1,
				"makes": 1,
				"put": 1,
				"dead": 1,
				"everything": 3,
				"death": 1,
				"hear": 1,
				"everyone": 3,
				"alone": 2,
				"sometimes": 2,
				"most": 1,
				"same": 1,
				"far": 1,
				"around": 2,
				"went": 1,
				"wish": 1,
				"days": 1,
				"person": 2,
				"left": 1,
				"anyone": 3,
				"might": 1,
				"though": 1,
				"doing": 2,
				"hard": 1,
				"fucking": 2,
				"live": 1,
				"o": 1,
				"place": 1,
				"friend": 1,
				"name": 1,
				"mind": 1,
				"each": 1,
				"wait": 1,
				"house": 1,
				"care": 1,
				"white": 1,
				"believe": 2,
				"watch": 1,
				"song": 1,
				"y'all": 1,
				"having": 2,
				"rest": 1,
				"gotta": 2,
				"soul": 1,
				"call": 1,
				"nor": 1,
				"full": 1,
				"leave": 1,
				"game": 1,
				"thus": 1,
				"sweet": 1,
				"sun": 1,
				"show": 1,
				"without": 2,
				"die": 1,
				"gone": 1,
				"another": 3,
				"earth": 1,
				"soon": 1,
				"thank": 1,
				"there's": 1,
				"hair": 1,
				"doesn't": 2,
				"high": 1,
				"rain": 1,
				"bed": 1,
				"baby": 2,
				"enough": 2,
				"cause": 1,
				"mine": 1,
				"play": 1,
				"heard": 1,
				"girl": 1,
				"money": 2,
				"moon": 1,
				"words": 1,
				"stay": 1,
				"talk": 1,
				"saw": 1,
				"ass": 1,
				"ready": 2,
				"looking": 2,
				"king": 1,
				"tonight": 2,
				"christmas": 2,
				"feeling": 2,
				"already": 3,
				"since": 1,
				"week": 1,
				"tomorrow": 3,
				"help": 1,
				"lord": 1,
				"seen": 1,
				"until": 2,
				"fall": 1,
				"tired": 2,
				"knew": 1,
				"start": 1,
				"comes": 1,
				"true": 1,
				"cannot": 2,
				"sky": 1,
				"years": 1,
				"else": 1,
				"cold": 1,
				"music": 2,
				"coming": 2,
				"wind": 1,
				"found": 1,
				"whole": 1,
				"try": 1,
				"summer": 2,
				"lost": 1,
				"sure": 1,
				"remember": 3,
				"till": 1,
				"sad": 1,
				"ain't": 1,
				"black": 1,
				"hands": 1,
				"anything": 3,
				"yourself": 2,
				"real": 1,
				"miss": 1,
				"told": 1,
				"both": 1,
				"school": 1,
				"cry": 1,
				"eat": 1,
				"change": 1,
				"fair": 1,
				"took": 1,
				"ask": 1,
				"wonder": 2,
				"side": 1,
				"mother": 2,
				"dear": 1,
				"beautiful": 3,
				"'tis": 1,
				"wrong": 1,
				"sorry": 2,
				"gave": 1,
				"lot": 1,
				"red": 1,
				"under": 2,
				"literally": 4,
				"Twitter": 2,
				"turn": 1,
				"fear": 1,
				"speak": 1,
				"also": 2,
				"peace": 1,
				"mean": 1,
				"heaven": 2,
				"free": 1,
				"round": 1,
				"sea": 1,
				"part": 1,
				"spring": 1,
				"yes": 1,
				"okay": 2,
				"hour": 2,
				"he's": 1,
				"making": 2,
				"art": 1,
				"winter": 2,
				"word": 1,
				"break": 1,
				"looks": 1,
				"voice": 1,
				"hold": 1,
				"snow": 1,
				"watching": 2,
				"read": 1,
				"bitch": 1,
				"together": 3,
				"bring": 1,
				"son": 1,
				"ye": 1,
				"none": 1,
				"pain": 1,
				"family": 3,
				"hell": 1,
				"child": 1,
				"truth": 1,
				"late": 1,
				"won't": 1,
				"dream": 1,
				"water": 2,
				"thanks": 1,
				"big": 1,
				"set": 1,
				"half": 1,
				"against": 2,
				"forget": 2,
				"lay": 1,
				"dark": 1,
				"maybe": 2,
				"follow": 2,
				"fire": 2,
				"deep": 1,
				"woman": 2,
				"kind": 1,
				"pretty": 2,
				"tears": 1,
				"young": 1,
				"actually": 4,
				"within": 2,
				"blue": 1,
				"listen": 2,
				"wanted": 2,
				"air": 1,
				"birthday": 2,
				"reason": 2,
				"sound": 1,
				"honestly": 3,
				"haven't": 2,
				"room": 1,
				"feet": 1,
				"open": 2,
				"boy": 1,
				"stand": 1,
				"needs": 1,
				"thinking": 2,
				"joy": 1,
				"I'd": 1,
				"leaves": 1,
				"use": 1,
				"loved": 1,
				"matter": 2,
				"door": 1,
				"behind": 2,
				"between": 2,
				"knows": 1,
				"women": 2,
				"damn": 1,
				"few": 1,
				"win": 1,
				"power": 2,
				"meet": 1,
				"waiting": 2,
				"finally": 3,
				"fight": 1,
				"ok": 2,
				"three": 1,
				"close": 1,
				"past": 1,
				"talking": 2,
				"what's": 1,
				"times": 1,
				"land": 1,
				"lie": 1,
				"near": 1,
				"pass": 1,
				"run": 1,
				"early": 2,
				"move": 1,
				"food": 1,
				"understand": 3,
				"fell": 1,
				"thine": 1,
				"ah": 1,
				"nice": 1,
				"goes": 1,
				"above": 2,
				"excited": 3,
				"war": 1,
				"crazy": 2,
				"says": 1,
				"body": 2,
				"smile": 1,
				"turned": 1,
				"used": 1,
				"father": 2,
				"pray": 1,
				"sick": 1,
				"stars": 1,
				"blood": 1,
				"fun": 1,
				"trust": 1,
				"wow": 1,
				"car": 1,
				"guess": 1,
				"whom": 1,
				"phone": 1,
				"forth": 1,
				"guys": 1,
				"others": 2,
				"nobody": 3,
				"isn't": 2,
				"dog": 1,
				"sing": 1,
				"tree": 1,
				"rose": 1,
				"lose": 1,
				"saying": 2,
				"taking": 2,
				"gold": 1,
				"hot": 1,
				"children": 2,
				"moment": 2,
				"line": 1,
				"drink": 1,
				"eye": 1,
				"wants": 1,
				"learn": 1,
				"seems": 1,
				"you'll": 1,
				"playing": 2,
				"weekend": 2,
				"poor": 1,
				"o'er": 2,
				"felt": 1,
				"living": 2,
				"wake": 1,
				"cried": 1,
				"lady": 2,
				"green": 1,
				"worst": 1,
				"almost": 2,
				"anymore": 3,
				"looked": 1,
				"book": 1,
				"working": 2,
				"mad": 1,
				"hurt": 1,
				"arms": 1,
				"vain": 1,
				"walk": 1,
				"glad": 1,
				"answer": 2,
				"mom": 1,
				"save": 1,
				"called": 1,
				"himself": 2,
				"dreams": 1,
				"stood": 1,
				"beauty": 2,
				"died": 1,
				"silence": 2,
				"gets": 1,
				"pay": 1,
				"bright": 1,
				"tweet": 1,
				"buy": 1,
				"somebody": 3,
				"along": 2,
				"fast": 1,
				"strong": 1,
				"worth": 1,
				"evening": 2,
				"sit": 1,
				"season": 2,
				"city": 2,
				"point": 1,
				"bear": 1,
				"autumn": 2,
				"amazing": 3,
				"probably": 3,
				"story": 2,
				"question": 2,
				"met": 1,
				"less": 1,
				"crying": 2,
				"sir": 1,
				"least": 1,
				"forgot": 2,
				"seeing": 2,
				"brother": 2,
				"return": 2,
				"hath": 1,
				"beneath": 2,
				"thoughts": 1,
				"funny": 2,
				"second": 2,
				"let's": 1,
				"among": 2,
				"wife": 1,
				"proud": 1,
				"deserve": 2,
				"hit": 1,
				"hours": 2,
				"send": 1,
				"takes": 1,
				"they're": 1,
				"job": 1,
				"low": 1,
				"ya": 1,
				"brought": 1,
				"cool": 1,
				"imagine": 3,
				"wine": 1,
				"star": 1,
				"either": 2,
				"sight": 1,
				"cut": 1,
				"forever": 3,
				"asked": 1,
				"we're": 1,
				"kiss": 1,
				"gods": 1,
				"broke": 1,
				"beat": 1,
				"guy": 1,
				"born": 1,
				"small": 1,
				"known": 1,
				"different": 3,
				"window": 2,
				"across": 2,
				"holy": 2,
				"movie": 2,
				"girls": 1,
				"swear": 1,
				"touch": 1,
				"lies": 1,
				"feels": 1,
				"rather": 2,
				"queen": 1,
				"flowers": 2,
				"single": 2,
				"fine": 1,
				"breast": 1,
				"grow": 1,
				"lips": 1,
				"passed": 1,
				"clear": 1,
				"weather": 2,
				"unto": 2,
				"news": 1,
				"course": 1,
				"instead": 2,
				"wild": 1,
				"started": 2,
				"longer": 2,
				"wasn't": 2,
				"beyond": 2,
				"class": 1,
				"breath": 1,
				"straight": 1,
				"outside": 2,
				"wings": 1,
				"short": 1,
				"everybody": 4,
				"strength": 1,
				"she's": 1,
				"sense": 1,
				"warm": 1,
				"trees": 1,
				"clouds": 1,
				"happen": 2,
				"forward": 2,
				"asleep": 2,
				"songs": 1,
				"month": 1,
				"laugh": 1,
				"wide": 1,
				"rise": 1,
				"town": 1,
				"video": 3,
				"woke": 1,
				"wear": 1,
				"grave": 1,
				"country": 2,
				"kill": 1,
				"sent": 1,
				"kids": 1,
				"fate": 1,
				"supposed": 2,
				"faith": 1,
				"loves": 1,
				"road": 1,
				"seem": 1,
				"easy": 2,
				"mood": 1,
				"listening": 3,
				"Trump": 1,
				"seek": 1,
				"inside": 2,
				"lives": 1,
				"coffee": 2,
				"ones": 1,
				"spirit": 2,
				"able": 2,
				"self": 1,
				"fly": 1,
				"wise": 1,
				"ago": 2,
				"state": 1,
				"worse": 1,
				"team": 1,
				"means": 1,
				"sat": 1,
				"beside": 2,
				"become": 2,
				"human": 2,
				"act": 1,
				"wouldn't": 2,
				"starting": 2,
				"dawn": 1,
				"bit": 1,
				"write": 1,
				"future": 2,
				"ways": 1,
				"perfect": 2,
				"stuff": 1,
				"broken": 2,
				"cute": 1,
				"stupid": 2,
				"drive": 1,
				"sister": 2,
				"favorite": 3,
				"shadow": 2,
				"yeah": 1,
				"wall": 1,
				"ground": 1,
				"falling": 2,
				"mouth": 1,
				"held": 1,
				"grief": 1,
				"Friday": 2,
				"post": 1,
				"happened": 2,
				"super": 2,
				"couldn't": 2,
				"heat": 1,
				"bitches": 2,
				"street": 1,
				"tried": 1,
				"boys": 1,
				"youth": 1,
				"field": 1,
				"garden": 2,
				"gives": 1,
				"hearts": 1,
				"sorrow": 2,
				"giving": 2,
				"ere": 1,
				"later": 2,
				"merry": 2,
				"grace": 1,
				"idea": 3,
				"you've": 1,
				"train": 1,
				"ice": 1,
				"order": 2,
				"bird": 1,
				"praise": 1,
				"afraid": 2,
				"stream": 1,
				"shame": 1,
				"golden": 2,
				"spoke": 1,
				"laid": 1,
				"silent": 2,
				"woe": 1,
				"seemed": 1,
				"enjoy": 2,
				"darkness": 2,
				"given": 2,
				"age": 1,
				"glory": 2,
				"check": 1,
				"asking": 2,
				"eating": 2,
				"dust": 1,
				"storm": 1,
				"chance": 1,
				"yesterday": 3,
				"shut": 1,
				"form": 1,
				"dying": 2,
				"dance": 1,
				"account": 2,
				"empty": 2,
				"spake": 1,
				"bless": 1,
				"stone": 1,
				"weep": 1,
				"race": 1,
				"social": 2,
				"front": 1,
				"alas": 2,
				"doubt": 1,
				"running": 2,
				"welcome": 2,
				"problem": 2,
				"sitting": 2,
				"nature": 2,
				"pride": 1,
				"feelings": 2,
				"smell": 1,
				"river": 2,
				"whatever": 3,
				"hast": 1,
				"Jesus": 2,
				"knowing": 2,
				"writing": 2,
				"meant": 1,
				"quite": 1,
				"evil": 2,
				"happiness": 3,
				"cup": 1,
				"business": 2,
				"soft": 1,
				"games": 1,
				"truly": 2,
				"hill": 1,
				"daughter": 2,
				"loud": 1,
				"catch": 1,
				"etc.": 4,
				"everyday": 3,
				"throw": 1,
				"drop": 1,
				"sleeping": 2,
				"slow": 1,
				"safe": 1,
				"slowly": 2,
				"shore": 1,
				"ran": 1,
				"parents": 2,
				"hey": 1,
				"promise": 2,
				"master": 2,
				"themselves": 2,
				"party": 2,
				"below": 2,
				"path": 1,
				"picture": 2,
				"sign": 1,
				"drunk": 1,
				"middle": 2,
				"cast": 1,
				"share": 1,
				"tea": 1,
				"view": 1,
				"perhaps": 2,
				"battle": 2,
				"won": 1,
				"needed": 2,
				"'twas": 1,
				"space": 1,
				"telling": 2,
				"fucked": 1,
				"grass": 1,
				"ride": 1,
				"sounds": 1,
				"lights": 1,
				"quick": 1,
				"apart": 2,
				"filled": 1,
				"choose": 1,
				"indeed": 2,
				"seriously": 4,
				"blessed": 1,
				"four": 1,
				"kinda": 2,
				"step": 1,
				"date": 1,
				"taste": 1,
				"smoke": 1,
				"nay": 1,
				"rich": 1,
				"Sunday": 2,
				"wood": 1,
				"replied": 2,
				"fame": 1,
				"album": 2,
				"behold": 2,
				"weird": 1,
				"blow": 1,
				"yo": 1,
				"exactly": 3,
				"yours": 1,
				"fool": 1,
				"lead": 1,
				"God's": 1,
				"began": 2,
				"rock": 1,
				"definitely": 4,
				"watched": 1,
				"ugly": 2,
				"changed": 1,
				"works": 1,
				"grew": 1,
				"couple": 2,
				"top": 1,
				"sin": 1,
				"important": 3,
				"happens": 2,
				"sought": 1,
				"whose": 1,
				"waking": 2,
				"gift": 1,
				"loving": 2,
				"mighty": 2,
				"therefore": 2,
				"itself": 2,
				"birds": 1,
				"calling": 2,
				"pick": 1,
				"alive": 2,
				"shalt": 1,
				"dude": 1,
				"fact": 1,
				"quiet": 2,
				"law": 1,
				"secret": 2,
				"shadows": 2,
				"singing": 2,
				"brings": 1,
				"type": 1,
				"unless": 2,
				"flower": 2,
				"cat": 1,
				"treat": 1,
				"caught": 1,
				"floor": 1,
				"bout": 1,
				"moving": 2,
				"strange": 1,
				"dress": 1,
				"shot": 1,
				"turns": 1,
				"lived": 1,
				"realize": 3,
				"ring": 1,
				"expect": 2,
				"support": 2,
				"pictures": 2,
				"respect": 2,
				"aren't": 2,
				"losing": 2,
				"prayer": 1,
				"heavy": 2,
				"keeps": 1,
				"reach": 1,
				"flight": 1,
				"waste": 1,
				"flame": 1,
				"piece": 1,
				"afternoon": 3,
				"fled": 1,
				"often": 2,
				"putting": 2,
				"Monday": 2,
				"draw": 1,
				"anybody": 4,
				"deal": 1,
				"dinner": 2,
				"nap": 1,
				"desire": 3,
				"college": 2,
				"plain": 1,
				"ear": 1,
				"dad": 1,
				"kept": 1,
				"attention": 3,
				"fan": 1,
				"media": 3,
				"scent": 1,
				"skin": 1,
				"reading": 2,
				"awake": 2,
				"pity": 2,
				"lo": 1,
				"luck": 1,
				"we'll": 1,
				"gym": 1,
				"wearing": 2,
				"blind": 1,
				"chill": 1,
				"annoying": 3,
				"led": 1,
				"bought": 1,
				"crown": 1,
				"skies": 1,
				"force": 1,
				"burn": 1,
				"taken": 2,
				"brave": 1,
				"walking": 2,
				"lonely": 2,
				"thousand": 2
			}
		self.uncompress ={ 
				"a": "END",
				"b": "START",
				"c": "\n",
				"d": "the",
				"e": "I",
				"f": "to",
				"g": "and",
				"h": "a",
				"i": "of",
				"j": "you",
				"k": "in",
				"l": "my",
				"m": "is",
				"n": "for",
				"o": "me",
				"p": "it",
				"q": "that",
				"r": "on",
				"s": "with",
				"t": "this",
				"u": "be",
				"v": "so",
				"w": "but",
				"x": "not",
				"y": "he",
				"z": "all",
				"A": "have",
				"B": "was",
				"C": "I'm",
				"D": "his",
				"E": "are",
				"F": "they",
				"G": "your",
				"H": "at",
				"I": "just",
				"J": "like",
				"K": "as",
				"L": "when",
				"M": "we",
				"N": "her",
				"O": "what",
				"P": "if",
				"Q": "from",
				"R": "one",
				"S": "no",
				"T": "do",
				"U": "will",
				"V": "up",
				"W": "love",
				"X": "now",
				"Y": "don't",
				"Z": "out",
				"0": "can",
				"1": "she",
				"2": "get",
				"3": "how",
				"4": "day",
				"5": "know",
				"6": "by",
				"7": "who",
				"8": "people",
				"9": "go",
				"aa": "there",
				"ab": "time",
				"ac": "him",
				"ad": "it's",
				"ae": "about",
				"af": "never",
				"ag": "then",
				"ah": "really",
				"ai": "or",
				"aj": "good",
				"ak": "more",
				"al": "them",
				"am": "see",
				"an": "their",
				"ao": "life",
				"ap": "an",
				"aq": "had",
				"ar": "has",
				"as": "would",
				"at": "want",
				"au": "make",
				"av": "am",
				"aw": "only",
				"ax": "back",
				"ay": "still",
				"az": "too",
				"aA": "why",
				"aB": "here",
				"aC": "some",
				"aD": "man",
				"aE": "come",
				"aF": "going",
				"aG": "said",
				"aH": "been",
				"aI": "let",
				"aJ": "night",
				"aK": "can't",
				"aL": "than",
				"aM": "need",
				"aN": "ever",
				"aO": "much",
				"aP": "think",
				"aQ": "were",
				"aR": "thy",
				"aS": "way",
				"aT": "down",
				"aU": "our",
				"aV": "again",
				"aW": "always",
				"aX": "someone",
				"aY": "even",
				"aZ": "God",
				"a0": "heart",
				"a1": "got",
				"a2": "us",
				"a3": "say",
				"a4": "did",
				"a5": "today",
				"a6": "thou",
				"a7": "where",
				"a8": "right",
				"a9": "shit",
				"ba": "take",
				"bb": "feel",
				"bc": "should",
				"bd": "well",
				"be": "shall",
				"bf": "over",
				"bg": "wanna",
				"bh": "before",
				"bi": "off",
				"bj": "could",
				"bk": "last",
				"bl": "happy",
				"bm": "new",
				"bn": "things",
				"bo": "thee",
				"bp": "yet",
				"bq": "work",
				"br": "into",
				"bs": "long",
				"bt": "away",
				"bu": "through",
				"bv": "these",
				"bw": "first",
				"bx": "May",
				"by": "better",
				"bz": "gonna",
				"bA": "little",
				"bB": "best",
				"bC": "give",
				"bD": "I've",
				"bE": "every",
				"bF": "tell",
				"bG": "world",
				"bH": "look",
				"bI": "thing",
				"bJ": "its",
				"bK": "because",
				"bL": "being",
				"bM": "must",
				"bN": "eyes",
				"bO": "home",
				"bP": "you're",
				"bQ": "lol",
				"bR": "I'll",
				"bS": "made",
				"bT": "great",
				"bU": "nothing",
				"bV": "old",
				"bW": "year",
				"bX": "that's",
				"bY": "many",
				"bZ": "im",
				"b0": "such",
				"b1": "morning",
				"b2": "which",
				"b3": "myself",
				"b4": "upon",
				"b5": "keep",
				"b6": "after",
				"b7": "sleep",
				"b8": "something",
				"b9": "hope",
				"ca": "fuck",
				"cb": "other",
				"cc": "came",
				"cd": "while",
				"ce": "thought",
				"cf": "find",
				"cg": "very",
				"ch": "done",
				"ci": "oh",
				"cj": "hate",
				"ck": "face",
				"cl": "own",
				"cm": "two",
				"cn": "getting",
				"co": "men",
				"cp": "end",
				"cq": "light",
				"cr": "once",
				"cs": "please",
				"ct": "does",
				"cu": "any",
				"cv": "hand",
				"cw": "friends",
				"cx": "bad",
				"cy": "u",
				"cz": "those",
				"cA": "didn't",
				"cB": "head",
				"cC": "trying",
				"cD": "stop",
				"cE": "next",
				"cF": "makes",
				"cG": "put",
				"cH": "dead",
				"cI": "everything",
				"cJ": "death",
				"cK": "hear",
				"cL": "everyone",
				"cM": "alone",
				"cN": "sometimes",
				"cO": "most",
				"cP": "same",
				"cQ": "far",
				"cR": "around",
				"cS": "went",
				"cT": "wish",
				"cU": "days",
				"cV": "person",
				"cW": "left",
				"cX": "anyone",
				"cY": "might",
				"cZ": "though",
				"c0": "doing",
				"c1": "hard",
				"c2": "fucking",
				"c3": "live",
				"c4": "o",
				"c5": "place",
				"c6": "friend",
				"c7": "name",
				"c8": "mind",
				"c9": "each",
				"da": "wait",
				"db": "house",
				"dc": "care",
				"dd": "white",
				"de": "believe",
				"df": "watch",
				"dg": "song",
				"dh": "y'all",
				"di": "having",
				"dj": "rest",
				"dk": "gotta",
				"dl": "soul",
				"dm": "call",
				"dn": "nor",
				"do": "full",
				"dp": "leave",
				"dq": "game",
				"dr": "thus",
				"ds": "sweet",
				"dt": "sun",
				"du": "show",
				"dv": "without",
				"dw": "die",
				"dx": "gone",
				"dy": "another",
				"dz": "earth",
				"dA": "soon",
				"dB": "thank",
				"dC": "there's",
				"dD": "hair",
				"dE": "doesn't",
				"dF": "high",
				"dG": "rain",
				"dH": "bed",
				"dI": "baby",
				"dJ": "enough",
				"dK": "cause",
				"dL": "mine",
				"dM": "play",
				"dN": "heard",
				"dO": "girl",
				"dP": "money",
				"dQ": "moon",
				"dR": "words",
				"dS": "stay",
				"dT": "talk",
				"dU": "saw",
				"dV": "ass",
				"dW": "ready",
				"dX": "looking",
				"dY": "king",
				"dZ": "tonight",
				"d0": "christmas",
				"d1": "feeling",
				"d2": "already",
				"d3": "since",
				"d4": "week",
				"d5": "tomorrow",
				"d6": "help",
				"d7": "lord",
				"d8": "seen",
				"d9": "until",
				"ea": "fall",
				"eb": "tired",
				"ec": "knew",
				"ed": "start",
				"ee": "comes",
				"ef": "true",
				"eg": "cannot",
				"eh": "sky",
				"ei": "years",
				"ej": "else",
				"ek": "cold",
				"el": "music",
				"em": "coming",
				"en": "wind",
				"eo": "found",
				"ep": "whole",
				"eq": "try",
				"er": "summer",
				"es": "lost",
				"et": "sure",
				"eu": "remember",
				"ev": "till",
				"ew": "sad",
				"ex": "ain't",
				"ey": "black",
				"ez": "hands",
				"eA": "anything",
				"eB": "yourself",
				"eC": "real",
				"eD": "miss",
				"eE": "told",
				"eF": "both",
				"eG": "school",
				"eH": "cry",
				"eI": "eat",
				"eJ": "change",
				"eK": "fair",
				"eL": "took",
				"eM": "ask",
				"eN": "wonder",
				"eO": "side",
				"eP": "mother",
				"eQ": "dear",
				"eR": "beautiful",
				"eS": "'tis",
				"eT": "wrong",
				"eU": "sorry",
				"eV": "gave",
				"eW": "lot",
				"eX": "red",
				"eY": "under",
				"eZ": "literally",
				"e0": "Twitter",
				"e1": "turn",
				"e2": "fear",
				"e3": "speak",
				"e4": "also",
				"e5": "peace",
				"e6": "mean",
				"e7": "heaven",
				"e8": "free",
				"e9": "round",
				"fa": "sea",
				"fb": "part",
				"fc": "spring",
				"fd": "yes",
				"fe": "okay",
				"ff": "hour",
				"fg": "he's",
				"fh": "making",
				"fi": "art",
				"fj": "winter",
				"fk": "word",
				"fl": "break",
				"fm": "looks",
				"fn": "voice",
				"fo": "hold",
				"fp": "snow",
				"fq": "watching",
				"fr": "read",
				"fs": "bitch",
				"ft": "together",
				"fu": "bring",
				"fv": "son",
				"fw": "ye",
				"fx": "none",
				"fy": "pain",
				"fz": "family",
				"fA": "hell",
				"fB": "child",
				"fC": "truth",
				"fD": "late",
				"fE": "won't",
				"fF": "dream",
				"fG": "water",
				"fH": "thanks",
				"fI": "big",
				"fJ": "set",
				"fK": "half",
				"fL": "against",
				"fM": "forget",
				"fN": "lay",
				"fO": "dark",
				"fP": "maybe",
				"fQ": "follow",
				"fR": "fire",
				"fS": "deep",
				"fT": "woman",
				"fU": "kind",
				"fV": "pretty",
				"fW": "tears",
				"fX": "young",
				"fY": "actually",
				"fZ": "within",
				"f0": "blue",
				"f1": "listen",
				"f2": "wanted",
				"f3": "air",
				"f4": "birthday",
				"f5": "reason",
				"f6": "sound",
				"f7": "honestly",
				"f8": "haven't",
				"f9": "room",
				"ga": "feet",
				"gb": "open",
				"gc": "boy",
				"gd": "stand",
				"ge": "needs",
				"gf": "thinking",
				"gg": "joy",
				"gh": "I'd",
				"gi": "leaves",
				"gj": "use",
				"gk": "loved",
				"gl": "matter",
				"gm": "door",
				"gn": "behind",
				"go": "between",
				"gp": "knows",
				"gq": "women",
				"gr": "damn",
				"gs": "few",
				"gt": "win",
				"gu": "power",
				"gv": "meet",
				"gw": "waiting",
				"gx": "finally",
				"gy": "fight",
				"gz": "ok",
				"gA": "three",
				"gB": "close",
				"gC": "past",
				"gD": "talking",
				"gE": "what's",
				"gF": "times",
				"gG": "land",
				"gH": "lie",
				"gI": "near",
				"gJ": "pass",
				"gK": "run",
				"gL": "early",
				"gM": "move",
				"gN": "food",
				"gO": "understand",
				"gP": "fell",
				"gQ": "thine",
				"gR": "ah",
				"gS": "nice",
				"gT": "goes",
				"gU": "above",
				"gV": "excited",
				"gW": "war",
				"gX": "crazy",
				"gY": "says",
				"gZ": "body",
				"g0": "smile",
				"g1": "turned",
				"g2": "used",
				"g3": "father",
				"g4": "pray",
				"g5": "sick",
				"g6": "stars",
				"g7": "blood",
				"g8": "fun",
				"g9": "trust",
				"ha": "wow",
				"hb": "car",
				"hc": "guess",
				"hd": "whom",
				"he": "phone",
				"hf": "forth",
				"hg": "guys",
				"hh": "others",
				"hi": "nobody",
				"hj": "isn't",
				"hk": "dog",
				"hl": "sing",
				"hm": "tree",
				"hn": "rose",
				"ho": "lose",
				"hp": "saying",
				"hq": "taking",
				"hr": "gold",
				"hs": "hot",
				"ht": "children",
				"hu": "moment",
				"hv": "line",
				"hw": "drink",
				"hx": "eye",
				"hy": "wants",
				"hz": "learn",
				"hA": "seems",
				"hB": "you'll",
				"hC": "playing",
				"hD": "weekend",
				"hE": "poor",
				"hF": "o'er",
				"hG": "felt",
				"hH": "living",
				"hI": "wake",
				"hJ": "cried",
				"hK": "lady",
				"hL": "green",
				"hM": "worst",
				"hN": "almost",
				"hO": "anymore",
				"hP": "looked",
				"hQ": "book",
				"hR": "working",
				"hS": "mad",
				"hT": "hurt",
				"hU": "arms",
				"hV": "vain",
				"hW": "walk",
				"hX": "glad",
				"hY": "answer",
				"hZ": "mom",
				"h0": "save",
				"h1": "called",
				"h2": "himself",
				"h3": "dreams",
				"h4": "stood",
				"h5": "beauty",
				"h6": "died",
				"h7": "silence",
				"h8": "gets",
				"h9": "pay",
				"ia": "bright",
				"ib": "tweet",
				"ic": "buy",
				"id": "somebody",
				"ie": "along",
				"if": "fast",
				"ig": "strong",
				"ih": "worth",
				"ii": "evening",
				"ij": "sit",
				"ik": "season",
				"il": "city",
				"im": "point",
				"in": "bear",
				"io": "autumn",
				"ip": "amazing",
				"iq": "probably",
				"ir": "story",
				"is": "question",
				"it": "met",
				"iu": "less",
				"iv": "crying",
				"iw": "sir",
				"ix": "least",
				"iy": "forgot",
				"iz": "seeing",
				"iA": "brother",
				"iB": "return",
				"iC": "hath",
				"iD": "beneath",
				"iE": "thoughts",
				"iF": "funny",
				"iG": "second",
				"iH": "let's",
				"iI": "among",
				"iJ": "wife",
				"iK": "proud",
				"iL": "deserve",
				"iM": "hit",
				"iN": "hours",
				"iO": "send",
				"iP": "takes",
				"iQ": "they're",
				"iR": "job",
				"iS": "low",
				"iT": "ya",
				"iU": "brought",
				"iV": "cool",
				"iW": "imagine",
				"iX": "wine",
				"iY": "star",
				"iZ": "either",
				"i0": "sight",
				"i1": "cut",
				"i2": "forever",
				"i3": "asked",
				"i4": "we're",
				"i5": "kiss",
				"i6": "gods",
				"i7": "broke",
				"i8": "beat",
				"i9": "guy",
				"ja": "born",
				"jb": "small",
				"jc": "known",
				"jd": "different",
				"je": "window",
				"jf": "across",
				"jg": "holy",
				"jh": "movie",
				"ji": "girls",
				"jj": "swear",
				"jk": "touch",
				"jl": "lies",
				"jm": "feels",
				"jn": "rather",
				"jo": "queen",
				"jp": "flowers",
				"jq": "single",
				"jr": "fine",
				"js": "breast",
				"jt": "grow",
				"ju": "lips",
				"jv": "passed",
				"jw": "clear",
				"jx": "weather",
				"jy": "unto",
				"jz": "news",
				"jA": "course",
				"jB": "instead",
				"jC": "wild",
				"jD": "started",
				"jE": "longer",
				"jF": "wasn't",
				"jG": "beyond",
				"jH": "class",
				"jI": "breath",
				"jJ": "straight",
				"jK": "outside",
				"jL": "wings",
				"jM": "short",
				"jN": "everybody",
				"jO": "strength",
				"jP": "she's",
				"jQ": "sense",
				"jR": "warm",
				"jS": "trees",
				"jT": "clouds",
				"jU": "happen",
				"jV": "forward",
				"jW": "asleep",
				"jX": "songs",
				"jY": "month",
				"jZ": "laugh",
				"j0": "wide",
				"j1": "rise",
				"j2": "town",
				"j3": "video",
				"j4": "woke",
				"j5": "wear",
				"j6": "grave",
				"j7": "country",
				"j8": "kill",
				"j9": "sent",
				"ka": "kids",
				"kb": "fate",
				"kc": "supposed",
				"kd": "faith",
				"ke": "loves",
				"kf": "road",
				"kg": "seem",
				"kh": "easy",
				"ki": "mood",
				"kj": "listening",
				"kk": "Trump",
				"kl": "seek",
				"km": "inside",
				"kn": "lives",
				"ko": "coffee",
				"kp": "ones",
				"kq": "spirit",
				"kr": "able",
				"ks": "self",
				"kt": "fly",
				"ku": "wise",
				"kv": "ago",
				"kw": "state",
				"kx": "worse",
				"ky": "team",
				"kz": "means",
				"kA": "sat",
				"kB": "beside",
				"kC": "become",
				"kD": "human",
				"kE": "act",
				"kF": "wouldn't",
				"kG": "starting",
				"kH": "dawn",
				"kI": "bit",
				"kJ": "write",
				"kK": "future",
				"kL": "ways",
				"kM": "perfect",
				"kN": "stuff",
				"kO": "broken",
				"kP": "cute",
				"kQ": "stupid",
				"kR": "drive",
				"kS": "sister",
				"kT": "favorite",
				"kU": "shadow",
				"kV": "yeah",
				"kW": "wall",
				"kX": "ground",
				"kY": "falling",
				"kZ": "mouth",
				"k0": "held",
				"k1": "grief",
				"k2": "Friday",
				"k3": "post",
				"k4": "happened",
				"k5": "super",
				"k6": "couldn't",
				"k7": "heat",
				"k8": "bitches",
				"k9": "street",
				"la": "tried",
				"lb": "boys",
				"lc": "youth",
				"ld": "field",
				"le": "garden",
				"lf": "gives",
				"lg": "hearts",
				"lh": "sorrow",
				"li": "giving",
				"lj": "ere",
				"lk": "later",
				"ll": "merry",
				"lm": "grace",
				"ln": "idea",
				"lo": "you've",
				"lp": "train",
				"lq": "ice",
				"lr": "order",
				"ls": "bird",
				"lt": "praise",
				"lu": "afraid",
				"lv": "stream",
				"lw": "shame",
				"lx": "golden",
				"ly": "spoke",
				"lz": "laid",
				"lA": "silent",
				"lB": "woe",
				"lC": "seemed",
				"lD": "enjoy",
				"lE": "darkness",
				"lF": "given",
				"lG": "age",
				"lH": "glory",
				"lI": "check",
				"lJ": "asking",
				"lK": "eating",
				"lL": "dust",
				"lM": "storm",
				"lN": "chance",
				"lO": "yesterday",
				"lP": "shut",
				"lQ": "form",
				"lR": "dying",
				"lS": "dance",
				"lT": "account",
				"lU": "empty",
				"lV": "spake",
				"lW": "bless",
				"lX": "stone",
				"lY": "weep",
				"lZ": "race",
				"l0": "social",
				"l1": "front",
				"l2": "alas",
				"l3": "doubt",
				"l4": "running",
				"l5": "welcome",
				"l6": "problem",
				"l7": "sitting",
				"l8": "nature",
				"l9": "pride",
				"ma": "feelings",
				"mb": "smell",
				"mc": "river",
				"md": "whatever",
				"me": "hast",
				"mf": "Jesus",
				"mg": "knowing",
				"mh": "writing",
				"mi": "meant",
				"mj": "quite",
				"mk": "evil",
				"ml": "happiness",
				"mm": "cup",
				"mn": "business",
				"mo": "soft",
				"mp": "games",
				"mq": "truly",
				"mr": "hill",
				"ms": "daughter",
				"mt": "loud",
				"mu": "catch",
				"mv": "etc.",
				"mw": "everyday",
				"mx": "throw",
				"my": "drop",
				"mz": "sleeping",
				"mA": "slow",
				"mB": "safe",
				"mC": "slowly",
				"mD": "shore",
				"mE": "ran",
				"mF": "parents",
				"mG": "hey",
				"mH": "promise",
				"mI": "master",
				"mJ": "themselves",
				"mK": "party",
				"mL": "below",
				"mM": "path",
				"mN": "picture",
				"mO": "sign",
				"mP": "drunk",
				"mQ": "middle",
				"mR": "cast",
				"mS": "share",
				"mT": "tea",
				"mU": "view",
				"mV": "perhaps",
				"mW": "battle",
				"mX": "won",
				"mY": "needed",
				"mZ": "'twas",
				"m0": "space",
				"m1": "telling",
				"m2": "fucked",
				"m3": "grass",
				"m4": "ride",
				"m5": "sounds",
				"m6": "lights",
				"m7": "quick",
				"m8": "apart",
				"m9": "filled",
				"na": "choose",
				"nb": "indeed",
				"nc": "seriously",
				"nd": "blessed",
				"ne": "four",
				"nf": "kinda",
				"ng": "step",
				"nh": "date",
				"ni": "taste",
				"nj": "smoke",
				"nk": "nay",
				"nl": "rich",
				"nm": "Sunday",
				"nn": "wood",
				"no": "replied",
				"np": "fame",
				"nq": "album",
				"nr": "behold",
				"ns": "weird",
				"nt": "blow",
				"nu": "yo",
				"nv": "exactly",
				"nw": "yours",
				"nx": "fool",
				"ny": "lead",
				"nz": "God's",
				"nA": "began",
				"nB": "rock",
				"nC": "definitely",
				"nD": "watched",
				"nE": "ugly",
				"nF": "changed",
				"nG": "works",
				"nH": "grew",
				"nI": "couple",
				"nJ": "top",
				"nK": "sin",
				"nL": "important",
				"nM": "happens",
				"nN": "sought",
				"nO": "whose",
				"nP": "waking",
				"nQ": "gift",
				"nR": "loving",
				"nS": "mighty",
				"nT": "therefore",
				"nU": "itself",
				"nV": "birds",
				"nW": "calling",
				"nX": "pick",
				"nY": "alive",
				"nZ": "shalt",
				"n0": "dude",
				"n1": "fact",
				"n2": "quiet",
				"n3": "law",
				"n4": "secret",
				"n5": "shadows",
				"n6": "singing",
				"n7": "brings",
				"n8": "type",
				"n9": "unless",
				"oa": "flower",
				"ob": "cat",
				"oc": "treat",
				"od": "caught",
				"oe": "floor",
				"of": "bout",
				"og": "moving",
				"oh": "strange",
				"oi": "dress",
				"oj": "shot",
				"ok": "turns",
				"ol": "lived",
				"om": "realize",
				"on": "ring",
				"oo": "expect",
				"op": "support",
				"oq": "pictures",
				"or": "respect",
				"os": "aren't",
				"ot": "losing",
				"ou": "prayer",
				"ov": "heavy",
				"ow": "keeps",
				"ox": "reach",
				"oy": "flight",
				"oz": "waste",
				"oA": "flame",
				"oB": "piece",
				"oC": "afternoon",
				"oD": "fled",
				"oE": "often",
				"oF": "putting",
				"oG": "Monday",
				"oH": "draw",
				"oI": "anybody",
				"oJ": "deal",
				"oK": "dinner",
				"oL": "nap",
				"oM": "desire",
				"oN": "college",
				"oO": "plain",
				"oP": "ear",
				"oQ": "dad",
				"oR": "kept",
				"oS": "attention",
				"oT": "fan",
				"oU": "media",
				"oV": "scent",
				"oW": "skin",
				"oX": "reading",
				"oY": "awake",
				"oZ": "pity",
				"o0": "lo",
				"o1": "luck",
				"o2": "we'll",
				"o3": "gym",
				"o4": "wearing",
				"o5": "blind",
				"o6": "chill",
				"o7": "annoying",
				"o8": "led",
				"o9": "bought",
				"pa": "crown",
				"pb": "skies",
				"pc": "force",
				"pd": "burn",
				"pe": "taken",
				"pf": "brave",
				"pg": "walking",
				"ph": "lonely",
				"pi": "thousand"
			}
	}
}