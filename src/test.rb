#!/usr/local/bin/ruby

require 'Card'
require 'Deck'
require 'time'

def test_serverMsg()

end #test_serverMsg

def test_Card_isValid()

	c = Card.new()

	myCard = "n5"
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

	puts c.isValid(myCard0)
	puts c.isValid(myCard1)
	puts c.isValid(myCard2)
	puts c.isValid(myCard3)
	puts c.isValid(myCard4)
	puts c.isValid(myCard5)
	puts c.isValid(myCard6)
	puts c.isValid(myCard7)
	puts c.isValid(myCard8)
	puts c.isValid(myCard9)
	puts c.isValid(myCard10)
	puts c.isValid(myCard11)

end #test_Card_isValid()

def test_Deck()

	d = Deck.new()

	#initially print all the cards (should be shuffled)
	d.deck.each { |c|
		puts c
	} 
	# puts the length (should be 108)
	puts d.deck.length()

	# get 5 cards & display them
	cards = d.deal(5)
	cards.each { |c|
		puts c
	} 
	# puts the length (should be 103)
	puts d.deck.length()

	# try to get 10 cards (should return nil)
	#cards = d.deal(10)
	#if (cards == nil)
	#	puts "yup, no cards"
	#end

	################################################

	d.discard(cards[0])
	d.showDiscard()
	d.discard(cards[1])
	d.showDiscard()
	d.discard(cards[2])
	d.showDiscard()
	puts d.top_card
	

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

if __FILE__ == $0 then

test_ServerMsg()
#test_Card_isValid()
#test_Deck()
#test_timer()

end #if
