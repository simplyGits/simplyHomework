###
@subs = new SubsManager
	cacheLimit: 40
	expireIn: 10
###

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
]

FlowRouter.route '/',
	name: 'launchPage'
	triggersEnter: [
		(context, redirect) ->
			redirect 'overview' if Meteor.userId()? or Meteor.loggingIn()
	]
	action: -> BlazeLayout.render 'launchPage'

FlowRouter.route '/verify/:token',
	name: 'verifyMail'
	action: (params) ->
		Accounts.verifyEmail params.token, ->
			FlowRouter.go 'overview'
			notify 'Email geverifiëerd', 'success'

FlowRouter.route '/forgot',
	name: 'forgotPass'
	action: -> BlazeLayout.render 'forgotPass'

FlowRouter.route '/reset/:token',
	name: 'resetPass'
	action: -> BlazeLayout.render 'resetPass'

appRoutes = FlowRouter.group
	prefix: '/app'
	name: 'app'
	triggersEnter: [
		(context, redirect) ->
			redirect 'launchPage' unless Meteor.userId()? or Meteor.loggingIn()

		(context, redirect) -> $('body').addClass 'noscroll'
	]
	triggersExit: [
		(context) -> $('body').removeClass 'noscroll'
	]

appRoutes.route '/',
	name: 'overview'
	action: -> renderAppTemplate 'overview'

appRoutes.route '/messages',
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
			if Session.equals 'deviceType', 'phone' then 'mobileCalendar'
			else 'calendar'
		)

appRoutes.route '/person/:id',
	name: 'personView'
	action: -> renderAppTemplate 'personView'

appRoutes.route '/chat/:id',
	name: 'mobileChat'
	action: -> renderAppTemplate 'mobileChatWindow'

appRoutes.route '/settings/:page?',
	name: 'settings'
	action: -> renderAppTemplate 'settings'
