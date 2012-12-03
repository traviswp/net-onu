#!/usr/local/bin/ruby

class Player

	attr_reader :name
	attr_reader :socket
	attr_reader :cards
	attr_reader :games_won
	attr_reader :games_played

	#
    # Player.new(name, socket#) : constructor for object player
	#

    def initialize(name, socket)
        @name         = name
		@socket       = socket
		@cards        = []
		@card         = Card.new()
        @games_won    = 0
        @games_played = 0
    end #initialize

	#
	# Getters & Setters
	#

    def getName()
        return @name.to_s
    end #getName

	def getSocket()
		return @socket
	end

	def getCards()
		return @cards
	end

	def getCardCount()
		return @cards.length()
	end

	def reset!()
		@cards = []
	end

	def discard(card)

		# card represented as a string
		if ((card.kind_of? String) && (card != nil)) then

			# validate form (redundant...)
			valid = @card.valid_str?(card)
			if (!valid) then
				return nil
			end

			# verify existence
			cards = @cards
			pre = card[0].chr
			suf = card[1].chr
			pos = nil
			found = false
			cards.each { |c|
				if (c.prefix == pre && c.suffix == suf) then
					pos = @cards.index(c)
					found = true
				elsif (c.suffix == "W" && suf == "W") then # special: wild?
					pos = @cards.index(c)
					found = true
				elsif (c.suffix == "F" && suf == "F") then # special: wild draw 4?
					pos = @cards.index(c)
					found = true
				end			
			}

			# if found = false, the player does not have a discardable card
			if (!found) then
				return nil
			end 

			if (pos != nil) then
				@cards.delete_at(pos)
				return pos
			end

			return nil# "you don't have the card: #{card}"
		end

		# card represented as a Card
		if ((card.kind_of? Card) && (card != nil)) then

			# validate form (redundant...)
			valid = @card.valid_card?(card)
			if (!valid) then
				puts "is nil"
				return nil
			end

			# verify existence
			cards = @cards
			pre = card.getColor()
			suf = card.getIdentifier()
			pos = nil
			found = false
			cards.each { |c|
				if (c.prefix == pre && c.suffix == suf) then
					pos = @cards.index(c)
					found = true
					break
				elsif (c.suffix == "W" && suf == "W") then # special: wild?
					pos = @cards.index(c)
					found = true
					break
				elsif (c.suffix == "F" && suf == "F") then # special: wild draw 4?
					pos = @cards.index(c)
					found = true
					break
				end			
			}

			# if found = false, the player does not have a discardable card
			if (!found) then
				return nil
			end 

			if (pos != nil) then
				c = @cards.delete_at(pos)
				return pos
			end

			return nil# "you don't have the card: #{card}"
		end
	end

#	def playing?()
#		return
#	return 

#	def waiting?()
#		return
#	return 

	def getGamesWon()
		return @games_won
	end #getGamesWon

	def setGamesWon()
		@games_won = @games_won + 1
	end #setGamesWon

	def getGamesPlayed()
		return @games_played
	end #getGamesPlayed

	def setGamesPlayed()
		@games_played = @games_played + 1
	end #setGamesPlayed

	def reset()
		@cards = []
	end

	#
	# Game Stats & Basic Output
	#

    def getStats()
        stats = "After #{@games_played} games, you have won #{@games_won}.\n" 
    end #getStats
    
    def to_s()
		str = "Cards: "
		@cards.each{ |c|
			str += c.to_s + ","
		}
		str[-1] = ""
		#str += getStats()
        return str
    end #toString
    
end
