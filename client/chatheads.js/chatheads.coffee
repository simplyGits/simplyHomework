class @ChatHeads
	@_springs: {}
	@_system: new rebound.SpringSystem()
	@_chatHeads: []

	@initialize: ->
		springs = @_springs

		snap = (value, side) ->
			switch side
				when "top" then $(".chatHead").css transform: "translate3d(0px, #{value}px, 0px)"
				when "left" then $(".chatHead").css transform: "translate3d(#{value}px, 0px, 0px)"
				when "right" then $(".chatHead").css transform: "translate3d(#{$(window).width() + value}px, 0px, 0px)"
				when "bottom" then $(".chatHead").css transform: "translate3d(0px, #{$(window).height() + value}px, 0px)"

		scale = (value) -> $(".chatHeadBin").css transform: "scale(#{value})"

		springs.top = @_system.createSpring 40, 6
		springs.left = @_system.createSpring 40, 6
		springs.right = @_system.createSpring 40, 6
		springs.bottom = @_system.createSpring 40, 6
		springs.bin = @_system.createSpring 80, 3

		springs.top.addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -20
				snap val, "top"
		springs.left.addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -20
				snap val, "left"
		springs.right.addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -40
				snap val, "right"
		springs.bottom.addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -40
				snap val, "bottom"
		springs.bin.addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, 1.35
				scale val

		if !amplify.store("chatHeadInfo")? then amplify.store "chatHeadInfo", top: 253, left: 0, side: "right"

		delayIds = []

		$(".chatHeadLeader").draggable
			scroll: no
			start: ->
				springs.top.setAtRest()
				springs.left.setAtRest()
				springs.right.setAtRest()
				springs.bottom.setAtRest()
				$(".chatHeadFollower").css opacity: 0 #fix ugly glitch
				
				$(".chatHeadBinBack").css visibility: "initial"
				$(".chatHeadBinBack").velocity {bottom: 0}, 200, "easeOutExpo", ->
					$(".chatHeadBin").velocity {opacity: 1}, 200

			drag: ->
				top = (Number) $(".chatHeadLeader").css("top").replace /[^\d\.\-]/ig, ""
				left = (Number) $(".chatHeadLeader").css("left").replace /[^\d\.\-]/ig, ""

				springs.top.setCurrentValue(top / -20).setAtRest()
				springs.left.setCurrentValue(left / -20).setAtRest()
				springs.right.setCurrentValue(($(window).width() - left) / 40).setAtRest()
				springs.bottom.setCurrentValue(($(window).height() - top) / 40).setAtRest()
				
				$(".chatHeadBadge").removeClass "under"
				$(".chatHeadBadge").removeClass "right"
				$(".chatHeadFollower").css transform: "translate3d(0px, 0px, 0px)"
				$(".chatHeadLeader").css transform: "translate3d(0px, 0px, 0px) scale(.93)"

				for i in [0...$(".chatHeadFollower").length]
					do (i, top, left) ->
						func = ->
							follower = $(".chatHeadFollower")[i]
							follower.style.opacity = 1
							follower.style.left = "#{left + 4 * (i + 1)}px"
							follower.style.top = "#{top}px"
							follower.style.zIndex = 99999 - i
						delayIds.push Meteor.setTimeout func, 20 * (i + 1)
			stop: ->
				$(".chatHeadBin").velocity {opacity: 0}, 200, ->
					$(".chatHeadBinBack").velocity {bottom: "-500px"}, 350, ->
						$(this).css visibility: "hidden"
				Meteor.clearTimeout delayId for delayId in delayIds
				delayIds = []

				top = (Number) $(".chatHeadLeader").css("top").replace /[^\d\.\-]/ig, ""
				left = (Number) $(".chatHeadLeader").css("left").replace /[^\d\.\-]/ig, ""

				for i in [0...$(".chatHeadFollower").length]
					do (i, top, left) ->
						follower = $(".chatHeadFollower")[i]
						follower.style.left = "#{left + ( 5 * (i + 1))}px"
						follower.style.top = "#{top + ( 5 * (i + 1))}px"
						follower.style.zIndex = 99999 - i

				values = [{ side: "top", value: top }
					{ side: "left", value: left }
					{ side: "right", value: $(window).width() - left }
					{ side: "bottom", value: $(window).height() - top }
				]

				closest = _.first(_.sortBy(values, (v) -> v.value)).side
				value = _.first(_.sortBy(values, (v) -> v.value)).value

				if closest is "top"
					springs[closest].setCurrentValue(value / -20).setAtRest()
					$(".chatHead").css top: 0
					$(".chatHeadBadge").addClass "under"
					amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

				else if closest is "left"
					springs[closest].setCurrentValue(value / -20).setAtRest()
					$(".chatHead").css left: 0
					$(".chatHeadBadge").addClass "right"
					amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

				else if closest is "right"
					springs[closest].setCurrentValue(value / 40).setAtRest()
					$(".chatHead").css left: 0
					amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

				else if closest is "bottom"
					springs[closest].setCurrentValue(value / 40).setAtRest()
					$(".chatHead").css top: 0
					amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

				springs[closest].setEndValue 1

		$(".chatHeadBin").droppable
			over: ->
				springs.bin.setEndValue 1
				$(".chatHeadBin").css color: "red", borderColor: "red"
			out: ->
				springs.bin.setEndValue 0
				$(".chatHeadBin").css color: "white", borderColor: "white"
			drop: ->
				$(".chatHeadBin").css color: "white", borderColor: "white"
				springs.bin.setEndValue 0
				$(".chatHead").addClass("ignoreDrag")
				$(".chatHead").velocity {opacity: 0}, ->
					$(".chatHead").css(visibility: "hidden", opacity: 1)
					$(".chatHead").removeClass("ignoreDrag")

		return undefined

	@flingChatHeadsOnScreen = ->
		springs = @_springs

		chatHeadInfo = amplify.store "chatHeadInfo"
		$(".chatHead").css top: 0, left: 0

		if chatHeadInfo.side is "left"
			$(".chatHead").css top: chatHeadInfo.top, visibility: "initial"
			springs.left.setCurrentValue(100).setAtRest()
			springs.left.setEndValue 1
			$(".chatHeadBadge").addClass "right"

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.top = "#{chatHeadInfo.top + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "right"
			$(".chatHead").css top: chatHeadInfo.top, visibility: "initial"
			springs.right.setCurrentValue(-50).setAtRest()
			springs.right.setEndValue 1

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.top = "#{chatHeadInfo.top + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "top"
			$(".chatHead").css left: chatHeadInfo.left, visibility: "initial"
			springs.top.setCurrentValue(100).setAtRest()
			springs.top.setEndValue 1
			$(".chatHeadBadge").addClass "under"

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.left = "#{chatHeadInfo.left + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "bottom"
			$(".chatHead").css left: chatHeadInfo.left, visibility: "initial"
			springs.bottom.setCurrentValue(-50).setAtRest()
			springs.bottom.setEndValue 1

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.left = "#{chatHeadInfo.left + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

	@chatHead: (options) ->
		obj = @

		throw new Error "options can't be null." unless options?
		_.defaults options, { dismissable: yes, exposedDiv: null }
		{ uniqueId, badgeCount, imageUrl, dismissable, onOpen, mapper } = options

		chatHead = _.find @_chatHeads, if mapper? then mapper else ((cH) -> cH.id is id)
		return chatHead if chatHead?

		handle =
			_open: yes
			_dirty: no
			_leader: no
			id: uniqueId
			badgeCount: 0
			open: ->
				@_open = no
				obj._updateDirty()

				@_dirty = yes

			close: ->
			throw: ->

		d = $ document.createElement "div"
		d.addClass "notification #{type}"
		d.attr "id", notId
		d.html if html then "<div>#{body}</div>" else "<div>#{escape body}</div>"
		d.append "<br>"

	@_updateDirty: ->
		# for chatHead, i in _.filter @_chatHeads, (cH) -> cH._dirty
		# 	if $(".chatHead#{chatHead.id}").length is 0 and chatHead._open
		# 		d = $ document.createElement "div"

		# 		d.addClass if chatHead._leader then "chatHead chatHeadLeader" else "chatHead chatHeadFollower"
		# 		d.attr "id", chatHead.id

		# 		if chatHead._leader
		# 			d.html "<i class=\"\">#{@_totalBadgeCount()}</i>"

	@_totalBadgeCount: ->
		@_chatHeads
			.map (x) -> x.badgeCount
			.reduce (x, y) -> x + y

	@_onThrowCallbacks: []
	@_throwed: -> callack() for callback in @_onThrowCallbacks
	@onThrow: (callback) -> @_onThrowCallbacks.push callback

	@_onClickCallbacks: []
	@_clicked: -> callack() for callback in @_onClickCallbacks
	@onClick: (callback) -> @_onClickCallbacks.push callback

###
<div class="chatHead chatHeadLeader" style="background-image: url('https://www.gravatar.com/avatar/763664ead00ca1ed8e12db1d5ad703c5?s=75&d=identicon&r=PG');">
	<i class="chatHeadBadge">5</i>
</div>
###