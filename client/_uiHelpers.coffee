###
	   \|\/                        
	  _/;;\__                      
	,' /  \',";   <---- Onion      
   /  |    | \ \                   
   |  |    |  ||           ,-- HAND
	\  \   ; /,'           |       
	 '--^-^-^' _           v       
	,-._     ," '-,,___            
   ',_  '--,__'-,      '''--"      
   (  ''--,_  ''-^-''              
   ;''--,___''                     
  .'--,,__  ''                     
   ^._    '''             ,.--     
	  ''----________----''        

Art by Tom Smeding
http://tomsmeding.nl/
###

@DialogButtons =
	Ok: 0
	OkCancel: 1

@alertModal = (title, body, buttonType = 0, labels = { main: "oké", second: "annuleren" }, styles  = { main: "btn-default", second: "btn-default" }, callbacks = { main: null, second: null }, exitButton = yes) ->
	labels = _.extend { main: "oké", second: "annuleren" }, labels
	styles = _.extend { main: "btn-default", second: "btn-default" }, styles

	bootbox.dialog
		title: title
		message: body.replace /\n/ig, "<br>"
		onEscape: if buttonType isnt 0 then callbacks.second else if _.isFunction(callbacks.main) then callbacks.main else -> return
		buttons:
			switch buttonType
				when 0
					main:
						label: labels.main
						className: styles.main
						callback: ->
							if _.isFunction(callbacks.main) then callbacks.main()
							bootbox.hideAll()
				when 1
					main:
						label: labels.second
						className: styles.second
						callback: ->
							if _.isFunction(callbacks.second) then callbacks.second()
							bootbox.hideAll()
					second:
						label: labels.main
						className: styles.main
						callback: ->
							if _.isFunction(callbacks.main) then callbacks.main()
							bootbox.hideAll()

	$(".bootbox-close-button").remove() unless exitButton

@swalert = (options) ->
	throw new ArgumentException "options", "Can't be null" unless options?
	_.defaults options, { onSuccess: (->), onCancel: (->) }
	{ title, text, type, confirmButtonText, cancelButtonText, onSuccess, onCancel, html } = options

	swal {
		title
		text
		type
		confirmButtonText: confirmButtonText ? "oké"
		cancelButtonText
		allowOutsideClick: cancelButtonText?
		showCancelButton: cancelButtonText?
	}, (success) -> if success then onSuccess() else onCancel()

	if html? then $(".sweet-alert > p").html html.replace "\n", "<br>"

	return undefined

###*
# Checks if a given field is empty, if so returns true and displays an error message for the user.
#
# @method empty
# @param inputId {String} The ID of the field.
# @param groupId {String} The ID of the group of the field.
# @param message {String} The error message to show to the user.
# @return {Boolean} If the given field was empty.
###
@empty = (inputId, groupId, message) ->
	if $("##{inputId}").val() is ""
		$("##{groupId}").addClass("has-error").tooltip(placement: "bottom", title: message).tooltip("show")
		return true
	return false

@correctMail = (mail) -> /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i.test mail

@speak = (text) ->
	audio = new Audio
	audio.src = "http://www.ispeech.org/p/generic/getaudio?text=#{text}%2C&voice=eurdutchfemale&speed=0&action=convert"
	audio.play()

_text = null
@strikeThrough = (node, index) ->
	_text ?= node.text()
	return false if index >= _text.length

	sToStrike = _text.substr 0, index + 1
	sAfter = if index < --_text.length then _text.substr(index + 1, _text.length - index) else ""

	node.html '<span style="text-decoration: line-through" id="stroke">' + sToStrike + "</span>" + sAfter
	_.delay (->
		strikeThrough node, index + 1
	), 5

class @NotificationsManager
	@_notifications: []

	@notify = (options) ->
		throw new ArgumentException "options", "Can't be null" unless options?
		_.defaults options, { type: "default", time: 4000, dismissable: yes, labels: [], styles: [], callbacks: [], html: no, priority: 0, allowDesktopNotifications: yes, image: "" }
		{ body, type, time, dismissable, labels, styles, callbacks, html, onClick, priority, onDismissed, allowDesktopNotifications, image } = options

		check time, Match.Where (t) -> _.isNumber(t) and ( t is -1 or t > 0 )
		check priority, Number

		notId = NotificationsManager._notifications.length
		notHandle =
			_startedHiding: no
			_delayHandle: null
			_htmlNotification: null
			id: notId
			priority: priority
			hide: ->
				clearTimeout @_delayHandle
				if @_htmlNotification?
					@_htmlNotification.close()
					delete NotificationsManager._notifications[@id]
				else
					$(".notification##{notId}").removeClass "transformIn"
					@_startedHiding = yes
					_.delay ( =>
						$(".notification##{notId}").remove()
						delete NotificationsManager._notifications[@id]
					), 2000
					NotificationsManager._updatePositions()
			
			height: -> unless @_htmlNotification? then @element().outerHeight(yes) else 0
			
			content: (content, html = false) ->
				return if @_htmlNotification?
				if content?
					$(".notification##{notId} div").html (if html then body else _.escape body).replace /\n/g, "<br>"
					NotificationsManager._updatePositions()
					return content
				else
					return $(".notification##{notId} div")[if html then "html" else "text"]()
					
			element: -> $(".notification##{notId}")

		if document.hasFocus() or not allowDesktopNotifications or not Session.get "allowNotifications"
			d = $ document.createElement "div"
			d.addClass "notification #{type}"
			d.attr "id", notId
			d.html "<div>#{(if html then body else _.escape body).replace(/\n/g, "<br>")}</div>"
			d.append "<br>"
			if onClick?
				d.click ->
					if $(@).hasClass("noclick") then $(@).removeClass "noclick"
					else onClick arguments...
				d.css cursor: "pointer"

			if dismissable
				pos = null
				MIN = -200

				d.draggable
					axis: "x"
					start: (event, helper) ->
						pos = $(@).position().left
						$(@)
							.css width: $(this).outerWidth()
							.addClass "noclick"
					stop: (event, helper) ->
						$(@).css width: "initial"
						if $(@).position().left - pos > MIN
							$(@).css opacity: 1
						else
							$(@).velocity opacity: 0
							notHandle.hide()
							onDismissed?()
					drag: (event, helper) ->
						$(@).css opacity: 1 - ((pos - $(@).position().left) / 250)
					revert: -> $(@).position().left - pos > MIN

			for label, i in labels
				style = styles[i] ? "btn-default"
				btn = $.parseHTML "<button type=\"button\" class=\"btn #{style}\" id=\"#{notId}_#{i}\">#{label}</button>"

				callback = callbacks[i] ? (->)
				do (callback) -> btn[0].onclick = (event) -> callback event, notHandle
				
				d.append btn

			unless time is -1 # Handles that sick timeout, yo.
				hide = -> notHandle.hide()
				notHandle._delayHandle = _.delay hide, time + 500

				d.mouseover -> clearTimeout notHandle._delayHandle
				d.mouseleave -> notHandle._delayHandle = _.delay hide, time + 500

			$("body").append d

			_.delay ( -> $(".notification##{notId}").addClass "transformIn" ), 10

		else
			text = if html then body.trim().replace(/(<[^>]*>)|(&nbsp;)/g, "").replace("<br>", "\n") else body.trim()
			x = new Notification text.split("\n")[0], body: text.split("\n")[1..].join("\n"), tag: notId, icon: image
			notHandle._htmlNotification = x
			x.onclick = ->
				window.focus()
				onClick?()
				notHandle.hide()
			x.onclose = ->
				onDismissed?()
				notHandle.hide()

			unless time is -1 then notHandle._delayHandle = _.delay (-> notHandle.hide()), time + 500

		NotificationsManager._notifications.push notHandle
		NotificationsManager._updatePositions()

		return notHandle

	@notifications = -> _.filter NotificationsManager._notifications, (n) -> n? and not n._startedHiding

	@hideAll = -> x.hide() for x in NotificationsManager.notifications(); return undefined

	@_updatePositions = ->
		height = 0

		for notification, i in _.sortBy(_.reject(NotificationsManager.notifications(), (n) -> n._htmlNotification?).reverse(), "priority").reverse()
			notification.element().css top: height + 15
			height += notification.height() + 10

		return undefined

@notify = (body, type = "default", time = 4000, dismissable = yes, priority = 0) -> NotificationsManager.notify { body: "<b>#{_.escape body}</b>", type, time, dismissable, priority, html: yes, allowDesktopNotifications: no }

@gravatar = (userId = Meteor.userId(), size = 100) ->
	user = if _.isString(userId) then Meteor.users.findOne(userId) else userId
	if user.hasGravatar or _.isEmpty(user.profile.magisterPicture) then "#{user.gravatarUrl}&s=#{size}" else user.profile.magisterPicture

@slide = (id, isClass = no) ->
	targetHeight = $("div.sidebarButton##{id}").outerHeight yes

	$(".slider").css display: "none"
	if isClass
		$(".slider#classes").css(display: "initial").velocity {
			top: $("div.sidebarButton##{id}").position().top + $(".sidebarClasses").scrollTop()
			height: targetHeight + 5
		}, 150
	else
		$(".slider#global").css(display: "initial").velocity {
			top: $("div.sidebarButton##{id}").offset().top
			height: targetHeight + 5
		}, 150

	closeSidebar?()

Meteor.startup ->
	moment.locale "nl"

	Session.set "allowNotifications", no

	notification = null
	Deps.autorun ->
		if Meteor.user()? and htmlNotify.isSupported and !("ActiveXObject" of window)
			switch htmlNotify.permissionLevel()
				when "default"
					notification ?= notify "Als je bureaublad meldingen toestaat kan je overal meldingen van simplyHomework zien, zelfs als je op een ander tabblad zit.", null, -1, no, 9
					htmlNotify.requestPermission (result) ->
						notification?.hide()
						Session.set "allowNotifications", result is "granted"
				when "granted"
					notification?.hide()
					Session.set "allowNotifications", yes

	Session.set "isPhone", window.matchMedia("only screen and (max-width: 760px)").matches

	UI.registerHelper "isPhone", -> Session.get "isPhone"
	UI.registerHelper "empty", -> return @ is 0
	UI.registerHelper "first", (arr) -> EJSON.equals @, _.first arr
	UI.registerHelper "last", (arr) -> EJSON.equals @, _.last arr
	UI.registerHelper "minus", (base, substraction) -> base - substraction
	UI.registerHelper "gravatar", gravatar
	UI.registerHelper "has", (feature) -> has feature

	Meteor.defer -> Deps.autorun ->
		if Meteor.user()?
			$.get "#{Meteor.user().gravatarUrl}&s=1&d=404"
				.done -> Meteor.users.update Meteor.userId(), $set: hasGravatar: yes
				.fail -> Meteor.users.update Meteor.userId(), $set: hasGravatar: no

	disconnectedNotify = null
	_.delay ->
		Deps.autorun ->
			if Meteor.status().connected
				disconnectedNotify?.hide()
				disconnectedNotify = null
			else unless disconnectedNotify?
				disconnectedNotify = notify("Verbinding verbroken", "error", -1, no, 10)
	, 1200