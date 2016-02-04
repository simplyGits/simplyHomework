if Package['aldeed:collection2']?
	ChatMessages.attachSchema
		content:
			type: String
			max: 1000
		creatorId:
			type: String
			autoValue: -> if not @isFromTrustedCode and @isInsert then @userId
			denyUpdate: yes
		time:
			type: Date
			autoValue: -> if @isInsert then new Date()
			denyUpdate: yes
		chatRoomId:
			type: String
		readBy:
			type: [String]
			autoValue: -> if @isInsert then [@userId] else @value
		attachments:
			type: [String]
		changedOn:
			type: Date
			optional: yes
		pending:
			type: Boolean
			optional: yes

	ChatRooms.attachSchema
		type:
			type: String
			allowedValues: ['private', 'project', 'group', 'class']
		users:
			type: [String]
		projectId:
			type: String
			optional: yes
		subject:
			type: String
			optional: yes
		lastMessageTime:
			type: Date
			optional: yes
		events:
			type: [Object]
			blackbox: yes
		classInfo:
			type: Object
			blackbox: yes
			optional: yes
