#!/usr/local/bin/ruby

require File.expand_path("../ClientMsg.rb")
require File.expand_path("../ServerMsg.rb")


puts "-----------------------"
puts "|   Client Messages   |"
puts "-----------------------"
puts ClientMsg::JOIN
puts ClientMsg::PLAY
puts

puts "-----------------------"
puts "|   Server Messages   |"
puts "-----------------------"
puts ServerMsg::PLAYERS
puts ServerMsg::START
puts ServerMsg::PLAYED
puts ServerMsg::GAMEOVER
puts ServerMsg::ACCEPT
puts ServerMsg::DEAL
puts ServerMsg::PLAY
puts ServerMsg::INVALID
puts ServerMsg::CHAT
puts ServerMsg::WAIT
puts ServerMsg::TTS

puts
puts "[done]"
puts