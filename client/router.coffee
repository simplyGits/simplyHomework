AccountController = RouteController.extend
	verifyMail: -> Accounts.verifyEmail @params.token, -> Router.go "app"

forceRemoveModal = ->
	$("body").removeClass "modal-open"
	$(".modal-backdrop").remove()

Router.configure
	onStop: forceRemoveModal
	trackPageView: true
	notFoundTemplate: "notFound"
	loadingTemplate: "loading"

Router.onBeforeAction('loading')

Router.map ->
	@route "launchPage",
		path: "/"
		layoutTemplate: "launchPage"
		onBeforeAction: -> Meteor.defer => @redirect "app" if Meteor.user()? or Meteor.loggingIn()
		onAfterAction: ->
			document.title = "simplyHomework"
		fastRender: true

	@route "app",
		waitOn: -> NProgress.start(); Meteor.subscribe("essentials")

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
		onAfterAction: ->
			Meteor.defer -> $(".slider").velocity top: 0, 150 #lolwat
			document.title = "simplyHomework | #{Meteor.user().profile.firstName} #{Meteor.user().profile.lastName}"

			#App.firstTimeSetup() if !Meteor.user().completedTutorial

			NProgress.done()

		layoutTemplate: "app"
		template: "appOverview"

	@route "classView",
		layoutTemplate: "app"
		path: "/app/view/:classId"

		waitOn: -> NProgress.start(); Meteor.subscribe("essentials")

		onBeforeAction: -> Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
		onAfterAction: ->
			if !@data().currentClass?
				@redirect "app"
				Template.sidebar.rendered = -> $(".slider").velocity top: 0, 150
				alertModal "Niet gevonden", "Jij hebt dit vak waarschijnlijk niet.", DialogButtons.Ok, main: "o."
				return
			Meteor.defer => $(".slider").velocity top: @data().currentClass.__pos * 60, 150
			document.title = "simplyHomework | #{@data().currentClass._name}"
			NProgress.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.classId
				return currentClass: classes().smartFind id, (c) -> c._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given class. #{e.message} | stack: #{e.stack}"
				return { currentClass: null }

	@route "projectView",
		layoutTemplate: "app"
		path: "/app/project/:projectId"

		waitOn: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("projects"), Meteor.subscribe("usersData") ]

		onBeforeAction: -> Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
		onAfterAction: ->
			if !@data().currentProject?
				@redirect "app"
				Template.sidebar.rendered = -> $(".slide").velocity top: 0, 150
				alertModal "Niet gevonden", "Dit project is niet gevonden."
				return

			Meteor.defer => $(".slider").velocity top: @data().currentProject.__class.__pos * 60, 150
			document.title = "simplyHomework | #{@data().currentProject._name}"
			NProgress.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.projectId
				return currentProject: projects().smartFind id, (p) -> p._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given project. #{e.message} | stack: #{e.stack}"
				return { currentProject: null }

	@route "calendar",
		layoutTemplate: "app"
		path: "/app/calendar"

		waitOn: -> NProgress.start(); [ Meteor.subscribe("essentials"), Meteor.subscribe("usersData") ]

		onBeforeAction: -> Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
		onAfterAction: ->
			Meteor.defer -> $(".slider").velocity top: 0, 150
			document.title = "simplyHomework | Agenda"
			NProgress.done()

	@route "beta",
		layoutTemplate: "beta"
		onBeforeAction: -> Meteor.subscribe("betaPeople")
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