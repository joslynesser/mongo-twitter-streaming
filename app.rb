configure do
  DB = Mongo::Connection.new.db("mongotweets")
  DB.create_collection("tweets", :capped => true, :size => 10485760)
end

get '/' do
  content_type 'text/html', :charset => 'utf-8'
  @tweets = DB['tweets'].find({}, :limit => 10, :sort => [[ '$natural', :desc ]])
  erb :index
end

STREAMING_URL = 'http://stream.twitter.com/1/statuses/sample.json'

EM.schedule do
  http = EM::HttpRequest.new(STREAMING_URL).get :head => { 'Authorization' => [ 'joslynesser', 'ESSER556' ] }
  buffer = ""
  http.stream do |chunk|
    buffer += chunk
    while line = buffer.slice!(/.+\r?\n/)
      DB['tweets'].insert(JSON.parse(line))
    end
  end
end