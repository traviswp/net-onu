#!/usr/local/bin/ruby

require File.expand_path("./PlayerClass.rb")

class PlayerQueue
    
    #
    # Public constructor
    #
    def initialize()
        @player_list = Array.new()
		#@number_of_players = 0
    end
    
	#
	# Accessor for number of players in player queue
	#
	def getSize()
		return @player_list.size()
	end # getSize
	
	def getPlayers()
		return @player_list
	end # getPlayers
	
	
    #
    # Add the specified player to the player_queue
    #
    # > Trying to add something not of type Player is a no-op
    #
    def add(player)
        if player.kind_of?(Player)
            
            #TODO: only add unique players (name modifier)

            @player_list.push(player)
            #@number_of_players = @number_of_players + 1
        else
            puts "You cannot add a non-player to the Player Queue"
        end
		@player_list = @player_list.compact()
    end
    
    #
    # Remove the specified player from the player_queue
    #
    # > Trying to remove a non-existent player is a no-op
    # > Trying to remove something not of type Player is a no-op
    #
    def remove(player)
    
        if player.kind_of?(Player)
            rp = @player_list.find { |p| p.getName() == player.getName() }
            if rp != nil then
                @player_list.delete(rp)
                #@number_of_players = @number_of_players - 1
            end #if             
        end
		@player_list = @player_list.compact()
    
    end
    
	#
	# To String: a string of all player names in the player list
	#
	def to_s
		str = ""
		if (!@player_list.empty?) then
			@player_list.each{ |player|
				str += player.getName() + ","
			}
			str[-1] = ''
		end
		return str
	end
	
    #
    # Display a list of all of the players that are connected
    #
    def show()

        puts "-----------------------------------------"
        puts "Players connected:"
        
        if (@player_list.length != 0)
            @player_list.each { |player| puts player.getName() }
        else
            puts "no players connected..."
        end
        
        puts "-----------------------------------------"

    end
    
end
