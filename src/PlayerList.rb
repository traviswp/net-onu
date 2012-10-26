#!/usr/local/bin/ruby

require File.expand_path("./PlayerClass.rb")

class PlayerQueue
    
    @@number_of_players = 0

    #
    # Public constructor
    #
    def initialize ()
        @player_queue = Array.new
    end
    
    #
    # Add the specified player to the player_queue
    #
    # > Trying to add something not of type Player is a no-op
    #
    def add (player)
        if player.kind_of?(Player)
            
            #TODO: only add unique players (name modifier)

            @player_queue.push(player)
            @@number_of_players += 1
        else
            puts "You cannot add a non-player to the Player Queue"
        end
    end
    
    #
    # Remove the specified player from the player_queue
    #
    # > Trying to remove a non-existent player is a no-op
    # > Trying to remove something not of type Player is a no-op
    #
    def remove(player)
    
        if player.kind_of?(Player)
            rp = @player_queue.find { |aPlayer| aPlayer.getName == player.getName }
            if rp != nil then
                @player_queue.delete(rp)
                @@number_of_players -= 1
            end #if             
        end
    
    end
    
    #
    # Display a list of all of the players that are connected
    #
    def show()

        puts "-----------------------------------------"
        puts "Players connected:"
        
        if (@player_queue.length != 0)
            @player_queue.each { |player| puts player.getName() }
        else
            puts "..."
        end
        
        puts "-----------------------------------------"

    end
    
end
