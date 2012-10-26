#!/usr/local/bin/ruby

require File.expand_path("../ClientMsg.rb")
require File.expand_path("../ServerMsg.rb")

include ClientMsg
include ServerMsg


puts "-----------------------"
puts "|   Client Messages   |"
puts "-----------------------"
puts
puts ClientMsg.message("join",  ["matt"])
puts ClientMsg.message("play",  ["R5"])
puts ClientMsg.message("chat",  ["travis", "Hey man! Good to see you!"])
puts ClientMsg.message("party", ["hey!!!", "what?"])
puts

puts "-----------------------"
puts "|   Server Messages   |"
puts "-----------------------"
puts

puts ServerMsg.message("accept",   ["tmoney"])
puts ServerMsg.message("deal",     ["R5","B5","NW","RR","GS","NW","YR"])
puts ServerMsg.message("gg",       ["phil"])
puts ServerMsg.message("go",       ["Y1"])
puts ServerMsg.message("invalid",  ["hey man, you can't do that!"])
puts ServerMsg.message("played",   ["jessie","R3"])
puts ServerMsg.message("players",  ["travis","jessie","matt","big john","little mike"])
puts ServerMsg.message("startgame",["travis","jessie","matt","little mike"])
puts ServerMsg.message("tts",      [12])
puts ServerMsg.message("wait",     ["agent 007"])
puts
puts "[done]"

