###*
# The manager for notificafions.
# @class NotificationsManager
# @static
###
class NotificationsManager
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

@NotificationsManager = NotificationsManager
