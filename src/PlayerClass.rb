#!/usr/local/bin/ruby

class Player

    # Player.new(name) : constructor for object player
    def initialize (name)
        @name = name
        @score = 0
    end

    def getName ()
        return @name
    end

    def getScore ()
        return @score
    end
    
    def to_s ()
        return "Player: #{@name}, Score: #{@score}"
    end
    
end