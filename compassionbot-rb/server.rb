# CompassionBot server.rb -- Facebook messenger to API.ai integration
# Leslie Wu 2016, cloned from https://github.com/luisbebop/facebook-robot-sinatra

require 'sinatra'
require 'json'
require 'httparty'
require 'pp'
require './api_ai'
 
set :bind, '0.0.0.0' # bind address so external hosts can access it. use https://ngrok.com/ for testing
 
set :logging, true

# Note: need to shell env vars taken from Facebook messenger bot.
# If using Heroku, use "heroku config:set PAGE_ACCESS_TOKEN=... VERIFY_TOKEN=...
URL = "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV["PAGE_ACCESS_TOKEN"]}"

# Point Facebook to this webhook URL during configuration
post '/page_webhook' do
  body = request.body.read
  payload = JSON.parse(body)
  
  # get the sender of the message
  sender = payload["entry"].first["messaging"].first["sender"]["id"]
  
  # get the message text
  message = payload["entry"].first["messaging"].first["message"]
  message = message["text"] unless message.nil?
  
  pp message # debug dump input

  ai_response_text = ApiAi.chat(message)

  pp ai_response_text # debug dump output

  # Use OS X say to output bot response via TTS (text to speech)
  `say -v Vicki "#{ai_response_text}"` # workaround since FB reply to bot doesn't work ATM
  
  # ask Api.ai NLP api if it isn't a confirmation message from Facebook messenger API
  unless message.nil?
    @result = HTTParty.post(URL, 
        :body => { :recipient => { :id => sender}, 
                   :message => { :text => ai_response_text}
                 }.to_json,
        :headers => { 'Content-Type' => 'application/json' } ) # TODO this might not work?
  end
  
end

get '/page_webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end
 
get '/' do
  html = <<-HTML
<html>
<body>
Hi I'm Sam.
</body>
</html>
HTML

  html
end
