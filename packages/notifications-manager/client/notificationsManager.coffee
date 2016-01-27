genId = do ->
	index = 0
	->
		"notif_#{index++}"

buildHtmlNotfication = ({ id, body, html, image, onClick, onDismissed, onHide }) ->
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
			tag: id
			icon: image
		}
	)

	notif.onclick = ->
		window.focus()
		onClick?()
		onHide?()
	notif.onclose = ->
		onDismissed?()
		onHide?()

	notif

###*
# The manager for notificafions.
# @class NotificationsManager
# @static
###
class NotificationsManager
	@_notifications: []

	# TODO: Make it possible to update the handlers using the notification handle?
	###*
	# @method notify
	# @param {Object} options
	# @return {Object}
	###
	@notify: (options) ->
		check options, Object
		_.defaults options,
			type: 'default'
			time: 4000
			dismissable: yes
			html: no
			priority: 0
			allowDesktopNotifications: yes
			image: ''
			buttons: []
		{
			body, type, time, dismissable, html, onClick, onHide, priority,
			onDismissed, allowDesktopNotifications, image, buttons
		} = options

		check time, Match.Where (t) -> _.isNumber(t) and ( t is -1 or t > 0 )
		check priority, Number

		handle =
			_hiding: no
			_delayHandle: null
			_htmlNotif: null
			id: genId()
			priority: priority
			###*
			# @method hide
			###
			hide: ->
				clearTimeout @_delayHandle
				onHide?()

				if @_htmlNotif?
					@_htmlNotif.close()
					_.remove NotificationsManager._notifications, @id

				else
					$notification = @element()
					$notification.removeClass 'transformIn'
					@_hiding = yes
					NotificationsManager._updatePositions()

					_.delay ( =>
						$notification.remove()
						_.remove NotificationsManager._notifications, @id
					), 2000

			###*
			# @method height
			# @return {Number}
			###
			height: ->
				if @_htmlNotif? then 0
				else @element().outerHeight yes

			###*
			# @method content
			# @param {String} [content]
			# @param {Boolean} [html=false]
			# @return {String}
			###
			content: (content, html = false) ->
				if @_htmlNotif? and content?
					# We can't change the contents of a HTML notification, just rebuild it.
					@_htmlNotif.close()

					handle._htmlNotif = buildHtmlNotfication
						id: @id
						body: body
						html: html
						image: image
						onClick: onClick
						onDismissed: onDismissed
						onHide: -> handle.hide()

					undefined
				else
					$content = $ ".notification##{handle.id} div"
					if content?
						$content.html (
							if html then body
							else _.escape body
						).replace /\n/g, '<br>'

						NotificationsManager._updatePositions()

					if html then $content.html()
					else $content.text()

			###*
			# @method element
			# @return {jQuery}
			###
			element: -> $ ".notification##{handle.id}"

		if document.hasFocus() or
		not allowDesktopNotifications or not Session.get 'allowNotifications'
			d = $ document.createElement "div"
			d.addClass "notification #{type}"
			d.attr "id", handle.id
			d.html "<div>#{(if html then body else _.escape body).replace(/\n/g, '<br>')}</div>"
			d.append "<br>"
			if onClick?
				d.click ->
					if $(this).hasClass("noclick") then $(this).removeClass "noclick"
					else
						onClick arguments...
						handle.hide()
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
							handle.hide()
							onDismissed?()
					drag: (event, helper) ->
						$this = $ this
						$this.css opacity: 1 - ((pos - $this.position().left) / 250)
					revert: -> $(this).position().left - pos > MIN

			for b in buttons
				b.style ?= 'btn-default'
				b.hide ?= yes
				btn = $.parseHTML("<button type='button' class='btn #{b.style}'>#{b.label}</button>")[0]

				b.callback ?= (->)
				do (b) ->
					btn.onclick = (event) ->
						b.callback event, handle
						handle.hide() if b.hide

				d.append btn

			unless time is -1 # Handles that sick timeout, yo.
				hide = -> handle.hide()
				handle._delayHandle = _.delay hide, time + 500

				d.mouseover -> clearTimeout handle._delayHandle
				d.mouseleave -> handle._delayHandle = _.delay hide, time + 500

			$('body').append d
			Meteor.defer -> handle.element().addClass 'transformIn'

		else
			handle._htmlNotif = buildHtmlNotfication
				id: handle.id
				body: body
				html: html
				image: image
				onClick: onClick
				onDismissed: onDismissed
				onHide: -> handle.hide()

			if time isnt -1
				handle._delayHandle = _.delay (-> handle.hide()), time + 500

		@_notifications.push handle
		@_updatePositions()

		handle

	###*
	# @method notifications
	# @return {Object[]}
	###
	@notifications = -> _.reject @_notifications, '_hiding'

	###*
	# @method hideAll
	###
	@hideAll = ->
		x.hide() for x in @notifications()
		undefined

	###*
	# @method _updatePositions
	# @private
	###
	@_updatePositions = ->
		height = 0

		notifications = _(@notifications())
			.reject (n) -> n._htmlNotif?
			.reverse()
			.sortBy 'priority'
			.reverse()
			.value()

		for notification, i in notifications
			notification.element().css top: height + 15
			height += notification.height() + 10

		undefined

@NotificationsManager = NotificationsManager
