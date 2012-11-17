#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'Deck'
require 'ServerMsg'
require 'PlayerList'
require 'time'

include ServerMsg

class GameServer

    #
    #
    # public class methods
    #
    #

    public

	attr_reader :deck
    
    def initialize(port, min, max, timeout, lobby)
	
        @port             = port                          # Port
        @game_in_progress = false                         # Game status boolean

		# variables: game-timer logic
		@timer            = timeout                       # Timer till game starts
        @game_timer_on    = false                         # Time until game starts
		@start_time       = 0
		@current_time     = 0

        # variables: service connections via call to 'select'
        @descriptors      = Array.new()                   # Collection of the server's sockets
        @server_socket    = TCPServer.new("", port)       # The server socket (TCPServer)
        @timeout          = timeout                       # Default timeout
        @descriptors.push(@server_socket)                 # Add serverSocket to descriptors
        
        # enables the re-use of a socket quickly
        @server_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        # variables: player management
        @players          = PlayerQueue.new()
        @waiting          = PlayerQueue.new()
		@current_players  = 0                             # Current number of players connected (for next/current game)
		@total_players    = 0                             # Total number of players connected
        @min_players      = min                           # Min players needed for game
        @max_players      = max                           # Max players allowed for game
        @lobby            = lobby                         # Max # players that can wait for a game
		@direction        = 1                             # direction of game play (1 or -1 for positive or negative, respectively)
		@step             = 1                             # increment @step players (normal: 1; skip: add 1 to make 2)
		@next             = 0                             # index of the next player

		# variables: deck/card management
		@deck = Deck.new()

		# variables: game states
		@state = :beforegame
		@states = [:beforegame,:startgame,:play,:deal,:waitaction,:discard,:afterdiscard,:endgame]

		@buffer           = ""

        log("UNO Game Server started on port #{@port}")

    end #initialize
    
    def run()

        begin # error handling block
        
            while true

				# service connections
				
                result = select(@descriptors, nil, nil, @timeout)
				
                if result != nil then
                
                    # Iterate over tagged 'read' descriptors
                    for socket in result[0]
                    
                        # ServerSocket: Handle connection
                        if socket == @server_socket then
                            accept_new_connection()
							@new_connection = true
                        else
							# ClientSocket: Read
                            if socket.eof? then
                                msg = "Client left #{socket.peeraddr[2]}:#{socket.peeraddr[1]}"
                                broadcast(msg + "\n", socket)
                                socket.close
                                @descriptors.delete(socket)
								
								# HACK?
								#player = ...? # set player to be deleted based on descriptor
								#@players.remove(player)
								@current_players = @current_players - 1
								@total_players = @total_players - 1
                            else #chat
								#TODO: might have to start buffering what I'm reading....could be losing messages
								data = socket.gets()
								socket.flush
                                msg = "[#{socket.peeraddr[2]}|#{socket.peeraddr[1]}]:#{data}"
                                broadcast(msg, socket)
                            end #if
                            
                        end #if
                    
                    end #for            

                end #if

				# service game state(s)
				
				puts "Players: " + @current_players.to_s
				#puts "Game Timer On: " + @game_timer_on.to_s
				#puts "Game In Progress: " + @game_in_progress.to_s
				
#				if (@game_timer_on)
#					@current_time = Time.now().to_i
#					puts "timer: " + ((@current_time-@start_time).abs()).to_s
#				end #if
				
				player_check = ((@min_players <= @current_players) && (@current_players <= @max_players))
				
				if (@game_in_progress && player_check) then                     # game in progress
					puts "service: game in progress - check game state(s)"
					# TODO: add conditional logic to check for game-end
					@game_in_progress = false                                   # game end: deactivate game_in_progress
				elsif (@game_timer_on) then
					@current_time = Time.now().to_i
					puts "timer: " + ((@current_time-@start_time).abs()).to_s

					if ((@current_time-@start_time).abs() > @timeout) then      # start game
						puts "service: starting game"
						@state = @states[1]
						@game_in_progress = true                                # set game_in_progress
						@game_timer_on = false                                  # turn timer off
					end #if
				elsif (player_check) then
					if (!@game_timer_on) then
						puts "service: activate game timer"
						@game_timer_on = true                                   # activate game timer
						@start_time = Time.now().to_i                           # set start_time
					end #if
					if (@new_connection) then
						puts "service: new connection & reset timer"
						@new_connection = false                                 # reset connection status
						@start_time = Time.now().to_i                           # reset start_time
					end #if
				elsif (@new_connection && @game_in_progress) then               # player joing after game is full/game started
					puts "service: add player to lobby & wait for next game"
					@new_connection = false
				elsif (@new_connection && !@game_in_progress) then              # player joing after game is full/game started
					puts "service: (initial) new connection"
					@new_connection = false
				end #if
				
				#
				# Game States
				#
				
				if (@state == @states[0]) # before game
					puts "before game"
					#beforeGame()
				elsif (@state == @states[1]) # start game
					startGame()
				elsif (@state == @states[2]) # deal
					deal()
				elsif (@state == @states[3]) # play game
					play()
				elsif (@state == @states[4]) # wait for player action
					waitForAction()
				elsif (@state == @states[5]) # process discard
					discard()
				elsif (@state == @states[6]) # post-discard game handling
					postDiscard()
				elsif (@state == @states[7]) # end of game
					endGame()
				end # games states
				
            end #while

        rescue Interrupt
            puts "\nserver application interrupted: shutting down..."
            exit 0
        rescue Exception => e
            puts 'Exception: ' + e.message()
            print e.backtrace.join('\n')
            #retry
        end # error handling block
        
    end #run
    
    #
    # private class methods
    #

    private

    def log(msg)
        puts "log: " + msg.to_s
    end #log
    
    def broadcast(msg, omit_sock = nil)
        
        # Iterate over all known sockets, writing to everyone except for
        # the omit_sock & the serverSocket
        @descriptors.each do |client_socket|
            
            if client_socket != @server_socket && client_socket != omit_sock then
                client_socket.write(msg)
				#client_socket.flush
            end #if
            
        end #each
        
        log(msg)
                    
    end #broadcast
    
    def accept_new_connection()
        
        # Accept connect & add to descriptors
        new_socket = @server_socket.accept
        @descriptors.push(new_socket)

        # Send acceptance message
        args = new_socket.gets()

        ########################################
        client_name = name_validation(args)
		
		# create Player object
		p = Player.new(client_name)

		# add player to player list
		@players.add(p)
		
		@current_players = @current_players + 1
		@total_players = @total_players + 1
        ########################################

        msg = ServerMsg.message("ACCEPT",[client_name])
        #puts "message: " + msg
      
        new_socket.write(msg)

        # Broadcast 
        #msg = "Client joined #{new_socket.peeraddr[2]}:#{new_socket.peeraddr[1]}\n"
		msg = "#{client_name} has joined\n"
        broadcast(msg, new_socket)

    end #accept_new_connection
    
    def process_command(cmd)
        #TODO: regular expressions to validate command

        # Validate Command

        # Validate Number of Arguments

        # Validate Arguments (If Applicable)

        return cmd
    end #process_command

    #
    # Input : string name
    # Return: string name
    #    + If the name is already in existence, modify the name and return it
    #    
    def name_validation(cmd)
        #TODO: regular expressions to validate a client name

        # Match (1) the command and (2) the content of the message
        re = /\[([a-z]{2,9})\|([\w\W]{0,128})\]/i
        args = cmd.match re

        if args != nil then
            command = args[1]
            name    = args[2]
        else
            return nil; 
        end #if

        # Modify name if it is in use already
        exists = false
        numId = 1
        while exists
            #exists = @players.find { |n| n.getName() == name }
            if exists then
                name = name + numId.to_s
                numId = numId + 1
            else
                break
            end #if

        end #while

        return name

    end #name_validation

	#######################################################################

	def players()
		#return @players.compact()
		return @players
	end

	def waiting()
		#return @waiting.compact()
		return @waiting
	end

	def min?()
		return (players.size() >= 2)
	end

	def add_player(player)
		if (players.size() < @max_players) then
			#@players[position(nil)] = player unless @players.include? player
			@players << player unless @players.include? player
			return true
		elsif (waiting.size() < @lobby) then
			#@waiting[position(nil)] = player unless @waiting.include? player
			@waiting << player unless @waiting.include? player
			return true
		else
			return false
		end
	end

	def remove_player(player)
		@players[position(player)] = nil
	end

	def [](index)
		return players[index]
	end

	def position(player)
		return players.index(player)
	end

	def has_player?(player)
		return @players.include? player
	end

	#######################################################################

	#
	# Server States
	#

	def beforeGame()

		# service: connections

			# send: [ACCEPT|...] or [WAIT|...]

			# send: [PLAYERS|...]

			# parse msg & determine action

		# service: chat

		# (service: timer)

		# service: game states

	end

	def startGame()
		
		puts "state: start game" ###DEBUG

		# send [STARTGAME|...] (report all active players for game play)
		msg = ServerMsg.message("STARTGAME",[players])
		broadcast(msg)
		
		# call deal()
		deal()

		# start game play
		play()

	end 

	def play()
	
		puts "state: play"

		#loop

			# send [GO|CV]

			# (new state: waitForAction)
			

	end

	def waitForAction()
		puts "state: waitForAction"

		# simply wait for current player to discard

			# if discard: (new state: discard)

			# if timeout:
			#    - drop/skip player? (new state: postDiscard)

	end

	def discard(card)
		puts "state: discard"

		attempt = 0

		# check if the play is valid
		# 	1. does player have that card
		# 	2. is card valid/playable?
		#
		# call: cardValidation(card)

		# determine card type & appropriate action to take:

			# valid number card

			# skip

			# reverse

			# draw 2

				# wild

			# draw 4

				# wild

			# wild

			# can't play (draw 1 card - if still can't play, skip player)

				# if attempt == 0 then 
				#     draw(1)
				#     attempt = 1
				# else 
				#     

		# if valid play: (new state: afterDiscard())

	end

	def afterDiscard()
		puts "state: afterDiscard"

		# send [PLAYED|playername,CV]

		# check: [UNO|playername]

		# 
		# check: endGame (new state: endGame)
		# or
		# (new state: play)
		#

	end

	def endGame()
		puts "state: endGame"

		# send [GG|winning_player_name]
	end

	#######################################################################

	#
	# Server State Helper Methods
	#

	def draw(n)
		# send [DEAL|cards(1..n)] 
	end

	def cardValidation(card)
		# send [INVALID|message]
	end

	def getCurrentPlayer()
	
	end

	def getCurrentPlayerHand()

	end

	#######################################################################

	#
	# Deal: the initial deal gives each player 7 cards
	#
	def deal()
		# send [DEAL|...] (initial deal: everyone gets 7 cards)
		players().each{ |player| player.cards = @deck.deal(7) }
	end

	#
	# Reverse: reverses the play order
	#
	def reverse!()
		@direction = @direction * (-1)
		skip!(2)
	end

	#
	# Skip: skips count players in the current play order
	#
	def skip!(count = 1)
		@next += (count * @direction)
	end

	#
	# Give Card: gives player n cards
	#
	def give_card(player, n)
		if has_player?(player) then
			players()[postition(player)].cards << @deck.deal(n)
		end
	end

	#
	# Next Player: returns the next
	#
	#def next_player(player)
	#	list_len = players().size()
	#	# TODO: still need to make it to where @step accounts for "skips"
	#	index = (position(player) + (@step * @direction)) % list_len
	#	return [](index)
	#end 

	#
	# Full Reset: create a new (shuffled) deck & clear each players hand
	#
	def full_reset
		@deck = Deck.new()
		@players.each{ |player| player.reset() }
	end

	#######################################################################


end #GameServer
