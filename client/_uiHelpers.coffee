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

@alertModal = (title, body, buttonType = 0, labels = { main: "oké", second: "annuleren" }, styles  = { main: "btn-default", second: "btn-default" }, callbacks = { main: null, second: null }) ->
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

@isOldInternetExplorer = ->
	if navigator.appName is "Microsoft Internet Explorer"
		version = parseFloat RegExp.$1 if /MSIE ([0-9]{1,}[\.0-9]{0,})/.exec(navigator.userAgent)?
		return version < 9.0
	return false

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

@notify = (message, type = "warning", time = 4000) ->
	elem = $ switch type
		when "warning" then ".warningFlash"
		when "error" then ".errorFlash"
		else ".noticeFlash"

	check time, Match.Where (t) -> _.isNumber(t) and t >= -1 and t isnt 0

	elem.text message
	elem.addClass "transformIn"

	unless time is -1
		Session.set "warningFlashDelayHandle", _.delay ( -> elem.removeClass "transformIn"), time + 500

		elem.mouseover -> clearTimeout Session.get "warningFlashDelayHandle"
		elem.mouseleave -> Session.set "warningFlashDelayHandle", _.delay ( -> elem.removeClass "transformIn"), time + 500
	
	return hide: ->
		clearTimeout Session.get "warningFlashDelayHandle"
		elem.removeClass "transformIn"

class @NotificationsManager
	@_notifications: []

	@notify = (body, type = "notice", labels = [], styles = [], callbacks = []) ->
		#debugger
		notId = NotificationsManager._notifications.length
		notHandle =
			_done: no
			id: -> notId
			done: (val) ->
				if val?
					_done = val
				else
					_done
			hide: ->
				$(".persistantNotification##{notId}").removeClass "transformIn"
				_.delay ( -> $(".persistantNotification##{notId}").remove() ), 2000

			text: (text) -> $(".persistantNotification##{notId}").text text

		d = $ document.createElement "div"
		d.addClass "persistantNotification #{type}"
		d.attr "id", notId
		d.html "<div>#{body}</div>"
		d.append "<br>"

		for label, i in labels
			style = styles[i] ? "btn-default"
			btn = $.parseHTML "<button type=\"button\" class=\"btn #{style}\" id=\"#{notId}_#{i}\">#{label}</button>"
			d.append btn

		$("body").append d

		for label, i in labels
			callback = callbacks[i] ? (->)
			$(".persistantNotification##{notId}").find("button").click (event) -> callback event, notHandle

		_.delay ( -> $(".persistantNotification##{notId}").addClass "transformIn" ), 10

colors = [ "red"
	"cyan"
	"pink"
	"blue"
	"yellow"
	"green"
	"#B10DC9"
	"#85144B"
	"#F012BE"
	"#01FF70"
	"#FF851B"
	"#39CCCC"
]

@numberColor = (number) -> if number >= colors.length then colors[number % colors.length] else colors[number]

Meteor.startup ->
	Session.set "isPhone", window.matchMedia("only screen and (max-width: 760px)").matches

	UI.registerHelper "isPhone", -> Session.get "isPhone"
	UI.registerHelper "hasPremium", -> Meteor.user().hasPremium
	UI.registerHelper "empty", -> return @ is 0
	UI.registerHelper "first", (arr) -> EJSON.equals @, _.first arr
	UI.registerHelper "last", (arr) -> EJSON.equals @, _.last arr
	UI.registerHelper "minus", (base, substraction) -> base - substraction

	disconnectedNotify = null
	_.delay ->
		Deps.autorun ->
			if Meteor.status().connected then disconnectedNotify?.hide()
			else disconnectedNotify = notify("Verbinding verbroken", "error", -1)
	, 1200