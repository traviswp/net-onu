#!/usr/bin/env ruby

# Sockets are in the standard library
require 'socket' 
require 'Deck'
require 'ServerMsg'
require 'PlayerClass'
require 'PlayerList'
require 'time'

include ServerMsg

class GameServer

    ######################################################################
	#                                                                    #
    #                         public class methods                       #
	#                                                                    #
    ######################################################################

    public

	attr_reader :deck
    
    def initialize(port, min, max, timeout, lobby)
	
		# variables: support logging
		file = "../logs/server-log.txt"
		@log = File.new(file, "w+")                       # Log file for server activity

		# variables: game environment
        @min              = min                           # Min players needed for game
        @max              = max                           # Max players allowed for game
        @lobby            = lobby                         # Max # players that can wait for a game
		@direction        = 1                             # direction of game play (1 or -1 for positive or negative, respectively)
		@step             = 1                             # increment @step players (normal: 1; skip: add 1 to make 2)

		# variables: game-timer logic
		@timeout          = timeout                       # Timer till game starts
        @game_timer_on    = false                         # Time until game starts
		@start_time       = 0
		@current_time     = 0

        # variables: service connections via call to 'select'
        @port             = port                          # Port
        @r_descriptors    = Array.new()                   # Collection of server's read sockets
        @server_socket    = TCPServer.new("", port)       # The server socket (TCPServer)
        @r_descriptors.push(@server_socket)               # Add serverSocket to descriptors
		@message_queues  = Hash.new()                     # Contains buffers for interaction with each individual client
        
        # enables the re-use of a socket quickly
        @server_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        # variables: player management
		@players          = PlayerList.new()              # List of all players (active)
        @waiting          = PlayerList.new()              # List of all other players (waiting)
		@total_players    = 0                             # Total number of players connected

		@current          = 0                             # index of the current player whose turn it is
		@playerPlayed     = nil                           # Reference to current player who is playing
		@card             = nil                           # Reference to the card played by the current player
		@attempt          = 0                             # The attempt count that the player is on (between 0 & 2)
		@action           = nil                           # Represents the action associated with the card played by the current player

		@player_timer_on  = false
		@player_start     = 0
		@inactive_wait    = Constants::PLAYER_TIMEOUT     # Default player response time - drop connection if exceeded

		############################ DEBUG ############################
		@player_strikes_allowed   = 5
		############################ TESTING ############################
		@count = 0
		############################ TESTING ############################

		# variables: deck/card management
		@deck = Deck.new()

		# variables: game states
		@state     = :beforegame
		@states    = [:beforegame, :startgame, :play, :waitaction, :afterdiscard, :endgame]
		@actions   = [:none, :skip, :reverse, :draw2 ,:draw4, :wild]
		@commands  = [:chat, :play, :join, :invalid]

        log("UNO Game Server started on port #{@port}")

    end #initialize
    
    def run()

        begin # error handling block

            while true

				#############################################################
				# Service Connections/Disconnections & Process Client Input #
				#############################################################

				@new_connection = false
				
                result = select(@r_descriptors, nil, nil, 0)
				
                if result != nil then
                puts "#{result}"
                    # Iterate over tagged 'read' descriptors
                    for socket in result[0]
                    
                        # ServerSocket: Handle connection
                        if socket == @server_socket then

                            accept_new_connection()
							@new_connection = true

                        else # ClientSocket: Read

							# check: closed connection
                            if socket.eof? then
								close_connection(socket)
							# check: process incoming client messages
                            else
								read(socket)
                            end #if

                        end #if
                    
                    end #for            

                end #if

				#############################################################
				#                  Pre-Service Game State(s)                #
				#############################################################
				
				################################################################
				#TODO: move (all of) this checking into the beforeGame() method
				
				player_check     = (min_check? && max_check?)   # check: player count 
				game_in_progress = (@states.index(@state) > 0)  # check: game status
				################################################################
#puts "<#{@players.getSize()}><#{@waiting.getSize()}> player-check: [#{player_check}: <#{min_check?}><#{max_check?}>] | game_in_progress: [#{game_in_progress}]"

				# game in progress
				if (game_in_progress) then

					# check: minimum amount of players are connected
					if (@players.getSize() == 1) then

						# set game environment variables
						@state = :beforegame
						@game_timer_on = false

						# log & notify player(s)
						msg = ServerMsg.message("GG", @players.list())
						log (msg)
						broadcast(msg, nil)

					end

				else # game NOT in progress (before game)

					#check: timer has started (min_check? and max_check? was satisfied)
					if (@game_timer_on) then

						# get: current timestamp
						@current_time = Time.now().to_i
						#puts "timer: " + ((@current_time-@start_time).abs()).to_s

						#check: game timer expired
						if ((@current_time-@start_time).abs() > @timeout) then  # start game
							@state = :startgame                                  # state: start
							@game_timer_on = false                               # turn timer off
						end

					#end

					# check: min_check? & max_check? still satisfied
					elsif (player_check) then

						# check: activate timer if it isn't already running
						if (!@game_timer_on) then
							@game_timer_on = true                               
							@start_time = Time.now().to_i                       
						end

						# check: new connection - add to game
						if (@new_connection) then
							#puts "service: new connection & reset timer"
							@start_time = Time.now().to_i                       # reset start_time
						end #if

					else # player_check failed & game is not in progress - wait for connections
						  # or see if anyone is waiting from a previous game...
     					  # check if players from waiting list can move to players list

						while ( (@players.getSize() + 1 <= @max) && (@waiting.getSize() > 0) ) do

							# move player from one list to another
							player = @waiting.getFront()
							@players.add(player)

							log("moving #{player.getName()} from waiting to players list")
sleep(2)
							log(@players.list())
							log(@waiting.list())
						end



					end #if

				end

				# check: drop player due to inactivity
				if (@state == :waitaction) then

					current_time = Time.now().to_i
					if ((current_time - @player_start).abs() >= @inactive_wait) then

						# drop the player & continue
						player = getPlayerFromPos(@current)
						name = player.getName()
						drop_connection(player)

						# log action
						log("#{name}: connection dropped: exceeded max inactivity time")
	
					end

				end

				#############################################################
				#                    Service Game State(s)                  #
				#############################################################
				
				# TODO: before checking game states, make a method which runs through
				#       various conditions, ensuring that the game is still "eligible"
				#       - number of players > 1
				#       - ...?
				
				if (@state == @states[0]) then # before game
					#puts "before game"
					#beforeGame()
				elsif (@state == @states[1]) then # start game
					startGame()
				elsif (@state == @states[2]) then # play game
					play()
				elsif (@state == @states[3]) then # wait for player action
					waitForAction()
				#elsif (@state == @states[4]) then # post-discard game handling
				#	afterDiscard()
				#elsif (@state == @states[5]) then # end of game
				#	endGame()
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
    
    ######################################################################
	#                                                                    #
    #                         private class methods                      #
	#                                                                    #
    ######################################################################

    private

    def log(msg)
		logMsg = "log: #{msg}\n"
		puts logMsg
		@log.syswrite(logMsg)
    end # log
	
	def err(msg)
		errMsg = "error: #{msg}"
		log(errMsg)
	end # err
    
	#
	# x can be either a socket descriptor or a player. In either case, the 
	# appropriate socket descriptor is located and msg is written to only
	# that client
	#
	def send(msg, x)
		name = ""
		if (x.kind_of? Player) then
			socket = @players.getSocketFromPlayer(x)
			if socket != nil then
				begin
					socket.write(msg)
				rescue Exception => e
					err("There was a write error in 'send'. message = #{msg} & socket = #{socket}")
sleep(5)
				end
			end
		else
			socket = @r_descriptors.find{ |s| s == x }
			if socket != nil then
				begin
					socket.write(msg)
				rescue Exception => e
					err("There was a write error in 'send'. message = #{msg} & socket = #{socket}")
sleep(5)
				end
			else 
				begin
					x.write(msg)
				rescue Exception => e
					err("There was a write error in 'send'. message = #{msg} & socket = #{socket}")
sleep(5)
				end
			end			
        end #if
	end # send

    def broadcast(msg, omit_sock = nil)
        
		if msg != nil then

		    # Iterate over all known sockets, writing to everyone except for
		    # the omit_sock & the serverSocket
		    @r_descriptors.each do |client_socket|
		        
		        if client_socket != nil && client_socket != @server_socket && client_socket != omit_sock then

					begin
			            client_socket.write(msg)
					rescue Exception => e
						err("There was a write error in 'broadcast'. message = #{msg} & socket = #{client_socket}")
sleep(5)
					end

		        end #if
		        
		    end #each
		    
		    log("broadcast: " + msg)

		end
                    
    end #broadcast
    

	#########################################################################

    def accept_new_connection()
        
        # Accept connect
        new_socket = @server_socket.accept

		# Add new socket to descriptors
		@r_descriptors.push(new_socket)

		# Create a queue for each connection
		@message_queues[new_socket] = ""

		# Special call to read (expecting JOIN message)
		read(new_socket)

    end # accept_new_connection
    
	#########################################################################

	def remove_player(socket)

		# remove player
		player = @players.getPlayerFromSocket(socket)

		# check: determine if player was in the game or waiting (remove from the appropriate list)
		if player != nil then

			# put cards back in deck
			cards = player.getCards()
			@deck.put_back(cards)

			# physically remove player from list
			@players.remove(player)

			# Broadcast updated player list to all players (player left)
			msg = ServerMsg.message("PLAYERS", @players.list())
			broadcast(msg, socket)		#broadcast(msg, socket)

		else 

			# physically remove player from list
			player = @waiting.getPlayerFromSocket(socket)
			@waiting.remove(player)

		end

		# update game/lobby count
		@total_players = @total_players - 1

	end

	def close_connection(socket) 

		# store local reference of player
		player_in_game = @players.getPlayerFromSocket(socket)

		# handle descriptors
		socket.close()
		@r_descriptors.delete(socket)

		#
		# check: player's status
		#

		# check: player is waiting (not a player in the game)
		if player_in_game == nil then

			remove_player(socket)

		# check: player is playing in the game
		else

			remove_player(socket)

			# check: if game in progress, move to next player
			if ((@state != :beforegame) && (@state != :endgame)) then

				# check: only call play if that is a possible action
				if (@players.getSize() > 1) then

					move()
					play()

				elsif (@players.getSize() == 1) then

					puts "do something on this special 1 case?"

				end

			end

		end

	end # close_connection

	def drop_connection(player)
		socket = @players.getSocketFromPlayer(player)
		close_connection(socket)
	end # drop_connection
	
	def read(socket)

		while(true)
			# read: input on clientSocket

			# TODO: handle new lines?
			begin
				puts "just before read..."
				data = socket.read(1)
				data.chomp!
			rescue Exception => e
	            print e.backtrace
				exit(0)
				return nil
			end

			if data == nil then
				puts "error: nil valued 'read'"
				exit(0)
				return nil
			end

			# check: dropped/closed connection
			if data == "" then
				puts "dropped"
				#dropped_connection()
				exit (0)
				return nil
			end

			# update: @message_queues[socket]
			@message_queues[socket] = @message_queues[socket] + data

			#puts "buffer <#{@message_queues[socket]}>" #TODO: remove (debug)

			# validate: @message_queues[socket]
			result = validate(data, socket) #@message_queues[socket]
	
			# check: complete message from server?
			if result == nil then          # invalid command/argument(s)
				# do nothing
			elsif result[0] == "drop" then # valid command, empty contents (drop)
				#break
			elsif result != nil then       # valid command with valid argument(s)

				# process message
				command = result[0].to_s
				arguments = result[1].to_s
				process(command, arguments, socket)
				#break
				return true
			end

		end

		return true

	end #read

	def process(command, args, socket)

puts "process: [#{command}|#{args}]"

		if (command == "CHAT") then
			handle_chat(args, socket)
		elsif (command == "JOIN") then
			handle_join(args, socket)
		elsif (command == "PLAY") then
			handle_play(args, socket)
		else
			# error - shouldn't get invalid messages from the server
			err("error in method 'process'. unrecognized command '#{command}'")
		end

	end

	def handle_chat(message, socket)

		if socket != nil then

			# check: does the 'chatter' belong to the players list?
			playerName = @players.getPlayerFromSocket(socket).getName()

			# check: player not found? check list of waiting players
			if playerName == nil then
				playerName = @waiting.getPlayerFromSocket(socket).getName()
			end

			msg = ServerMsg.message("CHAT", [playerName, message])
			broadcast(msg, socket)

		end

	end

	def handle_join(name, socket)

        ########################################
		# Validation
        result = name_validation(name)
        ########################################

		# invalid join
		if result == nil then
			return
		end

		# check: valid results consist of an array of 1 element (the name)
		if (result.size() == 1) then

			# Update player counts
			@total_players = @total_players + 1

			# Create Player object & add to player list
			name = result[0]
			p = Player.new(name, socket)

			# Add player to the appropriate list
			if ((@players.getSize() + 1) <= @max) then

				if (@state == :beforegame || @state == :endgame) then

					# Inform player of acceptance
					msg = ServerMsg.message("ACCEPT",[name])		  
					send(msg, socket)

					@players.add(p)
					log("adding #{p.getName()} to players list")

					# Broadcast updated player list to all players
					# note: don't send list of waiting players!
					msg = ServerMsg.message("PLAYERS", @players.list())
					broadcast(msg, nil)
				else

					# Inform player they must wait
					msg = ServerMsg.message("WAIT",[name])		  
					send(msg, socket)

					@waiting.add(p)
					log("adding #{p.getName()} to waiting list - below max")
				end

			else
				# Inform player they must wait
				msg = ServerMsg.message("WAIT",[name])		  
				send(msg, socket)

				@waiting.add(p)
				log("adding #{p.getName()} to waiting list - above max")
			end		   

		else

			# invalid join request: drop connection
			message = result[1] # details
			handle_invalid(message, socket)
			log(message)
			socket.close()

		end

	end

	def handle_play(card, socket)

		# play validation handled in game states - set player & card...

		@playerPlayed = @players.getPlayerFromSocket(socket)          # type: Player
		@card = Card.new(card[0].chr.upcase(), card[1].chr.upcase())  # type: Card

	end

	def handle_invalid(message, socket)

		# check: find offending player
		player = @players.getPlayerFromSocket(socket)

		# check: if player is nil, player must be a waiting player
		if player == nil then
			player = @waiting.getPlayerFromSocket(socket)
		end

		# add strike to offending player
		player.addStrike()

		# inform the player
		msg = ServerMsg.message("INVALID", [message])
		send(msg, socket)

	end

	def validate(data, socket)
		
		######################################################
		# validating contents of the @message_queues[socket] #
		######################################################

		# match:
		#    command   (letters only; 2-9 characters)
		#    arguments (anything up to the first ']' character)
		re = /\[([a-zA-Z]{2,9})\|(.*?)\]/i
		m = @message_queues[socket].match re

		# upon matching: (1) set command, (2) set command info, and (3) remove
		#  this portion of the message from @buffer
		if m != nil then
			command = m[1].upcase()
			info    = m[2]
			@message_queues[socket].sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
		else
			#puts "received #{data}" #DEBUG
			return nil
		end

		# check: remove new line characters
		info.gsub!(/\\n/,"")

		#
		# validate command 
		#

		if !(ServerMsg.valid?(command)) then
			return nil
		end

		#validate: info following command
		if (info.size() < 1) then
			return ["drop"] # just drop empty commands
		elsif (info.size() > 128) then
			msg = "message error: [#{command}|#{info}] violates max message length constraint (128 characters)" #DEBUG
			handle_invalid(msg, socket)
			err(msg)
			return nil
		end	

		return [command,info]

	end # validation

    #
    # Input : string name
    # Return: string name
    #    + If the name is already in existence, modify the name and return it
    #    
    def name_validation(name)

		if (name == "") then 
			msg = "sorry, you must provide a valid name for the 'JOIN' request - on connect send: '[JOIN|player-name]'."
			return ["INVALID", msg]		
		end 

		# Modify name if it is in use already
		numId = 1
		tmp = name
		while true
			exists = @players.getList().find { |p| p.getName == tmp }
			if exists != nil then
				tmp = name + numId.to_s
				numId = numId + 1
			else
				name = tmp
				break
			end # if
		end # while

		return [name]

    end # name_validation

    ######################################################################
	#                                                                    #
    #                            Server States                           #
	#                                                                    #
    ######################################################################


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
		
		# send [STARTGAME|...] (report all active players for game play)
		msg = ServerMsg.message("STARTGAME", @players.list())
		broadcast(msg)
		
		# initial deal
		deal()

		# new state: play
		@state = :play

	end 

	def play()
	
		player = getCurrentPlayer()

		# send [DEAL|cards] if the last card played was a draw 2 or draw 4
		if (@action == :draw2) then
			draw(player, 2)
		elsif (@action == :draw4) then
			draw(player, 4)
		end
		@action = :none

		# send [GO|CV]
		if player != nil then
			msg = ServerMsg.message("GO", [top.to_s]) 
			send(msg, player)

			# (new state: waitForAction)
			@state = :waitaction
			@player_start = Time.now().to_i
		else
			err("player is nil? check method 'play'")
			exit 0
		end

	end

	def waitForAction()

		# simply wait for current player to discard
		playerCurrent = getCurrentPlayer()
		#puts "state: waitForAction - waiting for #{playerCurrent.getName()} to play!" ###DEBUG

		# check: if playerPlayed is current player, process the played card
		if (@playerPlayed == playerCurrent) then

			# process the discard for validity
			discard()

			# reset most recent play variables
			@playerPlayed = nil
			@card = nil

		# check: playerPlayed != current player - that's a strike!
		elsif @playerPlayed != nil then

			# penalize player playing out of turn
			@playerPlayed.addStrike()

			# check: player exceeded allowed strikes
			if (@playerPlayed.getStrikes == @player_strikes_allowed) then
				drop_connection(@playerPlayed)
			end

		end

	end

	def discard()

		card = Card.new()
		cards = getCurrentPlayerHand()

		# check: is this a valid card?
		result = card.valid_card?(@card) # *** this is redundant - card was validated in method 'process' ***
		if (!result) then
			msg = "sorry, '" + @card.to_s + "' is not a valid card."
			msg = ServerMsg.message("INVALID", [msg])
			send(msg, @playerPlayed)
			return
		end

		# check: is card playable? (check the top card)
		result = playable?(@card)
		if (!result) then
			msg = "sorry, '" + @card.to_s + "' cannot be played right now. the top card is: " + top().to_s
			msg = ServerMsg.message("INVALID", [msg])
			send(msg, @playerPlayed)
			return
		end

		# check: does the player have this card?
		pre = @card.getColor()
		suf = @card.getIdentifier()
		pos = nil
		found = false
		if !(@card.to_s == "NN") then
			cards.each { |c|
				if (c.prefix == pre && c.suffix == suf) then
					pos = cards.index(c)
					found = true
					break
				elsif (c.suffix == "W" && suf == "W") then # special: wild?
					pos = cards.index(c)
					found = true
					break
				elsif (c.suffix == "F" && suf == "F") then # special: wild draw 4?
					pos = cards.index(c)
					found = true
					break
				end			
			}

			# if found = false, the player does not have a discardable card
			if (!found) then
				msg = "sorry, you cannot play '" + @card.to_s + "' because you do not have that card."
				msg = ServerMsg.message("INVALID", [msg])
				send(msg, @playerPlayed)
				return
			end
		end

		#####################################################
		# determine card type & appropriate action to take: #
		#####################################################

		if ((@action == :none) && (@card.to_s == "NN")) then # no play

			@attempt = @attempt + 1

			if (@attempt == 1) then
				# current player draw 1
				draw(@playerPlayed, 1)

				# issue go command to player to try again
				msg = ServerMsg.message("GO", [top.to_s]) 
				send(msg, @playerPlayed)
				return
			end
		
		elsif ((@action == :none) && (@card.to_s != "NN")) then # no action - valid play (wild or number card

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			@playerPlayed.discard(@card)

		elsif (@action == :skip) then # skip

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			@playerPlayed.discard(@card)

			#skip next player
			skip!()

		elsif (@action == :reverse) then # reverse

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			@playerPlayed.discard(@card)

			#reverse direction
			reverse!()

		elsif (@action == :draw2) then # draw 2

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			@playerPlayed.discard(@card)

			#next player draws 2 cards

		elsif (@action == :wild) then # wild

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			#c = Card.new("N","W")
			#@playerPlayed.discard(c)
			@playerPlayed.discard(@card)

		elsif (@action == :draw4) then # draw 4

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
			#c = Card.new("N","F")
			#@playerPlayed.discard(c)
			@playerPlayed.discard(@card)

			#next player draws 4 cards
		end

		# set game environment variables
		@attempt = 0
		@state = :afterdiscard
		afterDiscard()

	end

	def afterDiscard()

		# send [PLAYED|playername,CV]
		msg = ServerMsg.message("PLAYED", [@playerPlayed.getName(),@card.to_s])
		broadcast(msg, nil)

		# check: [UNO|playername]
		result = unoCheck()
		if (result)
			msg = ServerMsg.message("UNO", [@playerPlayed.getName()])
			broadcast(msg, @playerPlayed.getSocket())
		end 

		#####################################################################
		#####################################################################
		#####################################################################
		log("--------------------------------------------------------#{@count}")
		log("Playing Players:\n#{@players.to_s}")
		@players.getList().each{ |p| log("#{p.getSocket()}") }
		log("-----------------------------------------------------------")
		log("#{@deck.showDeck()}")
		log("Waiting Players: #{@waiting.list().join(",")}")
		log("-----------------------------------------------------------")
		@count = @count + 1
		#####################################################################
		#####################################################################
		#####################################################################

		# check: end of game
		result = gameEndCheck()
		if (result) # end of game
			@state = :endgame
			endGame()
		else # game still in progress
			move()
			@state = :play
		end

	end

	def endGame()
		#puts "state: endGame" ###DEBUG

		# send [GG|winning_player_name]
		msg = ServerMsg.message("GG",[@playerPlayed.getName()])
		broadcast(msg, nil)

		# reset player cards & the game deck
		full_reset()

		# check if players from waiting list can move to players list
log("check waiting queue before moving on...<#{max_check?}><#{@waiting.getSize()}>")
		while ( (@players.getSize() + 1 <= @max) && (@waiting.getSize() > 0) ) do
log("before <#{@players.getSize()}><#{max_check?}><#{@waiting.getSize()}>")
			# move player from one list to another
			player = @waiting.getFront()
			@players.add(player)

			log("moving #{player.getName()} from waiting to players list (end of full game)")
sleep(2)
			log(@players.list())
			log(@waiting.list())
log("after <#{@players.getSize()}><#{max_check?}><#{@waiting.getSize()}>")
		end
log("done checking queue")
		# reset game state
		@state = :beforegame
	end

    ######################################################################
	#                                                                    #
    #                   Server State Helper Methods                      #
	#                                                                    #
    ######################################################################

	#
	# Deal: the initial deal gives each player 7 cards
	#
	def deal()
		@players.getList().each { |player|
			draw(player, 7)
		}		
	end # deal

	#
	# Draw: gives player n cards
	#
	def draw(player, n)
		cards = @deck.deal(n)
		player.cards.concat(cards)
		msg = ServerMsg.message("DEAL", card_list(cards))
		send(msg, player)
	end # draw

	#
	# Card_List: construct a list of cards where cards are represented as strings
	#
	def card_list(cards)
		list = []
		cards.each { |card|
			list << card.to_s
		}
		return list
	end # card_list

	def top()
		return @deck.getTopCard()
	end # top

	#
	# Move: moves @current to the index of the next player
	#
	def move()
		@current = (@current + (1 * @direction)) % @players.getSize()
	end

	#
	# Reverse: reverses the play order
	#
	def reverse!()
		@direction = @direction * (-1)
	end

	#
	# Skip: skips count players in the current play order (default 1)
	#
	def skip!(count = 1)
		move()
	end

	#
	# Playable: 
	#
	def playable?(card)

		top_color      = top().getColor()
		top_identifier = top().getIdentifier()

		color          = card.getColor()
		identifier     = card.getIdentifier()

		# set @action based on the identifier
		if (identifier == "D") then
			@action = :draw2
		elsif (identifier == "S") then
			@action = :skip
		elsif (identifier == "U") then
			@action = :reverse
		elsif (identifier == "W") then
			@action = :wild
		elsif (identifier == "F") then
			@action = :draw4
		else
			@action = :none
		end

		# NN (no play) is a valid play
		if ((color == "N") && (identifier == "N"))
			return true
		end

		# if the colors are the same, any card is valid
		if (top_color == color) then
			return true
		end

		# if the identifiers are the same, cards of any color can be played
		if (top_identifier = identifier) then
			return true
		end

		# if the identifier is W(ild) or wild draw F(our), it is playable
		if (identifier == "W" || identifier == "F") then
			return true
		end

		return false

	end

	#
	# Get Prev Player: returns the previous player
	#
	def getPrevPlayer()
		pos = ((@current - 1) % @players.getSize())
		return @players.getList()[pos]
	end

	#
	# Get Next Player: returns the next player
	#
	def getNextPlayer()
		pos = ((@current + 1) % @players.getSize())
		return @players.getList()[pos]
	end # nextPlayer

	#
	# Get Current Player: returns the current player
	#
	def getCurrentPlayer()
		pos = (@current % @players.getSize())
		return @players.getList()[pos]
	end

	#
	# Get Current Player Hand: returns the hand of the current player
	#
	def getCurrentPlayerHand()
		player = getCurrentPlayer()
		return getPlayerHand(player)
	end

	#
	# Get Player Hand: returns the hand of the specified player
	#
	def getPlayerHand(player)
		return player.getCards()
	end # getPlayerHand

	#
	# return a player based on their position 
	#
	def getPlayerFromPos(pos)
		return @players.getList().at(pos)
	end

	#
	# Game End Check: check if the player that just played has won
	#
	def gameEndCheck()
		count = @playerPlayed.getCardCount()
		if (count == 0) then 
			return true
		end
		return false
	end

	#
	# Uno Check: check if the player that just played has UNO
	#
	def unoCheck()
		count = @playerPlayed.getCardCount()
		if (count == 1) then 
			return true
		end
		return false
	end

	#
	# Min Check: return a boolean value indicating if there are more (or as many) players as the minimum
	#
	def min_check?()
		return @players.getSize() >= @min
	end # min

	#
	# Max Check: return boolean value indicating if there are more players than the maximum allowed
	#
	def max_check?()
		return @players.getSize() <= @max #(@max - 1)
	end # max

	#
	# Full Reset: create a new (shuffled) deck & clear each players hand
	#
	def full_reset()
		@deck = Deck.new()
		@current = 0
		@players.getList().each{ |player| player.reset!() }
	end

end #GameServer
