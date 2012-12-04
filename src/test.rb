#!/usr/bin/env ruby

require 'Card'
require 'Deck'
require 'time'
require 'PlayerList'
require 'ServerMsg'
require 'ClientMsg'

include ServerMsg

$cards = [

		# Regular cards (color: R,G,Y,B & number: 0-9)
		"R0","R1","R1","R2","R2","R3","R3","R4","R4","R5","R5","R6","R6","R7","R7","R8","R8","R9","R9",
		"G0","G1","G1","G2","G2","G3","G3","G4","G4","G5","G5","G6","G6","G7","G7","G8","G8","G9","G9",
		"Y0","Y1","Y1","Y2","Y2","Y3","Y3","Y4","Y4","Y5","Y5","Y6","Y6","Y7","Y7","Y8","Y8","Y9","Y9",
		"B0","B1","B1","B2","B2","B3","B3","B4","B4","B5","B5","B6","B6","B7","B7","B8","B8","B9","B9",

		# Action cards (color: R,G,Y,B & action: D (draw two), S (skip), U (reverse)
		"RD","RD","RS","RS","RU","RU",
		"GD","GD","GS","GS","GU","GU",
		"YD","YD","YS","YS","YU","YU",
		"BD","BD","BS","BS","BU","BU",

		# Wild cards (four regular wilds & four wild draw-fours)
		"NW","NW","NW","NW",
		"NF","NF","NF","NF",				
]

def test_checkDeck()

	s1 = "Y4,G6,GS,GD,G5,G6,G8,G9,G1,G9,GD,GU,BU,B5,BW,Y6,Y3,Y2,Y9,YS,Y6,R6,R5,RS,R9,R7,Y7,Y2,B2,BS,B1,B6,B4,B9,B9,BD,YD,YD,YU,Y9,R9,R2,R6,R3,R3,G3,GF,G4,G2,G8,G0,G1,GU,G3,GS,G5,G7,GW,RU,BU,BS,BW,Y5,Y1,YS,Y7,Y8,Y4,Y0,R0,RD,R1,R2,G2,G4,G7,GF,B3,B2,BD,BF,BF,GW,B8"
	a = s1.split(',')

	s2 = "G5,G2,R1,GU,B6,GU,Y4,B1,Y6,Y1,R5,BF,G1,G7,G8,Y9,YD,Y2,NW,B9,YS,BS,B3,B4,G4,Y7,R2,G5,R7,G1,YU,G6,G8,YD,BS,G9,R6,Y9,NF,B9,R3,BU,R6,BU,RS,B8,NW,B2,Y0,R3,NF,GD,R2,G3,NF,NW,RU,BD,RD,YS,GS,Y2,Y6,G7,Y8,G3,GS,Y7,GD,G4,R9,BD,R9,NW,R0,G9,G0,Y3,Y5,B2,G2,G6,B5"
	b = s2.split(',')

end #test_checkDeck

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

	#########################################################

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


end #if
