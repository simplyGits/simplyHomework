# Regular Expressions to detect a chapter.
@ChapterExps = [ /((chapter|unit):? ?\d+)|(\d+th (CHAPTER|UNIT))/ig      # English
	/(kapitel:? ?\d+)|(\d+\. KAPITEL)/ig                                 # German
	/((unit(e|é)|chapitre):? ?\d+)|(\d+eme (chapitre|unité|unite))/ig    # French
	/(((\bHO?O?F?D?S?T?U?K?[\.:]?)|(\bH[OOFDSTUK]{8,9}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(ook|plus|tevens|en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bHO?O?F?D?S?T?U?K?\b\.?)/ig # Dutch
]

# Regular Expressions to detect a paragraph
@ParagraphExps = [ /§ ?\d+ ?(t[\/\\]?m|[-+,]|en|ook|tevens|plus) ?/ig
	/(((\bPA?R?A?G?R?A?A?F?[\.:]?)|(\bP[ARAGRAAF]{8,9}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bPA?R?A?G?R?A?A?F?\b\.?)/ig # I have no idea what the fuck I'm doing.
]

# Regular Expressions to detect an exercise
@ExerciseExps = [
	/^[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(ook|plus|tevens|en|tot (en met)?) ?[0-9]+))*$/img
	/(((\bOP?D?R?A?C?H?T?[\.:]?)|(\bO[PDRACHT]{7,8}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(ook|plus|tevens|en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bOP?D?R?A?C?H?T?\b\.?)/ig
	/(((\bOP?G?A?V?E?[\.:]?)|(\bO[PGAVE]{5,6}\b)) ?[\d]+(( ?t[\/\\]?m ?\d+)|( ?[-+,] ?[0-9]+)|( ?(ook|plus|tevens|en|tot (en met)?) ?[0-9]+))*)|(\b[0-9]{1,2}d?e \bOP?G?A?V?E?\b\.?)/ig
]
