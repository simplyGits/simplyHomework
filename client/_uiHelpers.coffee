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
http://tomsmeding.com/
###

@DialogButtons =
	Ok: 0
	OkCancel: 1

@alertModal = (title, body, buttonType = 0, labels = { main: 'oké', second: 'annuleren' }, styles = { main: 'btn-default', second: 'btn-default' }, callbacks = { main: null, second: null }, exitButton = yes) ->
	labels = _.extend { main: 'Oké', second: 'Annuleren' }, labels
	styles = _.extend { main: 'btn-default', second: 'btn-default' }, styles

	bootbox.hideAll()

	bootbox.dialog
		title: title
		message: body.replace /\n/ig, '<br>'
		onEscape: (
			if buttonType is 0
				callbacks.second
			else if _.isFunction(callbacks.main)
				callbacks.main
		) ? (->)
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

	$('.bootbox-close-button').remove() unless exitButton
	undefined

@swalert = (options) ->
	check options, Object
	{ title
		text
		type
		confirmButtonText
		cancelButtonText
		onSuccess
		onCancel
		html } = options

	swal {
		title
		text
		type
		confirmButtonText: confirmButtonText ? 'Oké'
		cancelButtonText
		allowOutsideClick: cancelButtonText?
		showCancelButton: cancelButtonText?
	}, (success) -> if success then onSuccess?() else onCancel?()

	if html? then $('.sweet-alert > p').html html.replace '\n', '<br>'
	undefined

###*
# Sets the given `selector` to show an error state.
#
# @method setFieldError
# @param selector {jQuery|String} The thing to show an error on.
# @param message {String} The message to show as error.
# @param [trigger="manual"] {String} When to trigger the bootstrap tooltip.
# @param {jQuery} The given `selector`.
###
@setFieldError = (selector, message, trigger = 'manual') ->
	(if selector.jquery? then selector else $(selector))
		.addClass 'error'
		.tooltip placement: 'bottom', title: message, trigger: trigger
		.tooltip 'show'
		.on 'input change', ->
			$(this)
				.removeClass 'error'
				.tooltip 'destroy'

	selector

###*
# Checks if a given field is empty, if so returns true and displays an error message for the user.
#
# @method empty
# @param inputSelector {jQuery|String}
# @param groupSelector {jQuery|String}
# @param message {String} The error message to show to the user.
# @return {Boolean} If the given field was empty.
###
@empty = (inputSelector, groupSelector, message) ->
	$input = (if inputSelector.jquery? then inputSelector else $ inputSelector)
	$group = (if groupSelector.jquery? then groupSelector else $ groupSelector)

	if $input.val() is ''
		setFieldError $group, message
		yes
	else no

# TODO: Give this its own package
###*
# The manager for notificafions.
# @class NotificationsManager
# @static
###
class @NotificationsManager
	@_notifications: []

	# TODO: Make it possible to update the handlers using the notification handle?
	# TODO: Clean this method up. Please. (maybe use handlebars templates?)
	# TODO: `options.onHide` not called on timeout for onfocus notifications?
	@notify: (options) ->
		check options, Object
		_.defaults options,
			type: 'default'
			time: 4000
			dismissable: yes
			labels: []
			styles: []
			callbacks: []
			html: no
			priority: 0
			allowDesktopNotifications: yes
			image: ''
		{
			body, type, time, dismissable, labels, styles, callbacks, html, onClick, priority,
			onDismissed, allowDesktopNotifications, image, onHide
		} = options

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
				if @_htmlNotification? and content?
					# We can't change the contents of a HTML notification, just rebuild it.
					@_htmlNotification.close()

					text = (
						trimmed = body.trim()
						if html
							trimmed.replace(/(<[^>]*>)|(&nbsp;)/g, '').replace('<br>', '\n')
						else
							trimmed
					)
					notif = new Notification(
						text.split("\n")[0]
						{
							body: text.split("\n")[1..].join("\n")
							tag: notId
							icon: image
						}
					)
					notHandle._htmlNotification = notif
					notif.onclick = ->
						window.focus()
						onClick?()
						onHide?()
						notHandle.hide()
					notif.onclose = ->
						onDismissed?()
						onHide?()
						notHandle.hide()

					undefined
				else
					$content = $ ".notification##{notId} div"
					if content?
						$content.html (
							if html then body
							else _.escape body
						).replace /\n/g, "<br>"

						NotificationsManager._updatePositions()

					if html then $content.html()
					else $content.text()

			element: -> $ ".notification##{notId}"

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
						$this = $ this
						pos = $this.position().left
						$this
							.css width: $this.outerWidth()
							.addClass 'noclick'
					stop: (event, helper) ->
						$this = $ this
						if $this.position().left - pos > MIN
							$this.css
								width: "initial"
								opacity: 1
						else
							$this.animate opacity: 0
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
@notify = (body, type = 'default', time = 4000, dismissable = yes, priority = 0) ->
	NotificationsManager.notify {
		body: "<b>#{_.escape body}</b>"
		type
		time
		dismissable
		priority
		html: yes
		allowDesktopNotifications: no
	}

###*
# 'Slides' the slider to the given destanation.
# @method slide
# @param {String} [id] The ID of the `.sidebarButton` to slide to.
###
@slide = (id) ->
	closeSidebar?()
	Meteor.defer ->
		$('.sidebarButton.selected').removeClass 'selected'
		$(".sidebarButton##{id}").addClass 'selected' if id?

###*
# Start a animate.css shake animation on the elements which match the
# given selector. After the shake this method makes sure it can shake
# again. Shake it like it's hot! ;)
#
# @method shake
# @param selector {jQuery|String} The selector of which elements to shake.
###
@shake = (selector) ->
	(if selector.jquery? then selector else $ selector)
		.addClass 'animated shake'
		.one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
			$(this).removeClass 'animated shake'

###*
# Sets various meta data for the current page. (eg: the document title)
#
# @method setPageOptions
# @param options {Object} The options you prefer.
#   @param [options.title] {String} The title to set.
#   @param [options.color] {String} The color to set. If this is omitted the default color for each component will be used.
#   @param [options.headerTitle=title] {String} The title that is used for the header.
#   @param [options.useAppPrefix=true] {Boolean} Whether or not to use the app prefix ("simplyHomework").
###
@setPageOptions = ({ title, headerTitle, color, useAppPrefix }) ->
	check title,         Match.Optional String
	check headerTitle,   Match.Optional String
	check color,         Match.Optional Match.OneOf String,  null
	check useAppPrefix,  Match.Optional Boolean

	headerTitle ?= title
	useAppPrefix ?= yes

	if not title? and headerTitle?
		Session.set 'headerPageTitle', headerTitle
	else if title? or headerTitle?
		Session.set 'documentPageTitle', if useAppPrefix then "simplyHomework | #{title}" else title
		Session.set 'headerPageTitle', headerTitle

	unless _.isUndefined color
		Session.set 'pageColor', color

###*
# Set the current bigNotice.
# @method setBigNotice
# @param options {Object|null} The options object. If null the notice will be removed.
# @return {Object} An handle object: { hide, content, onClick, onDismissed }
###
@setBigNotice = (options) ->
	if options?
		check options, Object
		_.defaults options,
			theme: 'default'
			allowDismiss: yes
			onDismissed: -> setBigNotice null

		currentBigNotice.set options
		$('body').addClass 'bigNoticeOpen'

		hide: -> setBigNotice null
		content: (content) ->
			if content?
				currentBigNotice.set _.extend currentBigNotice.get(), { content }
				content
			else
				currentBigNotice.get().content

		onClick: (onClick) ->
			if _.isFunction onClick
				currentBigNotice.set _.extend currentBigNotice.get(), { onClick }

		onDismissed: (onDismissed) ->
			if _.isFunction onDismissed
				currentBigNotice.set _.extend currentBigNotice.get(), { onDismissed }

	else if _.isNull options
		currentBigNotice.set null
		$('body').removeClass 'bigNoticeOpen'
		undefined

###*
# @method showModal
# @param {String} name The ID of the modal, has to be the same as the template name.
# @param {Object} [options]
# 	@param {Function} [options.onHide]
# @param {any} [data]
# @return {Function} When called, removes the newely spawned modal.
###
@showModal = (name, options, data) ->
	check name, String
	check options, Match.Optional Object
	check data, Match.Optional Match.Any

	view = (
		if data?
			Blaze.renderWithData Template[name], data, document.body
		else
			Blaze.render Template[name], document.body
	)
	$modal = $ "##{name}"
	$modal
		.modal options
		.one 'hidden.bs.modal', ->
			Blaze.remove view
			options?.onHide?()

		.find('input[type="text"]:first-child')
		.focus()

	-> $modal.modal 'hide'

Meteor.startup ->
	Session.setDefault 'documentPageTitle', 'simplyHomework'
	Session.setDefault 'pageColor', 'lightgray'
	Session.setDefault 'allowNotifications', no

	$colortag = $ 'meta[name="theme-color"]'
	Tracker.autorun ->
		document.title = Session.get 'documentPageTitle'
		$colortag.attr 'content', Session.get('pageColor') ? '#32A8CE'

	BlazeLayout.setRoot 'body'

	notice = null
	Tracker.autorun ->
		if Meteor.userId()? and window.Notification? and not window.ActiveXObject?
			switch Notification.permission
				when 'default'
					notice = setBigNotice
						content: 'We hebben je toestemming nodig om bureaubladmeldingen weer te kunnen geven.'
						onClick: ->
							Notification.requestPermission (result) ->
								notice?.hide()
								Session.set 'allowNotifications', result is 'granted'
				when 'granted'
					notice?.hide()
					Session.set 'allowNotifications', yes

	Template.registerHelper 'picture', (user, size) -> picture user, if _.isNumber(size) then size else undefined
	Template.registerHelper 'has', has
	Template.registerHelper 'toUpperCase', (str) -> str.toUpperCase()
	Template.registerHelper 'cap', (str) -> Helpers.cap str

	Template.registerHelper 'isPhone', -> Session.equals 'deviceType', 'phone'
	Template.registerHelper 'isTablet', -> Session.equals 'deviceType', 'tablet'
	Template.registerHelper 'isDesktop', -> Session.equals 'deviceType', 'desktop'

	Template.registerHelper 'currentYear', -> new Date().getFullYear()
	Template.registerHelper 'dateFormat', (format, date) -> moment(date).format format
	Template.registerHelper 'time', (date) -> moment(date).format 'HH:mm'
	Template.registerHelper 'numberFormat', (number) ->
		switch number
			when 0 then 'geen'
			else number

	Template.registerHelper 'textColor', (color, fallback) ->
		color ?= fallback
		return '' unless color?
		if chroma(color).luminance() > .45 then 'black' else 'white'

	Template.registerHelper 'pathFor', (path, view) ->
		unless path?
			throw new Error "`path` parameter is required."

		if path.hash?.route?
			view = path
			path = view.hash.route
			delete view.hash.route

		query = (
			if view.hash.query?
				FlowRouter._qs.parse view.hash.query
			else
				{}
		)
		hashBang = view.hash.hash ? ''
		FlowRouter.path(path, view.hash, query) + hashBang

	disconnectedNotice = null
	Tracker.autorun ->
		status = Meteor.status()

		if status.connected
			console.info('Reconnected.') if disconnectedNotice?

			disconnectedNotice?.hide()
			disconnectedNotice = null
		else unless disconnectedNotice? or status.retryCount < 2
			disconnectedNotice = setBigNotice
				content: 'Verbinding verbroken'
				theme: 'error noclick'
				allowDismiss: no
			console.info 'Disconnected.'
