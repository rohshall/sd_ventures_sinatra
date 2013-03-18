require 'sinatra'
require 'rubygems'
require 'sequel'
require 'json'
require 'pry'
require 'bundler'
Bundler.require

configure :development do
  set :database, 'sd_ventures_development'
end

configure :test do
  set :database, 'sd_ventures_test'
end

configure :production do
  set :database, 'sd_ventures_production'
end


DB = Sequel.connect("jdbc:postgresql://localhost/#{settings.database}?user=sd_ventures")


get '/devices' do
  devices_with_types = DB[:devices].join(:device_types, :id => :device_type_id)
  JSON.generate(devices_with_types.map([:mac_addr, :name]).map { |mac_addr, name| {:mac_addr => mac_addr, :device_type => name} })
end

get '/readings' do
  readings_for_devices = DB[:readings].join(:devices, :mac_addr => :device_mac_addr).join(:device_types, :id => :device_type_id)
  JSON.generate(readings_for_devices.map([:value, :device_mac_addr, :name]).map { |reading, mac_addr, device_type| {:reading => reading, :mac_addr => mac_addr, :device_type => device_type} })
end

get '/devices/:device_mac_addr/readings' do
  readings_for_devices = DB[:readings].filter(:device_mac_addr => params[:device_mac_addr]).join(:devices, :mac_addr => :device_mac_addr).join(:device_types, :id => :device_type_id)
  JSON.generate(readings_for_devices.map([:value, :device_mac_addr, :name]).map { |reading, mac_addr, device_type| {:reading => reading, :mac_addr => mac_addr, :device_type => device_type} })
end

post '/devices/:device_mac_addr/readings' do
  reading = JSON.parse request.body.read
  DB[:readings].insert(:value => reading["value"], :device_mac_addr => params[:device_mac_addr], :created_at => Time.now)
  JSON.generate({:status => "ok"})
end

