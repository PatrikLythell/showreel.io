window.Scripts =
	
	signup: ->
		
		timer = null
		initCheck = $('input#username').attr('placeholder')
		
		$('input#username').keyup ->
			$('input#username').css('color', 'grey')
			clearTimeout(timer)
			timer = setTimeout ->
				username = $('input#username').val()
				console.log "check"
				checkName(username)
			, 300

		checkName = (username) ->
			$.post '/check-username',
				"user_name": username
			, (res) ->
				console.log res
				if res is "taken"
					$('button#signup').addClass('btn-danger').attr('disabled','disabled').html('Username is taken')
					$('input#username').css('color', 'red')
				else
					$('button#signup').removeClass('btn-danger').removeAttr('disabled').html('Sign Up!')
					$('input#username').css('color', 'green')
					
		checkName(initCheck)

		$('button#signup').click ->
			username = $('input#username').val()
			username = $('input#username').attr("placeholder") if !username
			console.log username
			$.post 'new-user',
				"user_name": username
			, (res) ->
				$('div.content').html('<button class="btn-large color">Do you like light?</button><button class="btn-large btn-inverse color">Or dark?</button>')

		$('button.color').live("click", ->
			color = null
			if $(this).hasClass('btn-inverse')
				color = "dark"
			else
				color = "light"
			console.log color
			$.post '/color-choice',
				"color": color
			, (res) ->
				console.log res
				window.location.href = "/sync"
		)

	videoInfo: (id, user) ->
		$.post '/video-info',
			"video_id": id
			"user": user
		, (res) ->
			console.log res
		
