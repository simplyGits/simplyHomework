@subs = new SubsManager
	cacheLimit: 40
	expireIn: 10

AccountController = RouteController.extend
	verifyMail: ->
		Accounts.verifyEmail @params.token, =>
			Router.go "app"
			notify "Email geverifiëerd", "success"
			@next()

Router.configure
	onStop: ->
		$(".modal.in").modal "hide"
		$(".backdrop.dimmed").removeClass "dimmed"
		$(".tooltip").tooltip "destroy"
		$("body").removeClass "modal-open"
	trackPageView: true

Router.map ->
	@route "launchPage",
		fastRender: yes
		path: "/"
		layoutTemplate: "launchPage"
		onBeforeAction: ->
			Meteor.defer => @redirect "app" if Meteor.userId()? or Meteor.loggingIn()
			@next()
		onAfterAction: ->
			document.title = "simplyHomework"
			$("meta[name='theme-color']").attr "content", "#32A8CE"

	@route "app",
		fastRender: yes
		subscriptions: ->
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			subs.subscribe("calendarItems")
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "overview"
				$("meta[name='theme-color']").attr "content", "#32A8CE"

			document.title = (
				# When we don't have magister info yet the name is empty.
				unless _.isEmpty Meteor.user().profile.firstName
					"simplyHomework | #{Meteor.user().profile.firstName} #{Meteor.user().profile.lastName}"
				else
					"simplyHomework"
			)

			App.followSetupPath() if @ready()

		layoutTemplate: "app"
		template: "appOverview"

	@route "classView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/class/:classId"

		subscriptions: ->
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Je hebt dit vak waarschijnlijk niet.", confirmButtonText: "o.", type: "error"
				return

			Meteor.defer =>
				slide @data()._id.toHexString()
				$("meta[name='theme-color']").attr "content", @data().__color()

			document.title = "simplyHomework | #{@data().name}"

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.classId
				return Classes.findOne id, transform: classTransform
			catch e
				Kadira.trackError "Class-Search-Error", e.message, stacks: e.stack
				return null

	@route "projectView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/project/:projectId"

		subscriptions: ->
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("projects", new Meteor.Collection.ObjectID @params.projectId)
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			subs.subscribe("usersData", @data?()?.participants)
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Dit project is niet gevonden.", type: "error"
				return

			if @data().__class()? then Meteor.defer =>
				slide @data().__class()._id.toHexString()
				$("meta[name='theme-color']").attr "content", @data().__class().__color()

			document.title = "simplyHomework | #{@data().name}"

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.projectId
				return Projects.findOne id, transform: projectTransform
			catch e
				Kadira.trackError "Project-Search-Error", e.message, stacks: e.stack
				return null

	@route "calendar",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/calendar"

		subscriptions: ->
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			@redirect "mobileCalendar" if Session.get "isPhone"
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "calendar"
				$("meta[name='theme-color']").attr "content", "#32A8CE"

			document.title = "simplyHomework | Agenda"

	@route "mobileCalendar",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/mobileCalendar"

		subscriptions: ->
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			@redirect "calendar" unless Session.get "isPhone"
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "calendar"
				$("meta[name='theme-color']").attr "content", "#32A8CE"

			document.title = "simplyHomework | Agenda"

	@route "personView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/person/:_id"

		subscriptions: ->
			return [
				subs.subscribe("usersData", [ @params._id ])
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "overview"

			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Deze persoon is niet gevonden.", type: "error"
				return

			document.title = "simplyHomework | #{@data().profile.firstName} #{@data().profile.lastName}"

		data: -> Meteor.users.findOne @params._id

	@route "mobileChatWindow",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/chat/:_id"

		subscriptions: ->
			return [
				subs.subscribe("usersData", [ @params._id ])
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.userId()?
				@redirect "launchPage"
				return
			@redirect "app" unless Session.get "isPhone"
			@next()

		onAfterAction: ->
			Meteor.defer -> slide "overview"

			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Deze chat is niet gevonden.", type: "error"
				return

			document.title = "simplyHomework | #{@data().__friendlyName}"

		data: ->
			x = Meteor.users.findOne { _id: @params._id }, transform: userChatTransform
			x ?= Projects.findOne { _id: new Meteor.Collection.ObjectID @params._id }, transform: projectChatTransform
			return x

	@route "privacy",
		fastRender: yes
		layoutTemplate: "privacy"
		onAfterAction: ->
			document.title = "simplyHomework | Privacy"
			$("body").scrollTop 0

	@route "press",
		fastRender: yes
		layoutTemplate: "press"
		onAfterAction: ->
			document.title = "simplyHomework | Pers"
			$("body").scrollTop 0

	@route "verifyMail",
		fastRender: yes
		path: "/verify/:token"
		controller: AccountController
		action: "verifyMail"

	@route "forgotPass",
		fastRender: yes
		path: "/forgot"
		layoutTemplate: "forgotPass"

	@route "resetPass",
		fastRender: yes
		path: "/reset/:token"
		layoutTemplate: "resetPass"

Router.route "/(.*)", -> # 404 route.
	if @ready()
		document.title = "simplyHomework | Niet gevonden"
		@render "notFound"
