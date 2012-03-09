require 'sinatra'
require './lib/vrowser'

def get_active_servers
  Vrowser.load_file("/home/kimoto/config.yml") do |vrowser|
    greped = vrowser.active_servers.select(:name, :host, :ping, :num_players, :type, :map, :players)
    ordered = greped.order(:host)
    return ordered.map(&:values)
  end
end

def get_active_servers_nary
  get_active_servers.map(&:values)
end

get '/api/connected/json' do
  content_type :json
  return get_active_servers.to_json
end

get '/api/updated/json' do
  content_type :json
  return get_active_servers_nary.to_json
end

get '/' do
  redirect "index.html"
end

