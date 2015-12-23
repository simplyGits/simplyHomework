if Package['aldeed:collection2']?
	ChatMessages.attachSchema
		content:
			type: String
			max: 1000
		creatorId:
			type: String
			index: 1
			autoValue: -> if not @isFromTrustedCode and @isInsert then @userId
			denyUpdate: yes
		time:
			type: Date
			index: -1
			autoValue: -> if @isInsert then new Date()
			denyUpdate: yes
		chatRoomId:
			type: String
			index: 1
		readBy:
			type: [String]
			index: 1
			autoValue: -> if @isInsert then [@userId] else @value
		attachments:
			type: [String]
		changedOn:
			type: Date
			optional: yes

	ChatRooms.attachSchema
		type:
			type: String
			allowedValues: ['private', 'project', 'group']
		users:
			type: [String]
			index: 1
		projectId:
			type: String
			optional: yes
		subject:
			type: String
			optional: yes
			index: 1
		lastMessageTime:
			type: Date
			optional: yes
			index: 1
		events:
			type: [Object]
			blackbox: yes
