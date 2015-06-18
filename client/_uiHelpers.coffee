###
      \|\/
     _/;;\__
   ,' /  \',";   <---- Onion
  /  |    | \ \
  |  |    |  ||          ,-- HAND
   \  \   ; /,'          |
    '--^-^-^'  _         v
   ,-._      ," '-,,___
  ',_  '--.,__'-,      '''--"
  (  ''--.,_  ''-^-''
  ;''--.,___''
 .'--.,,__  ''
  ^.,_    '''             ,.--
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
	{
		title
		text
		type
		confirmButtonText
		cancelButtonText
		onSuccess
		onCancel
		html
	} = options

	swal {
		title
		text
		type
		confirmButtonText: confirmButtonText ? "oké"
		cancelButtonText
		allowOutsideClick: cancelButtonText?
		showCancelButton: cancelButtonText?
	}, (success) -> if success then onSuccess?() else onCancel?()

	if html? then $(".sweet-alert > p").html html.replace "\n", "<br>"
	undefined

###*
# Sets the given `selector` to show an error state.
#
# @method setFieldError
# @param selector {jQuery|String} The thing to show on error on.
# @param message {String} The message to show as error.
# @param [trigger="manual"] {String} When to trigger the bootstrap tooltip.
# @param {jQuery} The given `selector`.
###
@setFieldError = (selector, message, trigger = "manual") ->
	(if selector.jquery? then selector else $(selector))
		.addClass "error"
		.tooltip placement: "bottom", title: message, trigger: trigger
		.tooltip "show"

	selector

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
		$("##{groupId}").addClass("error").tooltip(placement: "bottom", title: message).tooltip("show")
		return true
	return false

###*
# Force Beatrix to speak out the given `text`.
#
# @method speak
# @param text {String} The string to speak out.
###
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

###*
# The manager for notificafions.
# @class NotificationsManager
# @static
###
class @NotificationsManager
	@_notifications: []

	@notify = (options) ->
		throw new ArgumentException "options", "Can't be null" unless options?
		_.defaults options, { type: "default", time: 4000, dismissable: yes, labels: [], styles: [], callbacks: [], html: no, priority: 0, allowDesktopNotifications: yes, image: "" }
		{ body, type, time, dismissable, labels, styles, callbacks, html, onClick, priority, onDismissed, allowDesktopNotifications, image, onHide } = options

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
					_.remove NotificationsManager._notifications, @id
				else
					$notification = @element()
					$notification.removeClass "transformIn"
					@_startedHiding = yes
					_.delay ( =>
						$notification.remove()
						_.remove NotificationsManager._notifications, @id
					), 2000
					NotificationsManager._updatePositions()

			height: -> unless @_htmlNotification? then @element().outerHeight(yes) else 0

			content: (content, html = false) ->
				if @_htmlNotification? # We can't change the contents of a HTML notification, just rebuild it.
					@_htmlNotification.close()

					text = if html then body.trim().replace(/(<[^>]*>)|(&nbsp;)/g, "").replace("<br>", "\n") else body.trim()
					x = new Notification text.split("\n")[0], body: text.split("\n")[1..].join("\n"), tag: notId, icon: image
					notHandle._htmlNotification = x
					x.onclick = ->
						window.focus()
						onClick?()
						onHide?()
						notHandle.hide()
					x.onclose = ->
						onDismissed?()
						onHide?()
						notHandle.hide()

					return

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
					if $(this).hasClass("noclick") then $(this).removeClass "noclick"
					else
						onClick arguments...
						onHide?()
						notHandle.hide()
				d.css cursor: "pointer"

			if dismissable
				pos = null
				MIN = -200

				d.draggable
					axis: "x"
					start: (event, helper) ->
						$(this)
							.css width: $(this).outerWidth()
							.addClass "noclick"
					stop: (event, helper) ->
						$this = $ this
						if $this.position().left - pos > MIN
							$this.css
								width: "initial"
								opacity: 1
						else
							$this.velocity opacity: 0
							notHandle.hide()
							onDismissed?()
							onHide?()
					drag: (event, helper) ->
						$this = $ this
						$this.css opacity: 1 - ((pos - $this.position().left) / 250)
					revert: -> $(this).position().left - pos > MIN

			for label, i in labels
				style = styles[i] ? "btn-default"
				btn = $.parseHTML("<button type='button' class='btn #{style}' id='#{notId}_#{i}'>#{label}</button>")[0]

				callback = callbacks[i] ? (->)
				do (callback) -> btn.onclick = (event) -> callback event, notHandle

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
				onHide?()
				notHandle.hide()
			x.onclose = ->
				onDismissed?()
				onHide?()
				notHandle.hide()

			unless time is -1 then notHandle._delayHandle = _.delay (-> notHandle.hide()), time + 500

		NotificationsManager._notifications.push notHandle
		NotificationsManager._updatePositions()

		return notHandle

	@notifications = -> _.reject NotificationsManager._notifications, "_startedHiding"

	@hideAll = -> x.hide() for x in NotificationsManager.notifications(); return undefined

	@_updatePositions = ->
		height = 0

		for notification, i in _.sortBy(_.reject(NotificationsManager.notifications(), (n) -> n._htmlNotification?).reverse(), "priority").reverse()
			notification.element().css top: height + 15
			height += notification.height() + 10

		return undefined

###*
# Shortcut for basic NotificationManager.notify(...).
# @method notify
# @param body {String} The body of the notification.
# @param [type="default"] {String} The type of notification, could be "warning", "error", "notice", "success" and "default".
# @param [time=4000] {Number} The time in ms for how long the notification must at max stay, if -1 the notification doesnt hide.
# @param [dismissable=true] {Boolean} Whether or not this notification is dismissable.
# @param [priority=0] {Number} The priority of the notification.
###
@notify = (body, type = "default", time = 4000, dismissable = yes, priority = 0) -> NotificationsManager.notify { body: "<b>#{_.escape body}</b>", type, time, dismissable, priority, html: yes, allowDesktopNotifications: no }

###*
# Gets the gravatar url of the given `userId`.
# @method gravatar
# @param [userId=Meteor.userId()] {User|ObjectID} The object or ID of the user to get the gravatar from.
# @param [size=100] {Number} The size in pixels that the gravatar shall be.
# @return {String} A string containing the URL of the gravatar.
###
@gravatar = (userId = Meteor.userId(), size = 100) ->
	user = if _.isString(userId) then Meteor.users.findOne(userId) else userId
	if user.hasGravatar or _.isEmpty(user.profile.magisterPicture) then "#{user.gravatarUrl}&s=#{size}" else user.profile.magisterPicture

###*
# 'Slides' the slider to the given destanation.
# @method slide
# @param id {String} The ID of the `.sidebarButton` to slide to.
###
@slide = (id) ->
	$("div.sidebarButton.selected").removeClass "selected"
	$("div.sidebarButton##{id}").addClass "selected"

	closeSidebar?()

###*
# Start a animate.css shake animation on
# the elements which match the given selector.
# After the shake this method makes sure it can
# shake again. Shake it like it's hot! ;)
#
# @method shake
# @param selector {String} The selector of which elements to shake.
###
@shake = (selector) ->
	$(selector)
		.addClass "animated shake"
		.one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', -> $(this).removeClass "animated shake"

###*
# Set the current bigNotice.
# @method setBigNotice
# @param [options] {Object} The options object. If null the notice will be removed.
# @return {Object} An handle object: { hide, content, onClick, onDismissed }
###
@setBigNotice = (options) ->
	if options?
		check options, Object
		_.defaults options, { theme: "default", onClick: (->), onDismissed: (->), allowDismiss: yes }

		currentBigNotice.set options
		$("body").addClass "bigNoticeOpen"

		return {
			hide: -> setBigNotice null
			content: (content) ->
				if content?
					currentBigNotice.set _.extend currentBigNotice.get(), { content }
					return content
				else
					return currentBigNotice.get().content

			onClick: (callback) -> currentBigNotice.set _.extend currentBigNotice.get(), onClick: callback
			onDismissed: (callback) -> currentBigNotice.set _.extend currentBigNotice.get(), onDismissed: callback
		}
	else
		currentBigNotice.set null
		$("body").removeClass "bigNoticeOpen"
		return undefined

Meteor.startup ->
	Session.set "allowNotifications", no

	notification = null
	Tracker.autorun ->
		if Meteor.userId()? and htmlNotify.isSupported and !("ActiveXObject" of window)
			switch htmlNotify.permissionLevel()
				when "default"
					notification = setBigNotice
						content: "Wij hebben je toestemming nodig om bureaubladmeldingen weer te kunnen geven."
						onClick: ->
							htmlNotify.requestPermission (result) ->
								notification?.hide()
								Session.set "allowNotifications", result is "granted"
				when "granted"
					notification?.hide()
					Session.set "allowNotifications", yes

	Session.set "isPhone", window.matchMedia("only screen and (max-width: 760px)").matches or /android|iphone|ipod|blackberry|windows phone/i.test navigator.userAgent

	UI.registerHelper "isPhone", -> Session.get "isPhone"
	UI.registerHelper "empty", -> return this is 0
	UI.registerHelper "first", (arr) -> EJSON.equals this, _.first arr
	UI.registerHelper "last", (arr) -> EJSON.equals this, _.last arr
	UI.registerHelper "minus", (base, substraction) -> base - substraction
	UI.registerHelper "gravatar", gravatar
	UI.registerHelper "has", (feature) -> has feature

	# TODO: Remove the console.infos.
	disconnectedNotify = null
	_.delay ->
		Deps.autorun ->
			if Meteor.status().connected
				console.info("Reconnected.") if disconnectedNotify?

				disconnectedNotify?.hide()
				disconnectedNotify = null
			else unless disconnectedNotify?
				disconnectedNotify = notify("Verbinding verbroken", "error", -1, no, 10)
				console.info "Disconnected."
	, 1200
