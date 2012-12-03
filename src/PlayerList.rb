#!/usr/local/bin/ruby

require File.expand_path("./PlayerClass.rb")

class PlayerList
    
    #
    # Public constructor
    #

	attr_reader :player_list

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
	
	def getList()
		return @player_list
	end # getPlayers
	
	def getPlayerFromPos(pos)
		rp = @players_list.at(pos)
	end

	def getPlayerFromSocket(socket)
		rp = @player_list.find { |player| player.socket == socket }
		return rp
	end # getPlayerBySocket	

	def getSocketFromPlayer(player)

		if player.kind_of?(Player)
			rp = @player_list.find { |p| p.socket == player.socket }

			if rp != nil then
				return rp.socket
			end
		else 
			puts "sorry, can't get socket from non-player"
		end

	end # getPlayerBySocket	

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
    
	def list()
		l = []
		@player_list.each { |player|
			l << "#{player.getName()}"
		}
		return l
	end

	#
	# To String: a string of all player names in the player list
	#
	def to_s
		str = ""
		if (!@player_list.empty?) then
			@player_list.each{ |player|
				str += "#{player.getName()}:[#{player.to_s}]"
				str += "\n"
			}
			str[-1] = ''
		end
		return str
	end
    
end
