local H, C, L = unpack(select(2, ...))

if H.client == "frFR" then
	L.GUID_ISNIL = "GUID non-valide pour l'unit\195\169 %s"
	L.INITIALIZE_PREDEFINEDLISTNOTFOUND = "La liste de sorts pr\195\169d\195\169finis n'a pas \195\169t\195\169 trouv\195\169e"
	L.INITIALIZE_PREDEFINEDIDNOTFOUND = "ID %s inexistant dans la liste de sorts pr\195\169d\195\169finis"
	L.CHECKSPELL_NOSPELLSFOUND = "Aucun sort configur\195\169 pour cette sp\195\169"
	L.CHECKSPELL_SPELLNOTLEARNED = "Le sort %s(%d) n'est pas connu"
	L.CHECKSPELL_SPELLNOTEXISTS = "Le sort %d n'existe pas"
	L.CHECKSPELL_MACRONOTFOUND = "La macro %s n'existe pas"
	L.TOOLTIP_UNKNOWNSPELL = "Sort %s(%d) inconnu"
	L.TOOLTIP_UNKNOWN_MACRO = "Macro %s inconnue"
	L.TOOLTIP_UNKNOWN = "Inconnu"
	L.TOOLTIP_MACRO = "Macro: |cFF00FFFF%s|r"
	L.TOOLTIP_TARGET = "Cible: |cFF00FF00%s|r"
	L.BUFFDEBUFF_TOOMANYBUFF = "Trop d'am\195\169liorations sur %s %s"
	L.BUFFDEBUFF_TOOMANYDEBUFF = "Trop d'affaiblissements sur %s %s"
	L.SETTINGS_UNKNOWNBUFFDEBUFF = "SpellID %d inconnu dans %s"
	L.SETTINGS_DUPLICATEBUFFDEBUFF = "SpellID %d et %d sont le m\195\170me buff/debuff (%s) dans %s"
	L.SPELLLIST_INCOMBAT = "Impossible de changer de settings lorsque vous \195\170tes en combat"
end