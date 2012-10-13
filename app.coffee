express = require 'express'
jade = require 'jade'
vimeo = require './vimeo'
async = require 'async'
db = require('mongojs').connect('vimeo', ['users'])

app = express()

vimeoConnect = vimeo.app
	APP_ID: 'b62d75bf5a4e0b0e5ae27acc9cae476e7000d0c5'
	APP_SECRET: '9e14fd99e7852a313685ed9a057b0c4d2a2bf4f5'
	CALLBACK_URL: 'http://localhost:3000/auth'

# CONFIGURATION

app.configure ->
	app.set 'view engine', 'jade'
	app.set 'views', "#{__dirname}/views"
	app.set 'port', process.env.PORT || 3000

	app.use express.bodyParser()
	app.use express.static(__dirname + '/public')
	app.use express.cookieParser()
	app.use express.session
		secret : "shhhhhhhhhhhhhh!"
	#app.use express.logger()
	app.use express.methodOverride()
	app.use app.router

app.configure 'development', () ->
	app.use express.errorHandler
		dumpExceptions: true
		showStack     : true

app.configure 'production', () ->
	app.use express.errorHandler()

# ROUTES

require('./routes.js')(app, vimeoConnect, async, db)

# SERVER

app.listen(app.get('port'))
console.log "Express server listening on port #{ app.get 'port' }"