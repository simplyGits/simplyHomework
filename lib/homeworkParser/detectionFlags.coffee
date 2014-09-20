# Regular Expressions to detect a chapter.
@ChapterExps = [ /((chapter|unit):? ?\d+)|(\d+th (CHAPTER|UNIT))/ig      # English
	/(kapitel:? ?\d+)|(\d+\. KAPITEL)/ig                                 # German
	/((unit(e|é)|chapitre):? ?\d+)|(\d+eme (chapitre|unité|unite))/ig    # French
	/(((\bHO?O?F?D?S?T?U?K?[\.:]?)|(\bH[OOFDSTUK]{8,9}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bHO?O?F?D?S?T?U?K?\b\.?)/ig # Dutch
]

# Regular Expressions to detect a paragraph
@ParagraphExps = [ /§ ?[0-9]+/ig
	/(((\bPA?R?A?G?R?A?A?F?[\.:]?)|(\bP[ARAGRAAF]{8,9}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bPA?R?A?G?R?A?A?F?\b\.?)/ig # I have no idea what the fuck I'm doing.
]

# Regular Expressions to detect a page description. Example: "pagina 525"
@PageExps = [
	/(((\bBL?A?D?Z?I?J?D?E?S?[\.:]?)|(\bB[LADZIJDES]{8,10}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bBL?A?D?Z?I?J?D?E?\b\.?)/ig # Dutch
	/(((\bPA?G?I?N?A?S?[\.:]?)|(\bP[AGINAS]{5,7}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bPA?G?I?N?A?\b\.?)/ig # Dutch
]