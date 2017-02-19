{ isPhone } = require 'meteor/device-type'

renderAppTemplate = (name) ->
	BlazeLayout.render 'app', main: name

@notFound = ->
	setPageOptions
		title: 'Niet gevonden'
		color: null

	template = 'notFound'
	if Meteor.userId()? or Meteor.loggingIn() then renderAppTemplate template
	else BlazeLayout.render template

FlowRouter.notFound = action: notFound

FlowRouter.triggers.exit [
	->
		$('.modal.in').modal 'hide'
		$('.modal-backdrop').remove()
		$('body').removeClass 'modal-open'
		$('.tooltip').tooltip 'destroy'
		$('.content').scrollTop 0
]

FlowRouter.route '/login',
	name: 'login'
	triggersEnter: [
		(context, redirect) ->
			redirect 'overview' if Meteor.userId()? or Meteor.loggingIn()
	]
	action: -> BlazeLayout.render 'login_signup'

FlowRouter.route '/signup',
	name: 'signup'
	triggersEnter: [
		(context, redirect) ->
			redirect 'overview' if Meteor.userId()? or Meteor.loggingIn()
	]
	action: -> BlazeLayout.render 'login_signup'

FlowRouter.route '/forgot',
	name: 'forgotPass'
	triggersEnter: [
		(context, redirect) ->
			redirect 'overview' if Meteor.userId()? or Meteor.loggingIn()
	]
	action: -> BlazeLayout.render 'login_signup'

FlowRouter.route '/verify/:token',
	name: 'verifyMail'
	action: (params) ->
		Accounts.verifyEmail params.token, ->
			FlowRouter.go 'overview'
			notify 'Email geverifiëerd', 'success'

FlowRouter.route '/reset/:token',
	name: 'resetPass'
	action: -> BlazeLayout.render 'resetPass'

appRoutes = FlowRouter.group
	name: 'app'
	triggersEnter: [
		(context, redirect) ->
			unless Meteor.userId()? or Meteor.loggingIn()
				document.location.href = 'https://simplyhomework.nl/'
	]

appRoutes.route '/',
	name: 'overview'
	action: -> renderAppTemplate 'overview'

appRoutes.route '/messages/compose',
	name: 'composeMessage'
	action: -> renderAppTemplate 'messages'

appRoutes.route '/messages/:folder?/:message?',
	name: 'messages'
	action: -> renderAppTemplate 'messages'

appRoutes.route '/class/:id',
	name: 'classView'
	action: -> renderAppTemplate 'classView'

appRoutes.route '/project/:id',
	name: 'projectView'
	action: -> renderAppTemplate 'projectView'

appRoutes.route '/calendar/:time?',
	name: 'calendar'
	action: ->
		renderAppTemplate (
			if isPhone() then 'mobileCalendar'
			else 'calendar'
		)

appRoutes.route '/person/:id',
	name: 'personView'
	action: -> renderAppTemplate 'personView'

appRoutes.route '/chat/:id',
	name: 'chat'
	triggersEnter: [
		(context, redirect) ->
			unless context.oldRoute?
				FlowRouter.go 'overview'
				FlowRouter.go 'chat', context.params
	]
	action: ->
		if isPhone()
			renderAppTemplate 'mobileChatWindow'

appRoutes.route '/grades',
	name: 'grades'
	action: -> renderAppTemplate 'gradesView'

appRoutes.route '/settings/:page?',
	name: 'settings'
	action: -> renderAppTemplate 'settings'
