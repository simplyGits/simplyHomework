send = ->
	if not correctMail($("#mailInput").val()) or BetaPeople.find(hash: md5 $("#mailInput").val().toLowerCase()).count() isnt 0
		shake "input"

		$("#mailInput").tooltip(placement: "bottom", html: "<h2>Je hebt je al aangemeld</h2>").tooltip "show"
	else
		BetaPeople.insert hash: md5($("#mailInput").val().toLowerCase()), mail: $("#mailInput").val().toLowerCase()
		$("input").remove()
		$("button").remove()
		$("h1").text("hou je mail in de gaten").css fontSize: if Session.get "isPhone" then "50px" else "100px"

Template.beta.events
	"keyup #mailInput": (event) ->
		if event.which is 13 then send()
		else $(event.target).css borderColor: if BetaPeople.find(hash: md5 event.target.value.toLowerCase()).count() is 0 and (event.target.value is "" or correctMail event.target.value) then "#fff" else "red"

	"click button": send

Template.beta.rendered = ->
	Meteor.defer ->
		$(".animate, .animateLong").addClass "animated"
		$(".animated").one 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', ->
			$(this).removeClass "animate animateLong"

		$(window).scroll ->
			scrollDelta = ($(".page2").offset().top - $(window).scrollTop()) / $(".page2").offset().top
			opacity = 1 + (scrollDelta - 1)
			if opacity < .2 then opacity = .2
			if Session.get('isPhone')
				$("div#betaContainer, .appNameHeaderBig").css { opacity }
			else
				$("div#betaContainer").css { opacity }

		if Session.get "isPhone"
			setHeight = -> $("div#betaFullContainer").css height: $(document).height() + 15
			setHeight()
			$(window).resize setHeight
