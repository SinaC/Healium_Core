local H, C, L = unpack(select(2,...))

H.myname = select(1, UnitName("player"))
H.myclass = select(2, UnitClass("player"))
H.client = GetLocale() 