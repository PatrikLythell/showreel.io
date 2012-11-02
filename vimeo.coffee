request = require 'request'
qs = require 'querystring'

exports.app = (config) ->
	
	root = 'https://vimeo.com/api/rest/v2?format=json'

	reqUrl = 'https://vimeo.com/oauth/request_token'
	authUrl = 'https://vimeo.com/oauth/authorize?oauth_token='
	accUrl = 'https://vimeo.com/oauth/access_token'

	callbackUrl = config.CALLBACK_URL
	appId = config.APP_ID
	appSecret = config.APP_SECRET

	requestToken: (callback) ->
		params =
			callback: callbackUrl
			consumer_key: appId
			consumer_secret: appSecret
		url = reqUrl
		request.post
			url: url
			oauth: params
		, (err, res, body) ->
			body = qs.parse body
			body.redirect = authUrl+body.oauth_token
			callback(body)

	getAccToken: (params, callback) ->
		params.consumer_key = appId
		params.consumer_secret = appSecret
		request.post
			url: accUrl
			oauth: params
		, (err, res, body) ->
			body = qs.parse body
			console.log body
			callback(body)

	getUserInfo: (params, callback) ->
		params.consumer_key = appId
		params.consumer_secret = appSecret
		console.log params
		request.post
			url: root+'&method=vimeo.people.getInfo'
			oauth: params
		, (err, res, body) ->
			body = JSON.parse body
			callback(body)

	getAllVideos: (params, callback) ->
		params.consumer_key = appId
		params.consumer_secret = appSecret
		request.post
			url: root+'&method=vimeo.videos.getAll'
			oauth: params
		, (err, res, body) ->
			body = JSON.parse body
			callback(body)

	getThumbnailUrls: (params, id, callback) ->
		params.consumer_key = appId
		params.consumer_secret = appSecret
		request.post
			url: root+'&method=vimeo.videos.getThumbnailUrls&video_id='+id
			oauth: params
		, (err, res, body) ->
			body = JSON.parse body
			callback(body)

	getVideoInfo: (params, videoid, callback) ->
		params.consumer_key = appId
		params.consumer_secret = appSecret
		request.post
			url: root+'&method=vimeo.videos.getInfo&video_id='+videoid
			oauth: params
		, (err, res, body) ->
			body = JSON.parse body
			callback(body.video[0])
