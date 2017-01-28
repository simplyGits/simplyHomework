if Meteor.isClient
	moment.locale 'nl'

	TimeSync.loggingEnabled = no

Meteor.startup ->
	Accounts.config
		sendVerificationEmail: yes
