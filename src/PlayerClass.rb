#!/usr/local/bin/ruby

class Player

    # Player.new(name) : constructor for object player
    def initialize (name)
        @name = name
        @games_won = =0
        @games_played = 0
    end #initialize

    def getName ()
        return @name
    end #getName

    def getStats ()
        stats = "After #{@games_played} games, you have won #{@games_won}." 
    end #getStats
    
    def to_s ()
        return "Player: #{@name}"
    end
    
end
