AccountController = RouteController.extend
	verifyMail: -> Accounts.verifyEmail @params.token, ->
		Router.go "app"
		notify "Email geverifiëerd", "success"

forceRemoveModal = ->
	$("body").removeClass "modal-open"
	$(".modal-backdrop").remove()

Router.configure
	onStop: forceRemoveModal
	trackPageView: true
	notFoundTemplate: "notFound"
	loadingTemplate: "loading"

Router.map ->
	@route "launchPage",
		path: "/"
		layoutTemplate: "launchPage"
		onBeforeAction: ->
			Meteor.defer => @redirect "app" if Meteor.user()? or Meteor.loggingIn()
			@next()
		onAfterAction: ->
			document.title = "simplyHomework"
		fastRender: true

	@route "app",
		waitOn: -> NProgress.start(); Meteor.subscribe("essentials")

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "overview"
			document.title = "simplyHomework | #{Meteor.user().profile.firstName} #{Meteor.user().profile.lastName}"

			#App.followSetupPath()

			NProgress.done()

		layoutTemplate: "app"
		template: "appOverview"

	@route "classView",
		layoutTemplate: "app"
		path: "/app/view/:classId"

		subscriptions: -> NProgress.start(); Meteor.subscribe("essentials")

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				Template.sidebar.rendered = -> $(".slider").velocity top: 0, 150
				swalert title: "Niet gevonden", text: "Jij hebt dit vak waarschijnlijk niet.", confirmButtonText: "o.", type: "error"
				return
			Meteor.defer => slide @data()._id.toHexString()
			document.title = "simplyHomework | #{@data()._name}"
			NProgress.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.classId
				return classes().smartFind id, (c) -> c._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given class. #{e.message} | stack: #{e.stack}"
				return null

	@route "projectView",
		layoutTemplate: "app"
		path: "/app/project/:projectId"

		subscriptions: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("projects"), Meteor.subscribe("usersData") ]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				Template.sidebar.rendered = -> $(".slider").velocity top: "75px", 150
				swalert title: "Niet gevonden", text: "Dit project is niet gevonden.", type: "error"
				return

			Meteor.defer => slide @data().currentProject.__class._id.toHexString()
			document.title = "simplyHomework | #{@data().currentProject._name}"
			NProgress.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.projectId
				return projects().smartFind id, (p) -> p._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given project. #{e.message} | stack: #{e.stack}"
				return null

	@route "calendar",
		layoutTemplate: "app"
		path: "/app/calendar"

		subscriptions: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("usersData") ]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "calendar"
			document.title = "simplyHomework | Agenda"
			NProgress.done()

	@route "mobileCalendar",
		layoutTemplate: "app"
		path: "/app/mobileCalendar/:date?"

		subscriptions: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("usersData") ]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "calendar"
			document.title = "simplyHomework | Agenda"
			NProgress.done()

		data: -> if params.date? then new Date(params.date).date() else Date.today()

	@route "personView",
		layoutTemplate: "app"
		path: "/app/person/:_id"

		subscriptions: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("usersData") ]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "overview"
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Dit persoon is niet gevonden.", type: "error"
				return

			document.title = "simplyHomework | #{@data().profile.firstName} #{@data().profile.lastName}"
			NProgress.done()

		data: ->
			try
				return Meteor.users.findOne @params._id
			catch
				return null

	@route "beta",
		layoutTemplate: "beta"
		onBeforeAction: ->
			Meteor.subscribe("betaPeople")
			@next()
		onAfterAction: -> document.title = "simplyHomework | Bèta"

	@route "press",
		layoutTemplate: "press"
		onAfterAction: -> document.title = "simplyHomework | Pers"

	@route "admin",
		layoutTemplate: "admin"

	@route "verifyMail",
		path: "/verify/:token"
		controller: AccountController
		action: "verifyMail"

	@route "forgotPass",
		path: "/forgot"
		layoutTemplate: "forgotPass"

	@route "resetPass",
		path: "/reset/:token"
		layoutTemplate: "resetPass"

	@route "full",
		layoutTemplate: "full"