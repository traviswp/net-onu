#!/usr/local/bin/ruby

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
	
		# variables: game-timer logic
		@timer            = timeout                       # Timer till game starts
        @game_timer_on    = false                         # Time until game starts
		@start_time       = 0
		@current_time     = 0

        # variables: service connections via call to 'select'
        @port             = port                          # Port
        @descriptors      = Array.new()                   # Collection of the server's sockets
        @server_socket    = TCPServer.new("", port)       # The server socket (TCPServer)
        @timeout          = timeout                       # Default timeout
        @descriptors.push(@server_socket)                 # Add serverSocket to descriptors
		@message_queues  = Hash.new()                     # Contains buffers for interaction with each individual client
        
        # enables the re-use of a socket quickly
        @server_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        # variables: player management
		@players          = PlayerList.new()              # List of all players (active)
        #@waiting_list     = PlayerList.new()             # List of all other players (waiting)
		@total_players    = 0                             # Total number of players connected
        @min              = min                           # Min players needed for game
        @max              = max                           # Max players allowed for game
        @lobby            = lobby                         # Max # players that can wait for a game
		@direction        = 1                             # direction of game play (1 or -1 for positive or negative, respectively)
		@step             = 1                             # increment @step players (normal: 1; skip: add 1 to make 2)
		@current          = 0                             # index of the current player whose turn it is
	
		############################ DEBUG ############################
		@playerPlayed     = nil
		@card             = nil
		@attempt          = 0
		@action           = nil
		############################ DEBUG ############################
		@player_timer     = false                         # Boolean represents if player turn is active (go command has been issued)
		@player_time      = 20                            # Default player response time
		@player_strikes   = 3
		############################ DEBUG ############################

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
				
                result = select(@descriptors, nil, nil, @timeout)
				
                if result != nil then
                
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
               
						# I don't know how I feel about this...
						#if @new_connection then
						#	read(socket)
						#end
     
                    end #for            

                end #if

				#############################################################
				#                  Pre-Service Game State(s)                #
				#############################################################
				
				puts "\n-------------------------------------------------"
				puts "#{@players.to_s}"

#				puts "Game Timer On: " + @game_timer_on.to_s
#				puts "Game In Progress: " + @game_in_progress.to_s				
#				if (@game_timer_on)
#					@current_time = Time.now().to_i
#					puts "timer: " + ((@current_time-@start_time).abs()).to_s
#				end #if
				
				################################################################
				#TODO: move (all of) this checking into the beforeGame() method
				
				player_check     = (min_check? && max_check?)   # check: player count 
				game_in_progress = (@states.index(@state) > 0)  # check: game status
				################################################################
				
				if (game_in_progress) then
					if (!player_check) then
						@state = @states[0]
						msg = ServerMsg.message("GG",[""])
						log (msg)
						broadcast(msg, nil)
					else
						#log("service: game in progress - check game state(s)")
					end
					if (@new_connection) then 
						log("service: game in progress - add player to lobby & wait for next game")
					end
				else # game not in progress (before game)

					if (@game_timer_on) then
						@current_time = Time.now().to_i
#						puts "timer: " + ((@current_time-@start_time).abs()).to_s

						if ((@current_time-@start_time).abs() > @timeout) then      # start game
							puts "service: starting game"
							@state = @states[1] ############################# <<<<<<<<<< start game
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
							@start_time = Time.now().to_i                           # reset start_time
						end #if
					elsif (@new_connection) then              # player joing after game is full/game started
						puts "service: (initial) new connection"
					end #if

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
        puts "log: " + msg.to_s + "\n"
    end # log
	
	def err(msg)
		log ("error: " + msg.to_s + "\n")
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
			socket.write(msg)
			name = x.getName()
		else
			socket = @descriptors.find{ |s| s == x }
			if socket != nil then
				socket.write(msg)
				player = @players.getPlayerFromSocket(x)
				name = player.getName()
			else 
				x.write(msg)
			end
			
        end

        if socket != nil then
	        log("sent #{socket.peeraddr[3]} (#{name}): " + msg)
		else
			err("send #{x.peeraddr[3]}: " + msg)
		end

	end # 

    def broadcast(msg, omit_sock = nil)
        
		if msg != nil then

		    # Iterate over all known sockets, writing to everyone except for
		    # the omit_sock & the serverSocket
		    @descriptors.each do |client_socket|
		        
		        if client_socket != @server_socket && client_socket != omit_sock then
		            client_socket.write(msg)
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
		@descriptors.push(new_socket)

		# Create a queue for each connection
		@message_queues[new_socket] = ""

		read(new_socket)

    end # accept_new_connection
    
	#########################################################################

	def remove_player(socket)

		# remove player
		player = @players.getPlayerFromSocket(socket)

		# TODO: put cards back in deck
		@players.remove(player)
		# TODO: delete player object?

		# update game/lobby count
		@total_players = @total_players - 1

	end

	def close_connection(socket) 
		
		remove_player(socket)

	    # Broadcast updated player list to all players (player left)
		msg = ServerMsg.message("PLAYERS", @players.list())
		broadcast(msg, socket)		#broadcast(msg, socket)

		# handle descriptors
		socket.close()
		@descriptors.delete(socket)

	end # close_connection
	
	def read(socket)

		while(true)

			# read: input on clientSocket

			# TODO: handle new lines?
			begin
				data = socket.read(1)
				#socket.flush()
				#msg = data.chomp!
			rescue Exception => e
	            print e.backtrace
				exit(0)
				return nil
			end

			if data == nil then
				puts "why nil?"
				exit(0)
				return nil
			end

			# check: dropped/closed connection
			if data == "" then
				puts "dropped"
				#dropped_connection()
				return nil
			end

			# update: @message_queues[socket]
			@message_queues[socket] = @message_queues[socket] + data
			p = @players.getPlayerFromSocket(socket)                          ###DEBUG
			if p != nil then
				puts "#{p.getName()}'s buffer on read:[#{@message_queues[socket]}]" ##DEBUG
			end

			# validate: @message_queues[socket]
			result = validate(data, socket) #@message_queues[socket]
	
			# check: complete message from server?
			if result == nil then          # invalid command/argument(s)
				# do nothing
			elsif result[0] == "drop" then # valid command, empty contents (drop)
				break
			elsif result != nil then       # valid command with valid argument(s)

				# process message
				command = result[0].to_s
				arguments = result[1].to_s
				process(command, arguments, socket)
				break
			end

			#break		
		
		end

		return true

	end #read

	def process(command, args, socket)
	
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
		playerName = @players.getPlayerFromSocket(socket).getName()
		msg = ServerMsg.message("CHAT", [playerName, message])
		broadcast(msg, socket)
	end

	def handle_join(name, socket) ###### ************

        ########################################
		# Validation
        result = name_validation(name)
        ########################################
		puts result
		# invalid join
		if result == nil then
			return
		end

		if (result.size() == 1) then

			# Create Player object & add to player list
			name = result[0]
			p = Player.new(name, socket)
			@players.add(p)

			# Update player counts
			@total_players = @total_players + 1

			# Inform player of acceptance
		    msg = ServerMsg.message("ACCEPT",[name])		  
			send(msg, socket)
		   
		    # Broadcast updated player list to all players
			msg = ServerMsg.message("PLAYERS", @players.list())
			broadcast(msg, nil)

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
		
		puts "state: start game" ###DEBUG

		# send [STARTGAME|...] (report all active players for game play)
		msg = ServerMsg.message("STARTGAME", @players.list())
		broadcast(msg)
		
		# initial deal
		deal()

		# new state: play
		@state = :play

	end 

	def play()
	
		puts "state: play" ###DEBUG
		puts @players.to_s

		player = getCurrentPlayer()

		# send [DEAL|cards] if the last card played was a draw 2 or draw 4
		if (@action == :draw2) then
			draw(player, 2)
		elsif (@action == :draw4) then
			draw(player, 4)
		end
		@action = :none


		# send [GO|CV]
		msg = ServerMsg.message("GO", [top.to_s]) 
		send(msg, player)

		# (new state: waitForAction)
		@state = :waitaction

	end

	def waitForAction()

		# simply wait for current player to discard
		playerCurrent = getCurrentPlayer()
		puts "state: waitForAction - waiting for #{playerCurrent.getName()} to play!" ###DEBUG


		if (@playerPlayed == playerCurrent) then

			# process the discard for validity
			discard()

			# reset most recent play variables
			@playerPlayed = nil
			@card = nil

		end

		#
		# if timeout:
		#    - drop/skip player? (new state: postDiscard)

	end

	def discard()
		puts "check: discard" ###DEBUG

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

		@attempt = 0
		@state = :afterdiscard
		afterDiscard()
	end

	def afterDiscard()
		puts "state: afterDiscard" ###DEBUG

		# send [PLAYED|playername,CV]
		msg = ServerMsg.message("PLAYED", [@playerPlayed.getName(),@card.to_s])
		#broadcast(msg, @playerPlayed.getSocket())
		broadcast(msg, nil)

		# check: [UNO|playername]
		result = unoCheck()
		if (result)
			msg = ServerMsg.message("UNO", [@playerPlayed.getName()])
			broadcast(msg, @playerPlayed.getSocket())
		end 

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
		puts "state: endGame" ###DEBUG

		# send [GG|winning_player_name]
		msg = ServerMsg.message("GG",[@playerPlayed.getName()])
		broadcast(msg, nil)

		# reset player cards & the game deck
		full_reset()

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
		return @players.getSize() <= @max
	end # max

	#
	# Full Reset: create a new (shuffled) deck & clear each players hand
	#
	def full_reset()
		@deck = Deck.new()
		@players.getList().each{ |player| player.reset() }
	end

end #GameServer
