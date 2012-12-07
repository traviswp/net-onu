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
    
    def initialize(port, min, max, timeout, lobby, debug_flag)
	
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


        @debug_flag = debug_flag
        msg = "UNO Game Server started on port #{@port}" 
        puts msg 
        if @debug_flag then
            puts "starting server with debug messages on..."
        end
        log(msg)

    end #initialize
    
    def run()

        begin # error handling block

            while true

#print "press enter to proceed"
#STDIN.getc

				#############################################################
				# Service Connections/Disconnections & Process Client Input #
				#############################################################

				@new_connection = false
				
                result = select(@r_descriptors, nil, nil, 0)
				
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
                    
                    end #for            

                end #if

				#
				# Special condition: in certain circumstances, the message_queues
				#  will still have something to process, but the client has already
				#  written it, thus, the select statement will not detect that
				#  the buffer is not empty. This method handles any lingering
				#  queued messages. 
				#

				if !@players.getList().empty? then
					@players.getList.each{ |p|

						if @message_queues[p.getSocket()] != "" then
							buffer_clear(p.getSocket())
						end
					}
				end

				if !@waiting.getList().empty? then
					@waiting.getList.each{ |p|

						if @message_queues[p.getSocket()] != "" then
							buffer_clear(p.getSocket())
						end
					}
				end


				#############################################################
				#                  Pre-Service Game State(s)                #
				#############################################################
				
				################################################################
				#TODO: move (all of) this checking into the beforeGame() method
				
				player_check     = (min_check? && max_check?)   # check: player count 
				game_in_progress = (@states.index(@state) > 0)  # check: game status
				################################################################

				# game in progress
				if (game_in_progress) then

					# check: minimum amount of players are connected (end game if true)
					if (@players.getSize() <= 1) then

						# set game environment variables
						@game_timer_on = false

						# the winner is the only remaining player
						winner = @players.list()[0]

						# call the end of game handler
						endGame(winner)

					end

				else # game NOT in progress (before game)

					#check: timer has started (min_check? and max_check? was satisfied)
					if (@game_timer_on) then

						# get: current timestamp
						@current_time = Time.now().to_i

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

							log(@players.list())
							log(@waiting.list())
						end

					end #if

				end

				# check: drop player due to inactivity
				if (@state == :waitaction) then

					current_time = Time.now().to_i
					if ((current_time - @player_start).abs() >= @inactive_wait) then

						# get the offending player
						player = getPlayerFromPos(@current)
						name = player.getName()

						# log action & inform client of the problem
						inactiveMsg = "#{name}: connection dropped: exceeded max inactivity time"
						msg = ServerMsg.message("INVALID", [inactiveMsg])
						send(msg, player.getSocket())

						# drop the player & continue
						drop_connection(player)

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
            msg = "\nserver application interrupted: shutting down..." 
            @log.syswrite(msg)
            puts msg
            exit 0
        rescue Exception => e
            puts 'Exception: ' + e.message()
            print e.backtrace.join('\n')
        end # error handling block
        
    end #run
    
    ######################################################################
	#                                                                    #
    #                         Private Class Methods                      #
	#                                                                    #
    ######################################################################

    private

	#
	# Debug messages (verbose mode)
	#
	def debug(msg)
        if @debug_flag then
            puts "debug: #{msg}"
        end
	end

	#
	# Regular log messages
	#
    def log(msg)
		logMsg = "log: #{msg}\n"
		debug(logMsg)
		@log.syswrite(logMsg)
    end # log
	
	#
	# Log error messages
	#
	def err(msg)
		errMsg = "error: #{msg}"
		log(errMsg)
	end # err
    
	#
	# Send messages to an explicit player
	#
	# x can be either a socket descriptor or a player. In either case, the 
	# appropriate socket descriptor is located and msg is written to only
	# that client
	#
	def send(msg, x)

		if msg != nil then

			# log activity
			log("`send`: #{msg}")

			name = ""
			if (x.kind_of? Player) then
				socket = @players.getSocketFromPlayer(x)
				if socket != nil then
					begin
						socket.write(msg)
					rescue Exception => e
						#err("(0) 'send' errpr: #{e}: message = #{msg}")
					end
				end
			else
				socket = @r_descriptors.find{ |s| s == x }
				if socket != nil then
					begin
						socket.write(msg)
					rescue Exception => e
						#err("(1) 'send' error: #{e}: message = #{msg}")
					end
				else 
					begin
						if x != nil then
							x.write(msg)
						end
					rescue Exception => e
						#err("(2) 'send' error: #{e}: message = #{msg}")
					end
				end			
		    end #if

		else # error

			#err("(4) `send` error: nil message")

		end

	end # send

	#
	# Broadcast messages
	#
    def broadcast(msg, omit_sock = nil)

		if msg != nil then
		    
		    log("`broadcast`: " + msg)

		    # Iterate over all known sockets, writing to everyone except for
		    # the omit_sock & the serverSocket
		    @r_descriptors.each do |client_socket|
		        
		        if client_socket != nil && client_socket != @server_socket && client_socket != omit_sock then

					begin

                        if client_socket != nil then
    			            client_socket.write(msg)
                        end 

					rescue Exception => e
                        # socket closed before write - just ignore this
						#err("`broadcast` error: #{e}: message = #{msg} player = [#{@players.getPlayerFromSocket(client_socket).getName()}]")
					end

		        end #if
		        
		    end #each

		end
                    
    end #broadcast
    
	#########################################################################

	#
	# Accept a new connection 
	#
    def accept_new_connection()
        
		# check: is there room in the lobby for 1 more player
		if @players.getSize() + @waiting.getSize() + 1 <= @lobby then

		    # Accept connect
		    new_socket = @server_socket.accept

			# Add new socket to descriptors
			@r_descriptors.push(new_socket)

			# Create a queue for each connection
			@message_queues[new_socket] = ""

			# Special call to read (expecting JOIN message)
			read(new_socket)

		else

		    # Temp. connect
		    tmp_socket = @server_socket.accept

			# Inform the connecter that the lobby is full
			message = "I'm sorry, the lobby is full! We only have room for #{@lobby} players. Disconnecting..."
			msg = ServerMsg.message("INVALID", [message])

			begin
				tmp_socket.write(msg)
				log("#{msg}")
			rescue Exception => e
				err("There was a write error in the 'accept_new_connection write'. message = #{msg} & socket = #{tmp_socket}")
			end

			# Close temp. connect
			tmp_socket.close()

		end

    end # accept_new_connection
    
	#########################################################################

	#
	# Remove a player object from the game environment
	#
	def remove_player(socket)

        # remove player (player was a waiting player)
        if @waiting.getPlayerFromSocket(socket) != nil then

			# physically remove player from list
			player = @waiting.getPlayerFromSocket(socket)
			@waiting.remove(player)

		    # update game/lobby count
		    @total_players = @total_players - 1

            return

        end

		# remove player (player was in the game)
		if @players.getPlayerFromSocket(socket) != nil then

			# put cards back in deck
			player = @players.getPlayerFromSocket(socket)
			cards = player.getCards()
			@deck.put_back(cards)

			# physically remove player from list
			@players.remove(player)

		end

		# Broadcast updated player list to all players (player left)
        if @players.list != [] then
    		msg = ServerMsg.message("PLAYERS", @players.list())
        else
		    msg = ServerMsg.message("PLAYERS", [""])
        end

		broadcast(msg, socket)		#broadcast(msg, socket)

        # update game/lobby count
        @total_players = @total_players - 1

	end

	#
	# Close socket (removes a player)
	#
	def close_connection(socket) 

		#
		# check: player's status
		#

		# check: player is waiting (not a player in the game)
		if @waiting.getPlayerFromSocket(socket) != nil then

			remove_player(socket)

		# check: player is playing in the game
		elsif @players.getPlayerFromSocket(socket) != nil then
			# player removal handler
			remove_player(socket)

			# check: if game in progress, move to next player
			if ((@state != :beforegame) && (@state != :endgame)) then

				# check: only call play if that is a possible action
				if (@players.getSize() > 1) then

					move()
					play()

				end

			end

		end

		# handle descriptors
        begin 
		    socket.close()
		    @r_descriptors.delete(socket)
        rescue Exception => e
            log("socket is closed already")
        end

	end # close_connection

	#
	# Calls other methods to close connection & remove player 
	#
	def drop_connection(player)
		socket = @players.getSocketFromPlayer(player)
		close_connection(socket)
	end # drop_connection
	
	#
	# Read
	#
	def read(socket)

		while(true)

			# read: input on clientSocket
			begin
				data = socket.read_nonblock(128)
				data.gsub!(/\r/, "")
				data.gsub!(/\n/, "")
                data.lstrip!
			rescue Exception => e
	            #print e.backtrace
				#exit(0)
				#return nil
			end

			if data == "" then
				debug "socket read data is empty"
			end

			# check: nil value from read?
			if data == nil then
			#	exit(0)
				return nil
			end

			# update: @message_queues[socket]
			@message_queues[socket] = @message_queues[socket] + data

			# validate: @message_queues[socket]
			result = validate(socket) #@message_queues[socket]
	
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

				return true
			end

			break

		end

		return true

	end #read

	#
	# clear @message_queue for socket x
	#
	def buffer_clear(x)

        command = "none"
        arguments = "none"
		begin

			# validate: @message_queue[socket] (get the player's socket)
            @message_queues[x].lstrip!
			result = validate(x)

			# check: complete message from server?
			if result != nil then

				# process message
				command = result[0].to_s
				arguments = result[1].to_s
				process(command, arguments, x)

			end

		rescue Exception => e

			err("method 'buffer clear': error processing: [#{command}|#{arguments}]")

		end

	end

    ######################################################################
	#                                                                    #
    #                             Validation                             #
	#                                                                    #
    ######################################################################

	def validate(socket)
		
		######################################################
		# validating contents of the @message_queues[socket] #
		######################################################


        #debug("buffer to validate on: #{@message_queues[socket]}")

		# check the beginning of the string:
		# remove anything up until you find the first '['
		re = /\A([^\[]*)[^\[\]]?/i
		m = @message_queues[socket].match re

		if m != nil && !m[0].empty? then
			msg = "(0) '#{m[0]}' is an invalid message"
			@message_queues[socket].sub!(/\A([^\[]*)[^\[\]]?/i, "")
			handle_invalid(msg, socket)
            return nil
		else

            re = /([^\[]*?)\[/i
            m = @message_queues[socket].match re

            if m != nil && $1 != "" then

                # invalid
                if $1.lstrip! != "" then
                    @message_queues[socket].sub!(/([^\[]*?)\[/i, "")
			        handle_invalid("(1) '#{$1}' is an invalid message", socket)
                    return nil 
                end

            end

		end
		
		# match:
		#    command   (letters only; 2-9 characters)
		#    arguments (anything up to the first ']' character)
		re = /\[([a-zA-Z]{0,10})\|(.*?)\]/i
		m = @message_queues[socket].match re

		# upon matching: (1) set command, (2) set command info, and (3) remove
		#  this portion of the message from @buffer
		if m != nil then
			command = m[1].upcase()
			info    = m[2]
			@message_queues[socket].sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
		else

            re = /\[([^\[\]]*)\]/i
            m = @message_queues[socket].match re

            if m != nil then

                # invalid: [ invalid contents ]
			    @message_queues[socket].sub!( /\[([^\[\]]*)\]/i, "")
		        handle_invalid("(1) '[#{$1}]' is an invalid message", socket)

            end

            return nil

		end

		#
		# validate command 
		#

		if !(ServerMsg.valid?(command)) then

			# invalid command
			msg = "`#{command}` is an invalid command"
			handle_invalid(msg, socket)
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

	def process(command, args, socket)

		##################################### DEBUG
		log("`process` received: [#{command}|#{args}]")
		##################################### DEBUG

		if (command == "CHAT") then
			handle_chat(args, socket)
		elsif (command == "JOIN") then
			handle_join(args, socket)
		elsif (command == "PLAY") then
			handle_play(args, socket)
		else
			# error - shouldn't get here (validation should catch it - but just in case)
			msg = "error in method 'process'. unrecognized command '[#{command}|#{args}]'"
			err("#{msg}")
			handle_invalid("#{msg}", socket)
		end

	end

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

			exists1 = @players.getList().find { |p| p.getName == tmp } # check @players list
			exists2 = @waiting.getList().find { |p| p.getName == tmp } # check @waiting list

			# if name exists, adjust it and check again, otherwise, return name
			if exists1 != nil || exists2 != nil then
				tmp = name + numId.to_s
				numId = numId + 1
			else
				name = tmp
				break
			end
		end

		return [name]

    end # name_validation

    ######################################################################
	#                                                                    #
    #                       Handle Client Requests                       #
	#                                                                    #
    ######################################################################

	#
	# Chat
	#
	def handle_chat(message, socket)

		if socket != nil then

			begin 

				# check: does the 'chatter' belong to the players list?
				player = @players.getPlayerFromSocket(socket)

                if player != nil then
                    playerName = player.getName()
                else
                    player = @waiting.getPlayerFromSocket(socket)
                    if player != nil then
                        playerName = player.getName()
                    else
                        raise "non-registered player trying to chat"
                    end
                end

                # socket represents valid player - send chat
				msg = ServerMsg.message("CHAT", [playerName, message])
				broadcast(msg, nil)

			rescue Exception => e

				# error (no player object)
				if socket != nil then

					msg = "CHAT error: #{e.message()}: send a valid JOIN message before chatting. disconecting..."
					log(msg)
					msg = ServerMsg.message("INVALID", [msg])
					send(msg, socket)

		            # drop the connection
		            close_connection(socket)

				end

			end

		end

	end

	#
	# Join
	#
	def handle_join(name, socket)

        # check: only one join per socket connection is allowed
        @players.getList().each{ |p|
            if p.getSocket == socket then

				msg = "(0) JOIN error: socket collision (cannot have multiple instances on single socket). disconnecting..."
				log(msg)
				msg = ServerMsg.message("INVALID", [msg])
				send(msg, socket)

                # error: multiple joins
                close_connection(socket)
                return
            end
        }
        
        @waiting.getList().each{ |p|
            if p.getSocket == socket then

				msg = "(1) JOIN error: socket collision (cannot have multiple instances on single socket). disconecting..."
				#log(msg)
				msg = ServerMsg.message("INVALID", [msg])
				send(msg, socket)

                # error: multiple joins
                close_connection(socket)
                return
            end
        }

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

	#
	# Play
	#
	def handle_play(card, socket)

		# play validation handled in game states - set player & card...

		if @state != :beforegame && @state != :aftergame then

			@playerPlayed = @players.getPlayerFromSocket(socket)          # type: Player
			@card = Card.new(card[0].chr.upcase(), card[1].chr.upcase())  # type: Card

		else # game not in progress

			# invalid play - game not in progress
			badPlayMsg = "can't play, game is not in progress!"
			handle_invalid(badPlayMsg, socket)

		end

	end

	#
	# Invalid
	#
	def handle_invalid(message, socket)

		# check: find offending player
		player = @players.getPlayerFromSocket(socket)

		# check: if player is nil, player must be a waiting player
		if player == nil then
			player = @waiting.getPlayerFromSocket(socket)
		end

		if player != nil then

			# add strike to offending player
			player.addStrike()

			log("#{player.getName()} getting a strike (#{player.getStrikes})") ######################################################################

			# check: player exceeded allowed strikes
			if (player.getStrikes() >= @player_strikes_allowed) then

				# inform player that they are about to be booted
				drop_message = "You have now committed #{@player_strikes_allowed} infractions - disconnecting you from the game..."
				msg = ServerMsg.message("INVALID", [drop_message])
				send(msg, socket)

				# drop the connection
				drop_connection(player)

                return

			end

			# inform the player
			msg = ServerMsg.message("INVALID", [message])
			send(msg, socket)

		else # player == nil

			#
			# zero tolerance for non-player offenders - drop connection
			#

			# inform the user on this connection of infraction
			msg = ServerMsg.message("INVALID", [message + " - zero tolerance for non-player connections"])
			send(msg, socket)

			# drop the connection
			close_connection(socket)

		end

	end

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

        #server output
        puts
        puts "Game Starting..."
        puts

        if @players.getSize() > 0 then
            msg= "Players: #{@players.list().join(", ")}"
            puts msg
            log(msg)
        end
        if @waiting.getSize() > 0 then
            msg = "Players Waiting: #{@waiting.list().join(", ")}"
            puts msg
            log(msg)
        end

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
			#err("player is quit in the middle of his play")
		end

	end

	def waitForAction()

		# simply wait for current player to discard
		playerCurrent = getCurrentPlayer()

		# check: if playerPlayed is current player, process the played card
		if (@playerPlayed == playerCurrent) then

			# process the discard for validity
			discard()

			# reset most recent play variables
			@playerPlayed = nil
			@card = nil

		# check: playerPlayed != current player - that's a strike!
		elsif @playerPlayed != nil then

			msg = "Hey, it is #{playerCurrent.getName()}'s turn! It is not your turn to play!"
			handle_invalid(msg,@playerPlayed.getSocket())

			# reset most recent play variables
			@playerPlayed = nil
			@card = nil

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
			@playerPlayed.discard(@card)

		elsif (@action == :draw4) then # draw 4

			#player discards @card onto discard pile
			@deck.discard(@card)

			#remove card from player's hand
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

        #server output
        puts "#{@playerPlayed.getName()} played '#{@card}'"

		# check: [UNO|playername]
		result = unoCheck()
		if (result)
			msg = ServerMsg.message("UNO", [@playerPlayed.getName()])
			broadcast(msg, @playerPlayed.getSocket())

            #server output
            puts "#{@playerPlayed.getName()} said 'UNO!'"
		end 

		#####################################################################
		#####################################################################
		debug("--------------------------------------------------------#{@count}")
		debug("Playing Players:\n#{@players.to_s}")
		debug("-----------------------------------------------------------")
		debug("#{@deck.showDeck()}")
		debug("Waiting Players: #{@waiting.list().join(",")}")
		debug("-----------------------------------------------------------")
		@count = @count + 1
		#####################################################################
		#####################################################################

		# check: end of game
		result = gameEndCheck()
		if (result) # end of game
			@state = :endgame
			endGame(@playerPlayed.getName())
		else # game still in progress
			move()
			@state = :play
		end

	end

	def endGame(winnerName)

        #server output
        if winnerName == nil or winnerName == "" then
            puts
            puts "Game Finished with no winner."
        else
            puts
            puts "Game Finished. Player #{winnerName} Won!\n"
        end

		# send [GG|winning_player_name]
		msg = ServerMsg.message("GG",[winnerName])
		broadcast(msg, nil)

		# reset player cards & the game deck
		full_reset()

		# check if players from waiting list can move to players list
		while ( (@players.getSize() + 1 <= @max) && (@waiting.getSize() > 0) ) do

			# move player from one list to another
			player = @waiting.getFront()
			@players.add(player)

			debug("moving #{player.getName()} from waiting to players list (end of full game)")
			log(@players.list())
			log(@waiting.list())
		end

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
        if player != nil then
		    cards = @deck.deal(n)
		    player.cards.concat(cards)
		    msg = ServerMsg.message("DEAL", card_list(cards))
		    send(msg, player)
        end
	end # draw

	#
	# Card_List: convert a list of cards to be cards represented as strings
	#
	def card_list(cards)
		list = []
		cards.each { |card|
			list << card.to_s
		}
		return list
	end # card_list

	#
	# Get the top card of the discard pile
	#
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
	# Get Prev Player: returns the previous player TODO: this can maybe be removed (not being used)
	#
	def getPrevPlayer()
		pos = ((@current - 1) % @players.getSize())
		return @players.getList()[pos]
	end

	#
	# Get Next Player: returns the next player TODO: this can maybe be removed (not being used)
	#
	def getNextPlayer()
		pos = ((@current + 1) % @players.getSize())
		return @players.getList()[pos]
	end # nextPlayer

	#
	# Get Current Player: returns the current player
	#
	def getCurrentPlayer()

		if @players.getSize() > 0 then
			pos = (@current % @players.getSize())
			return @players.getList()[pos]
		else
			return nil
		end

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
	# Full Reset: create a new (shuffled) deck & clear each players hand
	#
	def full_reset()
		@deck = Deck.new()
		@current = 0
		@players.getList().each{ |player| player.reset!() }
	end

    ######################################################################
	#                                                                    #
    #                  Server Check/Validation Methods                   #
	#                                                                    #
    ######################################################################

	#
	# Playable: determine if card can be played (set action & return boolean)
	#
	def playable?(card)

		# store components of the "top card"
		top_color      = top().getColor()
		top_identifier = top().getIdentifier()

		# store componets of the given card
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

end #GameServer
