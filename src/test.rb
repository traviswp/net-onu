#!/usr/local/bin/ruby

require 'Card'
require 'Deck'
require 'time'
require 'PlayerList'
require 'ServerMsg'
require 'ClientMsg'

include ServerMsg

def test_serverMsg()

end #test_serverMsg

def test_Card_isValid()

	c = Card.new("R","55")

	myCard0 = "n5"
	myCard1 = "G9"
	myCard2 = "NF"
	myCard3 = "RS"
	myCard4 = "BR"
	myCard5 = "YW"
	myCard6 = "G11"
	myCard7 = "PS"
	myCard8 = "a0"
	myCard9 = "hello man!!!"
	myCard10 = 5
	myCard11 = false

	puts c.valid_card?(c)
	puts c.valid_str?(myCard0)
	puts c.valid_str?(myCard1)
	puts c.valid_str?(myCard2)
	puts c.valid_str?(myCard3)
	puts c.valid_str?(myCard4)
	puts c.valid_str?(myCard5)
	puts c.valid_str?(myCard6)
	puts c.valid_str?(myCard7)
	puts c.valid_str?(myCard8)
	puts c.valid_str?(myCard9)
	puts c.valid_str?(myCard10)
	puts c.valid_str?(myCard11)

end #test_Card_isValid()

def test_Deck()

	d = Deck.new()

	#initially print all the cards (should be shuffled)
	puts d.to_s()
	puts d.size()  # puts the length (should be 108)

	# get 5 cards & display them
	cards = d.deal(5)
	puts cards.to_s

	# print deck after change
	puts d.to_s()
	puts d.size() # puts the length (should be 103)


	# try to get 10 cards (should return nil)
	#cards = d.deal(10)
	#if (cards == nil)
	#	puts "yup, no cards"
	#end

	################################################

	### SERVER DISCARD SHOULD DELETE THE DISCARDED CARD OUT OF THE PLAYERS HAND ###

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	d.discard(cards[0])
	cards.delete_at(0)

	d.showDiscard()
	puts "top card:"
	puts d.top_card
	puts cards.to_s()

end #test_Deck()

def test_timer()
	
	start_time = Time.now.to_i
	puts start_time
	count = 0
	while (true)
		
		current_time = Time.now.to_i

		if (current_time - start_time >= 5)
			puts "the start time was: ", start_time, " and the current time is ", current_time, "diff: ", (current_time-start_time).abs().to_s
			break
		end
	end #while

end #test_timer

def test_players()
	players = PlayerList.new()
	p1 = Player.new("travis",0)
	p2 = Player.new("test-player1",1)
	p3 = Player.new("test-player2",2)
	
	#puts "players: " + players.to_s()
	
	players.add(p1)
	players.add(p2)
	players.add(p3)

	puts players

	#puts "players: " + players.to_s().to_a.join("|")

	#puts ([players].kind_of? Array)
	#puts "[" + players.to_s + "]"

	#puts ServerMsg.message("STARTGAME", players.getPlayers)

end

def validate()

	print validation("[|]")
	puts
	print validation("[JOIN|travis]")
	puts
	print validation("[CHAT|hey travis, this is a test message!]")
	puts
	print validation("[play|R6]")
	puts
	print validation("[play|Y99]")
	puts
	print validation("[PLAY|di]")
	puts
	print validation("[NOPE|illegal command]")
	puts
	print validation("[STARTGAME|travis]")
	puts
	print validation("[HI|test]")
	puts


end

def validation(cmd)
	@players = ["travis","travis1","travis2","chat","mike"] ##TESTING

    # Match (1) the command and (2) the content of the message
#    re = /\[([a-z]{2,9})\|([\w\W]{0,128})\]/i
    re = /\[([a-z]{4})\|([\w\W]{0,128})\]/i
    args = cmd.match re

    if args != nil then
        command = args[1].upcase()
        info    = args[2]
    else
        return nil 
    end # if

	# validate if the command is supported
	if (!ClientMsg.include?(command)) then
		msg = "sorry, " + command + " is not a valid command"
		return ["INVALID", msg]
	end

	# handle supported commands
	if command == "JOIN" then

		# Modify name if it is in use already
		numId = 1
		tmp = info
		while true
		    exists = @players.find { |p| p.to_s == tmp }
		    if exists != nil then
		        tmp = info + numId.to_s
		        numId = numId + 1
		    else
				name = tmp
		        break
		    end # if
		end # while

		return [command, name]

	elsif command == "PLAY" then
		#validate card
		card = info
		valid = Card.new().valid_str?(card)
		if (!valid) then
			return nil
		end
		return [command, card]
	elsif command == "CHAT" then
		# validate msg
		msg = info
		return [command, msg]
	end

end # name_validation


if __FILE__ == $0 then

#test_ServerMsg()
#test_Card_isValid()
#test_Deck()
#test_timer()
#test_players()
#validate()

msg = "[JOIN|TRAvIS][CHAT|hey man this is travis! how is it going?][DEAL|B7]"
puts msg
re = /\[([a-zA-Z]{2,9})\|(.*?)\]/i
m = msg.match re

if m != nil then
	command = m[1].upcase()
	info    = m[2]
	puts command
	puts info
	puts info.size()
end

msg.sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
puts msg

end #if
