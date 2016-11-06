Template['settings_page_classes'].helpers
	classes: ->
		Classes.find {
			_id: $in: _.pluck getClassInfos(), 'id'
		}, sort: 'name': 1

Template['settings_page_classes_row'].helpers
	hidden: -> if @__classInfo.hidden then 'hidden' else ''

Template['settings_page_classes_row'].events
	'click .fa': ->
		current = @__classInfo.hidden
		Meteor.call 'setClassHidden', @_id, not current

Template['settings_page_classes'].onCreated ->
	@subscribe 'classes', hidden: yes
