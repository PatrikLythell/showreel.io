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
				res.redirect '/sign-up'

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
		user = req.session.user
		user.user_name = req.body.user_name

		db.users.save user, (err) ->
			throw err if err
			res.send("user sent ok")

	app.post '/color-choice', (req, res) ->
		color = req.body.color
		console.log color
		id = 
			id: req.session.user.id
		
		db.users.update id,
			$set:
				color: color
		, (err) ->
			throw err if err
			console.log "added color"
			username = req.session.user.user_name
			res.send "ok"

	app.get '/sync', (req, res) ->
		#get a lot of shit here

		console.log req.session.token #change back to token after dev is finished
		token =
			token: 'cf5c00fb4f410f44870c904ed069ab11'
			token_secret: '7b3e445a49f2ed44edbe39ef549918fa243d69b0'
			consumer_key: 'b62d75bf5a4e0b0e5ae27acc9cae476e7000d0c5'
			consumer_secret: '9e14fd99e7852a313685ed9a057b0c4d2a2bf4f5'

		thumbnails = []

		vimeoConnect.getAllVideos token, (response) ->
			for video, i in response.videos.video
				getThumbnailUrls(token, video.id)

		getThumbnailUrls = (token, id) ->
			vimeoConnect.getThumbnailUrls token, id, (response) ->
				thumbnails.push response.thumbnails

	app.get '/:username', (req, res) ->
		if req.url is '/favicon.ico'
			res.writeHead 200, {'Content-Type': 'image/x-icon'}
			res.end()
			console.log 'favicon requested'
		else
			username = req.url.substr(1)
			db.users.findOne {user_name: username}, (err, response) ->
				res.render 'user'
					user: response