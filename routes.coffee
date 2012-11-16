module.exports = (app, vimeoConnect, async, db) ->

	app.get '/', (req, res, next) ->
		res.render 'index',
			title: 'Hello World!'

	app.get '/vimeo', (req, res) ->
		vimeoConnect.requestToken (response) ->
			req.session.token = response.token
			req.session.token_secret = response.oauth_token_secret
			res.redirect response.redirect

	app.get '/auth', (req, res) ->
		params = # This is because request oauth function adds oauth as a precursor to all keys.
			token: req.query.oauth_token
			verifier: req.query.oauth_verifier
		params.token_secret = req.session.token_secret
		vimeoConnect.getAccToken params, (response) ->
			req.session.token = 
				token: response.oauth_token
				token_secret: response.oauth_token_secret
			req.session.token_secret = response.oauth_token_secret
			params = req.session
				
			# Get all user info
			vimeoConnect.getUserInfo req.session.token, (response) ->
				req.session.user = response.person
				id = 
					"vimeo.id": response.person.id
				db.users.findOne id, (err,docs) ->
					if docs is null
						res.redirect '/sign-up'
						console.log "new user"
					else
						res.redirect '/'+docs.user_name
						console.log "exising user"

	app.get '/sign-up', (req, res) ->
		res.render 'signup',
			user: req.session.user

	app.post '/check-username', (req, res) ->
		username = req.body.user_name
		db.users.findOne {user_name: username}, (err, response) ->
			if response is null
				res.send "free"
			else
				res.send "taken"

	app.post '/new-user', (req, res) ->
		user = 
			vimeo: req.session.user
		user.user_name = req.body.user_name
		user.token = req.session.token
		req.session.user_name = req.body.user_name

		db.users.insert user, (err) ->
			throw err if err
			res.send("user sent ok")

	app.post '/color-choice', (req, res) ->
		color = req.body.color
		console.log color
		id = 
			"vimeo.id": req.session.user.id
		
		db.users.update id,
			$set:
				color: color
		, (err) ->
			throw err if err
			console.log "added color"
			username = req.session.user.user_name
			res.send("ok")

	app.post '/video-info', (req, res) ->
		videoID = req.body.video_id
		user = req.body.user
		db.users.findOne {user_name: user}, (err, response) ->
			token = response.token
			vimeoConnect.getVideoInfo token, videoID, (response) ->
				console.log response.thumbnails
				res.send(response)

	app.get '/sync', (req, res) ->
		# THIS IS THE RENDER FUNCTION THAT CARRIES AN IF ON USERNAME
		console.log req.session
		render = (videos, name) ->
			console.log "redirecting"
			id = 
				"vimeo.id": req.session.user.id #either from session of from database
			db.users.update id,
				$set:
					videos: videos
			, true #upsert is true
			res.redirect '/'+name
		
		#get a lot of shit here

		#change this back to req.session.token token after dev is finished
		token =
			token: 'f4eb56c51595c348f178f7c30282047f'
			token_secret: '79029bf362b130d6ba9e87cc3dad44da0d610c1c'
			consumer_key: 'b62d75bf5a4e0b0e5ae27acc9cae476e7000d0c5'
			consumer_secret: '9e14fd99e7852a313685ed9a057b0c4d2a2bf4f5'

		vidArr = []

		getVideoInfo = (video, callback) ->
			vimeoConnect.getVideoInfo token, video.id, (response) -> #can i name it here for easier searh?
				delete response.owner
				vidArr.push response
				callback()

		vimeoConnect.getAllVideos token, (response) ->
			async.forEach response.videos.video, getVideoInfo, (err) ->
				render(vidArr, req.session.user_name)
				
	app.get '/:username', (req, res) ->
		if req.url is '/favicon.ico'
			res.writeHead 200, {'Content-Type': 'image/x-icon'}
			res.end()
			console.log 'favicon requested'
		else
			username = req.params.username
			db.users.findOne {user_name: username}, {token: 0}, (err, response) ->
				console.log response
				if response is null
					res.render '404'
				else 
					res.render 'user'
						user: response

	app.get '/:username/:video', (req, res) ->
		if req.url is '/favicon.ico'
			res.writeHead 200, {'Content-Type': 'image/x-icon'}
			res.end()
			console.log 'favicon requested'
		else
			username = req.params.username
			video = req.params.video
			videoName = video.replace(/_/g, "%20")
			videoName = decodeURIComponent(videoName)
			console.log videoName
			db.users.findOne {user_name: username}, {token: 0}, (err, response) ->
				# Check if user exists, let client check if video exists
				if response is null
					console.log "user not found"
					res.render '404'
				else
					render = (found) ->
						res.render 'video'
							user: response
							video: found

					found = null
					videoName = videoName.toLowerCase() # set lower case for check
					c = 0

					findVideo = (video, callback) ->
						searchTerm = video.title
						searchTerm = searchTerm.toLowerCase()
						if searchTerm is videoName
							found = video
							callback("err") # callback with an error to break the loop on find
						callback() # fallback callback if we don't find nuttin
						c++
						console.log c

					async.forEach response.videos, findVideo, (err) ->
						if !err
							res.render '404'
						else 
							render(found)


