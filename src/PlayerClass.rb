#!/usr/local/bin/ruby

class Player

	#
    # Player.new(name) : constructor for object player
	#

    def initialize(name)
        @name         = name
        @games_won    = 0
        @games_played = 0
    end #initialize

	#
	# Getters & Setters
	#

    def getName()
        return @name
    end #getName

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

	#
	# Game Stats & Basic Output
	#

    def getStats()
        stats = "After #{@games_played} games, you have won #{@games_won}." 
    end #getStats
    
    def toString()
        return "Player: #{@name}"
    end #toString
    
end
