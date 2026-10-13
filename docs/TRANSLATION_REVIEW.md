# Translation review notes

Every language here is an AI draft (`ai_draft`), so the app shows it as beta. Each file was drafted, then blind back-translated into English by a separate pass and compared with the source. The rows below are where a native reviewer should look first. Rows marked "fixed" were changed after the back-translation check.

Across every language, a medical reviewer should check the emergency lines and `allergen.red_meat` (alpha-gal) against an official anaphylaxis action plan in that language.

## fr
- emergency.say_anaphylaxis: added "(choc anaphylactique)"; medical reviewer confirm
- allergen.red_meat: alpha-gal term unknown to staff; medical review
- cross_contact.garnish: "garniture" can mean side dish; "topping" anglicism
- cross_contact.grill: "plancha" vs "plaque de cuisson"
- shopping.dairy_free: "laits végétaux (boissons végétales)"
## de
- allergen.crustaceans: "Krabben" can mean small shrimp in N. Germany; crab must be explicit fixed: Taschenkrebse added
- allergen.red_meat: "Rotes Fleisch" not standard medical category
- hidden.nut_sauces: praliné rendered as Praliné-Masse (Krokant)
- allergen.msg: dropped "MSG", added E 621
- emergency lines: Krankenwagen (CH Ambulanz, AT Rettung); check vs German anaphylaxis action plan
## it
- generic "nuts" lines use "frutta a guscio" (excludes peanuts) fixed: added "arachidi" to cross_contact.bakery, question.dessert, question.bread, shopping.dairy_free (travel.airline_announce already had it)
- allergen.gelatin added "colla di pesce"
- sulphites/msg follow Italian label wording, E621
- red_meat alfa-gal wording: medical review
- emergency lines: check vs Italian anaphylaxis action plan
## zh-Hans
- emergency.say_anaphylaxis: 严重过敏反应（过敏性休克）; medical review
- red_meat: added 哺乳动物的肉 since pork may not count as 红肉
- almond 杏仁（巴旦木） (apricot kernel ambiguity); mustard 芥末（芥菜籽制成的黄芥末） (wasabi ambiguity)
- hidden.all_forms butter -> 黄油或抹酱
- egg 蛋类（包括鸡蛋） to cover duck/quail eggs
- onion 葱（小葱）/红葱头; crustaceans vs molluscs naming (贝类 = molluscs) checked: ids match (crustaceans = 甲壳类, molluscs = 贝类及软体类)
## zh-Hant-TW
- almond 杏仁果（美國杏仁） (杏仁 = apricot kernel); mustard 黃芥末（芥末籽） (芥末 = wasabi)
- say_anaphylaxis 全身性過敏反應（過敏性休克）; medical review
- red_meat wording, no settled lay term
- staff yes/no = 是/否 (有/沒有 more natural for "contains")
- butter 奶油 (牛油 can mean beef tallow); 沙嗲醬 distinct from 沙茶醬
## es
- 39 ids carry regional forms in brackets; walnut "nueces de Castilla" (MX nuez = pecan); "mantequilla (manteca)" (AR butter vs ES/MX lard); "(sin TACC)"
- red_meat alfa-gal term; medical review
- "Mariscos crustáceos"; bogavante/jaiba may need country overrides
- miso/hoisin as frijol/judías/porotos may read as ordinary beans -> "soja fermentada"?
- generic "nuts" = "frutos secos" (dried fruit ambiguity, peanuts unclear) fixed: added "cacahuetes (cacahuates, maní)" to the same four lines as it
- emergency lines: check vs Spanish anaphylaxis action plan
## pl
- allergen lines in accusative to follow "Mam alergię na:"; read oddly standalone
- red_meat spelled out as mięso ssaków (wołowina, wieprzowina, jagnięcina); medical review
- krewetki (małe i duże); czereśnie i wiśnie; Gorczycę (w tym musztardę)
- anafilaksja vs wstrząs anafilaktyczny; autoinjector vs ampułkostrzykawka; check vs Polish action plan
- buckwheat added kasza/mąka gryczana; msg E621
## pt / pt-BR
- pt-BR 62 override rows; "caneta" feminine for auto-injector
- nuts: PT "frutos de casca rija", BR "castanhas e nozes"
- BR crustaceans "camarão (pequeno ou grande)", "caranguejo, siri"
- PT onion "cebolinho (cebola verde)" (cebolinho = chives in PT)
- BR pine_nut "Pinoli (pinhões de pinheiro europeu)"
- emergency lines check vs INEM / SAMU; "obrigado(a)" speaker gender
## Back-translation check: de: no dangerous mismatches. "Walnüsse (Baumnüsse)": Baumnuss is the Swiss word for walnut, kept; reviewer confirm it doesn't read as "all tree nuts" in DE/AT.
## Back-translation check: it: no dangerous mismatches. Broader: gelatin incl. colla di pesce; "Noci" can mean nuts generally.
## Back-translation check: zh-Hans: fixed marzipan 杏仁粉 -> added （巴旦木粉）; mustard broadened to seed + sauce/powder/oil (was limited to yellow mustard). 海鲜酱 = "seafood sauce" literal (safe side).
## Back-translation check: fr: no dangerous mismatches. fruits à coque excludes peanuts (peanut own row); "pâte à frire" = frying batter only.
## Back-translation check: pl: no dangerous mismatches. chicken stock powder rendered as poultry stock powder (fine: English means chicken stock powder). question.same_oil says fried vs cooked.
## Back-translation check: es: fixed walnut -> "Nueces de nogal (nueces de Castilla)" (MX nuez = pecan); banana -> "Bananas (plátanos)". Remaining: frutos secos broad; "mantequilla (manteca)" adds lard reading in ES/MX; gelatina = jelly dessert; suero de leche = buttermilk in LatAm; plancha in ordering.simple vs cross_contact.grill.
## Back-translation check: zh-Hant-TW: fixed marzipan 杏仁 ambiguity (now 杏仁果粉（美國杏仁粉）). Remaining: hidden.all_forms paste/butter generalised; chicken 雞粉 only; 胡桃 pecan glossed.
## Back-translation check: yue-Hant: fixed tree_nuts/marzipan 杏仁 -> （扁桃仁）; mustard broadened; legumes 扁豆 -> 小扁豆; gelatin now says pork/beef/fish. Remaining: 敏感 vs 過敏; staff yes/no 係/唔係 vs 有/冇.
## Back-translation check: pt: fixed pan -> frigideira/tacho; mala -> mala de mão; pt-BR pine_nut no longer "European only". Remaining: cebolinho (cebola verde); pt-BR "traço".
