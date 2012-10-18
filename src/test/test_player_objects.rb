#!/usr/local/bin/ruby

require File.expand_path("../PlayerQueue.rb")
require File.expand_path("../Player.rb")

# Players queue
players_list = PlayerQueue.new

# Make a few players
player1 = Player.new("travis")
player2 = Player.new("dan")
player3 = Player.new("matt")
player4 = Player.new("bob")

#
# Test 'Player' methods
#

puts "Player name : " + player1.getName()
print "Player score: " 
puts player1.getScore()
puts player1.to_s() 

#
# Test 'PlayerQueue' methods
#

# Display the initial list (should be empty)
players_list.show()

# Add players & display the list of players again
players_list.add(player1)
players_list.add(player2)
players_list.add(player3)
players_list.add(player4)
players_list.show()

# Remove a player and display the list of players again
players_list.remove(player1)
players_list.show()

# Try to delete a player that isn't in the game
players_list.remove(Player.new("bad man"))

# Try to delete something not of type Player
players_list.remove(5)