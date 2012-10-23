#!/usr/local/bin/ruby

require File.expand_path("../ClientMsg.rb")
require File.expand_path("../ServerMsg.rb")

include ClientMsg
include ServerMsg


puts "-----------------------"
puts "|   Client Messages   |"
puts "-----------------------"
puts
puts ClientMsg.message("join", ["matt"])
puts ClientMsg.message("play", ["R5"])
puts ClientMsg.message("chat", ["travis", "Hey man! Good to see you!"])
puts ClientMsg.message("party", ["hey!!!", "what?"])
puts

puts "-----------------------"
puts "|   Server Messages   |"
puts "-----------------------"
puts

puts
puts "[done]"
