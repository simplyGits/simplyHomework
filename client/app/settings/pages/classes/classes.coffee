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
		updateUser = (mod) -> Meteor.users.update Meteor.userId(), mod
		updateUser $pull: classInfos: id: @_id
		updateUser $push: classInfos: _.extend @__classInfo, hidden: not current

Template['settings_page_classes'].onCreated ->
	@subscribe 'classes', hidden: yes
