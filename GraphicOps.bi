'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Common.bi'
'$INCLUDE:'Types.bi'

' 32-bit BGRA color constants based on HTML color names
CONST BGRA_ALICEBLUE~& = &HFFF0F8FF~&
CONST BGRA_ALMOND~& = &HFFEFDECD~&
CONST BGRA_ANTIQUEBRASS~& = &HFFCD9575~&
CONST BGRA_ANTIQUEWHITE~& = &HFFFAEBD7~&
CONST BGRA_APRICOT~& = &HFFFDD9B5~&
CONST BGRA_AQUA~& = &HFF00FFFF~&
CONST BGRA_AQUAMARINE~& = &HFF7FFFD4~&
CONST BGRA_ASPARAGUS~& = &HFF87A96B~&
CONST BGRA_ATOMICTANGERINE~& = &HFFFFA474~&
CONST BGRA_AZURE~& = &HFFF0FFFF~&
CONST BGRA_BANANAMANIA~& = &HFFFAE7B5~&
CONST BGRA_BEAVER~& = &HFF9F8170~&
CONST BGRA_BEIGE~& = &HFFF5F5DC~&
CONST BGRA_BISQUE~& = &HFFFFE4C4~&
CONST BGRA_BITTERSWEET~& = &HFFFD7C6E~&
CONST BGRA_BLACK~& = &HFF000000~&
CONST BGRA_BLANCHEDALMOND~& = &HFFFFEBCD~&
CONST BGRA_BLIZZARDBLUE~& = &HFFACE5EE~&
CONST BGRA_BLUE~& = &HFF0000FF~&
CONST BGRA_BLUEBELL~& = &HFFA2A2D0~&
CONST BGRA_BLUEGRAY~& = &HFF6699CC~&
CONST BGRA_BLUEGREEN~& = &HFF0D98BA~&
CONST BGRA_BLUEVIOLET~& = &HFF8A2BE2~&
CONST BGRA_BLUSH~& = &HFFDE5D83~&
CONST BGRA_BRICKRED~& = &HFFCB4154~&
CONST BGRA_BROWN~& = &HFFA52A2A~&
CONST BGRA_BURLYWOOD~& = &HFFDEB887~&
CONST BGRA_BURNTORANGE~& = &HFFFF7F49~&
CONST BGRA_BURNTSIENNA~& = &HFFEA7E5D~&
CONST BGRA_CADETBLUE~& = &HFF5F9EA0~&
CONST BGRA_CANARY~& = &HFFFFFF99~&
CONST BGRA_CARIBBEANGREEN~& = &HFF1CD3A2~&
CONST BGRA_CARNATIONPINK~& = &HFFFFAACC~&
CONST BGRA_CERISE~& = &HFFDD4492~&
CONST BGRA_CERULEAN~& = &HFF1DACD6~&
CONST BGRA_CHARTREUSE~& = &HFF7FFF00~&
CONST BGRA_CHESTNUT~& = &HFFBC5D58~&
CONST BGRA_CHOCOLATE~& = &HFFD2691E~&
CONST BGRA_COPPER~& = &HFFDD9475~&
CONST BGRA_CORAL~& = &HFFFF7F50~&
CONST BGRA_CORNFLOWER~& = &HFF9ACEEB~&
CONST BGRA_CORNFLOWERBLUE~& = &HFF6495ED~&
CONST BGRA_CORNSILK~& = &HFFFFF8DC~&
CONST BGRA_COTTONCANDY~& = &HFFFFBCD9~&
CONST BGRA_CRAYOLAAQUAMARINE~& = &HFF78DBE2~&
CONST BGRA_CRAYOLABLUE~& = &HFF1F75FE~&
CONST BGRA_CRAYOLABLUEVIOLET~& = &HFF7366BD~&
CONST BGRA_CRAYOLABROWN~& = &HFFB4674D~&
CONST BGRA_CRAYOLACADETBLUE~& = &HFFB0B7C6~&
CONST BGRA_CRAYOLAFORESTGREEN~& = &HFF6DAE81~&
CONST BGRA_CRAYOLAGOLD~& = &HFFE7C697~&
CONST BGRA_CRAYOLAGOLDENROD~& = &HFFFCD975~&
CONST BGRA_CRAYOLAGRAY~& = &HFF95918C~&
CONST BGRA_CRAYOLAGREEN~& = &HFF1CAC78~&
CONST BGRA_CRAYOLAGREENYELLOW~& = &HFFF0E891~&
CONST BGRA_CRAYOLAINDIGO~& = &HFF5D76CB~&
CONST BGRA_CRAYOLALAVENDER~& = &HFFFCB4D5~&
CONST BGRA_CRAYOLAMAGENTA~& = &HFFF664AF~&
CONST BGRA_CRAYOLAMAROON~& = &HFFC8385A~&
CONST BGRA_CRAYOLAMIDNIGHTBLUE~& = &HFF1A4876~&
CONST BGRA_CRAYOLAORANGE~& = &HFFFF7538~&
CONST BGRA_CRAYOLAORANGERED~& = &HFFFF2B2B~&
CONST BGRA_CRAYOLAORCHID~& = &HFFE6A8D7~&
CONST BGRA_CRAYOLAPLUM~& = &HFF8E4585~&
CONST BGRA_CRAYOLARED~& = &HFFEE204D~&
CONST BGRA_CRAYOLASALMON~& = &HFFFF9BAA~&
CONST BGRA_CRAYOLASEAGREEN~& = &HFF9FE2BF~&
CONST BGRA_CRAYOLASILVER~& = &HFFCDC5C2~&
CONST BGRA_CRAYOLASKYBLUE~& = &HFF80DAEB~&
CONST BGRA_CRAYOLASPRINGGREEN~& = &HFFECEABE~&
CONST BGRA_CRAYOLATANN~& = &HFFFAA76C~&
CONST BGRA_CRAYOLATHISTLE~& = &HFFEBC7DF~&
CONST BGRA_CRAYOLAVIOLET~& = &HFF926EAE~&
CONST BGRA_CRAYOLAYELLOW~& = &HFFFCE883~&
CONST BGRA_CRAYOLAYELLOWGREEN~& = &HFFC5E384~&
CONST BGRA_CRIMSON~& = &HFFDC143C~&
CONST BGRA_CYAN~& = &HFF00FFFF~&
CONST BGRA_DANDELION~& = &HFFFDDB6D~&
CONST BGRA_DARKBLUE~& = &HFF00008B~&
CONST BGRA_DARKCYAN~& = &HFF008B8B~&
CONST BGRA_DARKGOLDENROD~& = &HFFB8860B~&
CONST BGRA_DARKGRAY~& = &HFFA9A9A9~&
CONST BGRA_DARKGREEN~& = &HFF006400~&
CONST BGRA_DARKKHAKI~& = &HFFBDB76B~&
CONST BGRA_DARKMAGENTA~& = &HFF8B008B~&
CONST BGRA_DARKOLIVEGREEN~& = &HFF556B2F~&
CONST BGRA_DARKORANGE~& = &HFFFF8C00~&
CONST BGRA_DARKORCHID~& = &HFF9932CC~&
CONST BGRA_DARKRED~& = &HFF8B0000~&
CONST BGRA_DARKSALMON~& = &HFFE9967A~&
CONST BGRA_DARKSEAGREEN~& = &HFF8FBC8F~&
CONST BGRA_DARKSLATEBLUE~& = &HFF483D8B~&
CONST BGRA_DARKSLATEGRAY~& = &HFF2F4F4F~&
CONST BGRA_DARKTURQUOISE~& = &HFF00CED1~&
CONST BGRA_DARKVIOLET~& = &HFF9400D3~&
CONST BGRA_DEEPPINK~& = &HFFFF1493~&
CONST BGRA_DEEPSKYBLUE~& = &HFF00BFFF~&
CONST BGRA_DENIM~& = &HFF2B6CC4~&
CONST BGRA_DESERTSAND~& = &HFFEFCDB8~&
CONST BGRA_DIMGRAY~& = &HFF696969~&
CONST BGRA_DODGERBLUE~& = &HFF1E90FF~&
CONST BGRA_EGGPLANT~& = &HFF6E5160~&
CONST BGRA_ELECTRICLIME~& = &HFFCEFF1D~&
CONST BGRA_FERN~& = &HFF71BC78~&
CONST BGRA_FIREBRICK~& = &HFFB22222~&
CONST BGRA_FLORALWHITE~& = &HFFFFFAF0~&
CONST BGRA_FORESTGREEN~& = &HFF228B22~&
CONST BGRA_FUCHSIA~& = &HFFC364C5~&
CONST BGRA_FUZZYWUZZY~& = &HFFCC6666~&
CONST BGRA_GAINSBORO~& = &HFFDCDCDC~&
CONST BGRA_GHOSTWHITE~& = &HFFF8F8FF~&
CONST BGRA_GOLD~& = &HFFFFD700~&
CONST BGRA_GOLDENROD~& = &HFFDAA520~&
CONST BGRA_GRANNYSMITHAPPLE~& = &HFFA8E4A0~&
CONST BGRA_GRAY~& = &HFF808080~&
CONST BGRA_GREEN~& = &HFF008000~&
CONST BGRA_GREENBLUE~& = &HFF1164B4~&
CONST BGRA_GREENYELLOW~& = &HFFADFF2F~&
CONST BGRA_HONEYDEW~& = &HFFF0FFF0~&
CONST BGRA_HOTMAGENTA~& = &HFFFF1DCE~&
CONST BGRA_HOTPINK~& = &HFFFF69B4~&
CONST BGRA_INCHWORM~& = &HFFB2EC5D~&
CONST BGRA_INDIANRED~& = &HFFCD5C5C~&
CONST BGRA_INDIGO~& = &HFF4B0082~&
CONST BGRA_IVORY~& = &HFFFFFFF0~&
CONST BGRA_JAZZBERRYJAM~& = &HFFCA3767~&
CONST BGRA_JUNGLEGREEN~& = &HFF3BB08F~&
CONST BGRA_KHAKI~& = &HFFF0E68C~&
CONST BGRA_LASERLEMON~& = &HFFFEFE22~&
CONST BGRA_LAVENDER~& = &HFFE6E6FA~&
CONST BGRA_LAVENDERBLUSH~& = &HFFFFF0F5~&
CONST BGRA_LAWNGREEN~& = &HFF7CFC00~&
CONST BGRA_LEMONCHIFFON~& = &HFFFFFACD~&
CONST BGRA_LEMONYELLOW~& = &HFFFFF44F~&
CONST BGRA_LIGHTBLUE~& = &HFFADD8E6~&
CONST BGRA_LIGHTCORAL~& = &HFFF08080~&
CONST BGRA_LIGHTCYAN~& = &HFFE0FFFF~&
CONST BGRA_LIGHTGOLDENRODYELLOW~& = &HFFFAFAD2~&
CONST BGRA_LIGHTGRAY~& = &HFFD3D3D3~&
CONST BGRA_LIGHTGREEN~& = &HFF90EE90~&
CONST BGRA_LIGHTPINK~& = &HFFFFB6C1~&
CONST BGRA_LIGHTSALMON~& = &HFFFFA07A~&
CONST BGRA_LIGHTSEAGREEN~& = &HFF20B2AA~&
CONST BGRA_LIGHTSKYBLUE~& = &HFF87CEFA~&
CONST BGRA_LIGHTSLATEGRAY~& = &HFF778899~&
CONST BGRA_LIGHTSTEELBLUE~& = &HFFB0C4DE~&
CONST BGRA_LIGHTYELLOW~& = &HFFFFFFE0~&
CONST BGRA_LIME~& = &HFF00FF00~&
CONST BGRA_LIMEGREEN~& = &HFF32CD32~&
CONST BGRA_LINEN~& = &HFFFAF0E6~&
CONST BGRA_MACARONIANDCHEESE~& = &HFFFFBD88~&
CONST BGRA_MAGENTA~& = &HFFFF00FF~&
CONST BGRA_MAGICMINT~& = &HFFAAF0D1~&
CONST BGRA_MAHOGANY~& = &HFFCD4A4C~&
CONST BGRA_MAIZE~& = &HFFEDD19C~&
CONST BGRA_MANATEE~& = &HFF979AAA~&
CONST BGRA_MANGOTANGO~& = &HFFFF8243~&
CONST BGRA_MAROON~& = &HFF800000~&
CONST BGRA_MAUVELOUS~& = &HFFEF98AA~&
CONST BGRA_MEDIUMAQUAMARINE~& = &HFF66CDAA~&
CONST BGRA_MEDIUMBLUE~& = &HFF0000CD~&
CONST BGRA_MEDIUMORCHID~& = &HFFBA55D3~&
CONST BGRA_MEDIUMPURPLE~& = &HFF9370DB~&
CONST BGRA_MEDIUMSEAGREEN~& = &HFF3CB371~&
CONST BGRA_MEDIUMSLATEBLUE~& = &HFF7B68EE~&
CONST BGRA_MEDIUMSPRINGGREEN~& = &HFF00FA9A~&
CONST BGRA_MEDIUMTURQUOISE~& = &HFF48D1CC~&
CONST BGRA_MEDIUMVIOLETRED~& = &HFFC71585~&
CONST BGRA_MELON~& = &HFFFDBCB4~&
CONST BGRA_MIDNIGHTBLUE~& = &HFF191970~&
CONST BGRA_MINTCREAM~& = &HFFF5FFFA~&
CONST BGRA_MISTYROSE~& = &HFFFFE4E1~&
CONST BGRA_MOCCASIN~& = &HFFFFE4B5~&
CONST BGRA_MOUNTAINMEADOW~& = &HFF30BA8F~&
CONST BGRA_MULBERRY~& = &HFFC54B8C~&
CONST BGRA_NAVAJOWHITE~& = &HFFFFDEAD~&
CONST BGRA_NAVY~& = &HFF000080~&
CONST BGRA_NAVYBLUE~& = &HFF1974D2~&
CONST BGRA_NEONCARROT~& = &HFFFFA343~&
CONST BGRA_OLDLACE~& = &HFFFDF5E6~&
CONST BGRA_OLIVE~& = &HFF808000~&
CONST BGRA_OLIVEDRAB~& = &HFF6B8E23~&
CONST BGRA_OLIVEGREEN~& = &HFFBAB86C~&
CONST BGRA_ORANGE~& = &HFFFFA500~&
CONST BGRA_ORANGERED~& = &HFFFF4500~&
CONST BGRA_ORANGEYELLOW~& = &HFFF8D568~&
CONST BGRA_ORCHID~& = &HFFDA70D6~&
CONST BGRA_OUTERSPACE~& = &HFF414A4C~&
CONST BGRA_OUTRAGEOUSORANGE~& = &HFFFF6E4A~&
CONST BGRA_PACIFICBLUE~& = &HFF1CA9C9~&
CONST BGRA_PALEGOLDENROD~& = &HFFEEE8AA~&
CONST BGRA_PALEGREEN~& = &HFF98FB98~&
CONST BGRA_PALETURQUOISE~& = &HFFAFEEEE~&
CONST BGRA_PALEVIOLETRED~& = &HFFDB7093~&
CONST BGRA_PAPAYAWHIP~& = &HFFFFEFD5~&
CONST BGRA_PEACH~& = &HFFFFCFAB~&
CONST BGRA_PEACHPUFF~& = &HFFFFDAB9~&
CONST BGRA_PERIWINKLE~& = &HFFC5D0E6~&
CONST BGRA_PERU~& = &HFFCD853F~&
CONST BGRA_PIGGYPINK~& = &HFFFDDDE6~&
CONST BGRA_PINEGREEN~& = &HFF158078~&
CONST BGRA_PINK~& = &HFFFFC0CB~&
CONST BGRA_PINKFLAMINGO~& = &HFFFC74FD~&
CONST BGRA_PINKSHERBET~& = &HFFF78FA7~&
CONST BGRA_PLUM~& = &HFFDDA0DD~&
CONST BGRA_POWDERBLUE~& = &HFFB0E0E6~&
CONST BGRA_PURPLE~& = &HFF800080~&
CONST BGRA_PURPLEHEART~& = &HFF7442C8~&
CONST BGRA_PURPLEMOUNTAINSMAJESTY~& = &HFF9D81BA~&
CONST BGRA_PURPLEPIZZAZZ~& = &HFFFE4EDA~&
CONST BGRA_RADICALRED~& = &HFFFF496C~&
CONST BGRA_RAWSIENNA~& = &HFFD68A59~&
CONST BGRA_RAWUMBER~& = &HFF714B23~&
CONST BGRA_RAZZLEDAZZLEROSE~& = &HFFFF48D0~&
CONST BGRA_RAZZMATAZZ~& = &HFFE3256B~&
CONST BGRA_RED~& = &HFFFF0000~&
CONST BGRA_REDORANGE~& = &HFFFF5349~&
CONST BGRA_REDVIOLET~& = &HFFC0448F~&
CONST BGRA_ROBINSEGGBLUE~& = &HFF1FCECB~&
CONST BGRA_ROSYBROWN~& = &HFFBC8F8F~&
CONST BGRA_ROYALBLUE~& = &HFF4169E1~&
CONST BGRA_ROYALPURPLE~& = &HFF7851A9~&
CONST BGRA_SADDLEBROWN~& = &HFF8B4513~&
CONST BGRA_SALMON~& = &HFFFA8072~&
CONST BGRA_SANDYBROWN~& = &HFFF4A460~&
CONST BGRA_SCARLET~& = &HFFFC2847~&
CONST BGRA_SCREAMINGREEN~& = &HFF76FF7A~&
CONST BGRA_SEAGREEN~& = &HFF2E8B57~&
CONST BGRA_SEASHELL~& = &HFFFFF5EE~&
CONST BGRA_SEPIA~& = &HFFA5694F~&
CONST BGRA_SHADOW~& = &HFF8A795D~&
CONST BGRA_SHAMROCK~& = &HFF45CEA2~&
CONST BGRA_SHOCKINGPINK~& = &HFFFB7EFD~&
CONST BGRA_SIENNA~& = &HFFA0522D~&
CONST BGRA_SILVER~& = &HFFC0C0C0~&
CONST BGRA_SKYBLUE~& = &HFF87CEEB~&
CONST BGRA_SLATEBLUE~& = &HFF6A5ACD~&
CONST BGRA_SLATEGRAY~& = &HFF708090~&
CONST BGRA_SNOW~& = &HFFFFFAFA~&
CONST BGRA_SPRINGGREEN~& = &HFF00FF7F~&
CONST BGRA_STEELBLUE~& = &HFF4682B4~&
CONST BGRA_SUNGLOW~& = &HFFFFCF48~&
CONST BGRA_SUNSETORANGE~& = &HFFFD5E53~&
CONST BGRA_TANN~& = &HFFD2B48C~&
CONST BGRA_TEAL~& = &HFF008080~&
CONST BGRA_TEALBLUE~& = &HFF18A7B5~&
CONST BGRA_THISTLE~& = &HFFD8BFD8~&
CONST BGRA_TICKLEMEPINK~& = &HFFFC89AC~&
CONST BGRA_TIMBERWOLF~& = &HFFDBD7D2~&
CONST BGRA_TOMATO~& = &HFFFF6347~&
CONST BGRA_TROPICALRAINFOREST~& = &HFF17806D~&
CONST BGRA_TUMBLEWEED~& = &HFFDEAA88~&
CONST BGRA_TURQUOISE~& = &HFF40E0D0~&
CONST BGRA_TURQUOISEBLUE~& = &HFF77DDE7~&
CONST BGRA_UNMELLOWYELLOW~& = &HFFFFFF66~&
CONST BGRA_VIOLET~& = &HFFEE82EE~&
CONST BGRA_VIOLETBLUE~& = &HFF324AB2~&
CONST BGRA_VIOLETRED~& = &HFFF75394~&
CONST BGRA_VIVIDTANGERINE~& = &HFFFFA089~&
CONST BGRA_VIVIDVIOLET~& = &HFF8F509D~&
CONST BGRA_WHEAT~& = &HFFF5DEB3~&
CONST BGRA_WHITE~& = &HFFFFFFFF~&
CONST BGRA_WHITESMOKE~& = &HFFF5F5F5~&
CONST BGRA_WILDBLUEYONDER~& = &HFFA2ADD0~&
CONST BGRA_WILDSTRAWBERRY~& = &HFFFF43A4~&
CONST BGRA_WILDWATERMELON~& = &HFFFC6C85~&
CONST BGRA_WISTERIA~& = &HFFCDA4DE~&
CONST BGRA_YELLOW~& = &HFFFFFF00~&
CONST BGRA_YELLOWGREEN~& = &HFF9ACD32~&
CONST BGRA_YELLOWORANGE~& = &HFFFFAE42~&

' This matches the QB64 BGRA 32-bit style color for little endian systems
TYPE BGRAType
    b AS _UNSIGNED _BYTE
    g AS _UNSIGNED _BYTE
    r AS _UNSIGNED _BYTE
    a AS _UNSIGNED _BYTE
END TYPE

TYPE BGRType
    b AS _UNSIGNED _BYTE
    g AS _UNSIGNED _BYTE
    r AS _UNSIGNED _BYTE
END TYPE

DECLARE LIBRARY "GraphicOps"
    SUB Graphics_DrawPixel (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_MakeTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE, BYVAL fColor AS _UNSIGNED _BYTE, BYVAL bColor AS _UNSIGNED _BYTE)
    FUNCTION Graphics_MakeDefaultTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE)
    SUB Graphics_SetForegroundColor (BYVAL fColor AS _UNSIGNED LONG)
    FUNCTION Graphics_GetForegroundColor~&
    SUB Graphics_SetBackgroundColor (BYVAL bColor AS _UNSIGNED LONG)
    FUNCTION Graphics_GetBackgroundColor~&
    SUB Graphics_DrawHorizontalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawVerticalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawLine (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawEllipse (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL rx AS LONG, BYVAL ry AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledEllipse (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL rx AS LONG, BYVAL ry AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawTriangle (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL x3 AS LONG, BYVAL y3 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledTriangle (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL x3 AS LONG, BYVAL y3 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_MakeBGRA~& (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE, BYVAL a AS _UNSIGNED _BYTE)
    FUNCTION Graphics_MakeRGBA~& (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE, BYVAL a AS _UNSIGNED _BYTE)
    FUNCTION Graphics_GetRedFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetGreenFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetBlueFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetAlphaFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetRGB~& (BYVAL clr AS _UNSIGNED LONG)
    FUNCTION Graphics_SwapRedBlue~& (BYVAL clr AS _UNSIGNED LONG)
    SUB Graphics_SetTextImageClearColor (BYVAL imageHandle AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_PutTextImagePro ALIAS "Graphics_PutTextImage" (BYVAL imageHandle AS LONG, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG)
    SUB Graphics_PutTextImage (BYVAL imageHandle AS LONG, BYVAL x AS LONG, BYVAL y AS LONG)
    SUB Graphics_RenderASCIIArt (BYVAL srcImage AS LONG, BYVAL dstImage AS LONG)
    FUNCTION Graphics_FindClosestColor~& (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE, BYVAL palettePtr AS _UNSIGNED _OFFSET, BYVAL paletteColors AS _UNSIGNED LONG)
END DECLARE
