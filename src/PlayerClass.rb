#!/usr/local/bin/ruby

class Player

	attr_reader :name
	attr_reader :cards
	attr_reader :games_won
	attr_reader :games_played

	#
    # Player.new(name) : constructor for object player
	#

    def initialize(name)
        @name         = name
		@cards        = []
        @games_won    = 0
        @games_played = 0
    end #initialize

	#
	# Getters & Setters
	#

    def getName()
        return @name
    end #getName

	def discard(card)
		if ((card.kind_of? Card) && (card != nil))
			if (@cards.include?(card)) then
				return @cards.delete_at(0)
			end
				return "you don't have the card: #{card}"
		end
		return "#{card} is not a valid card"
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
		str = ""
		str += "Player: #{@name}| Cards: "
		@cards.each{ |c|
			str += c
		}
		str += "\n"
		str += getStats()
        return str
    end #toString
    
end
