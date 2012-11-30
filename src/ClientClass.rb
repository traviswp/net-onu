#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'Card'
require 'PlayerClass'
require 'ClientMsg'

include ClientMsg

class GameClient

    ######################################################################
	#                                                                    #
    #                         public class methods                       #
	#                                                                    #
    ######################################################################    

    public

    def initialize(hostname, port, clientName)

        @hostname     = hostname                # Server address to connect to
        @port         = port                    # Server port to connect to
        @clientName   = clientName              # Client's name

        @clientSocket = []                      # Client socket (TCPSocket)
        @MAX_MSG_LEN  = 128                     # Max length of msg 
        @buffer = ""

		# Read/Write log file
		filename = @clientName + "_log.txt"
		@log = File.new(filename,"w+")

        # parameters for select
        @timeout      = 3                       # Client timeout for select call
        @descriptors  = Array.new()             # Collection of sockets
        @descriptors.push(STDIN)                # Client socket (standard input)

		@player       = nil
		@top          = nil

		# variables for game play tracking/output
		@players_list   = []
		@current_player = ""

		# valid game states
		@state  = :lobby
		@states = [:lobby, :start, :wait, :play]

		# inform client of initial connection
		startMsg = "Game client #{@hostname} started on port #{@port}"
		log(startMsg)
		puts startMsg

        connect()                               # Connect to server

    end #initialize

    def run()

        begin # error handling block

            while true

                result = select(@descriptors, nil, nil, @timeout)

                if result != nil then

                    # Iterate over tagged 'read' descriptors
                    for socket in result[0]

                        # ServerSocket: Handle connection
                        if socket == @clientSocket then
                        
                            # Read from server
                            check = read()

                            # Processing if check == nil (connection dropped)
                            if check == nil then
                                exit 0
                            end

                        # Client has written something
                        elsif socket == STDIN then
                            write()
                        else
                            err("unknown socket in 'select'")
                        end #if

                    end #for

                end #if

				#
				# Special condition: in certain circumstances, the buffer will
				#  still have something to process, but the server has already
				#  written it, thus, the select statement will not detect that
				#  the buffer is not empty. This method handles any lingering
				#  buffered messages. 
				#
				if (@buffer != "") then
					buffer_clear()
				end

				#############################################################
				#                    Service Game State(s)                  #
				#############################################################

				if (@state == @states[0]) then    #lobby
					lobby()
				elsif (@state == @states[1]) then #start
					start()
				elsif (@state == @states[2]) then #wait
					wait()
				elsif (@state == @states[3]) then #play
					play()
				end

            end #while

        rescue Interrupt
            logMsg =  "\nclient application interrupted: shutting down..."
			log(logMsg)
			puts logMsg
            exit 0
        rescue SystemExit => e
            # On a system exit, exit gracefully
        rescue StandardError => e
            errMsg = 'Exception: ' + e.message()
			err(errMsg)
			puts errMsg
            print e.backtrace.join('\n')
        end # error handling block

    end #run

    ######################################################################
	#                                                                    #
    #                        private class methods                       #
	#                                                                    #
    ######################################################################    
    private

    def log(msg)
		logMsg = "log: #{msg}\n"
		@log.syswrite(logMsg)
    end #log

    def err(msg)
        logMsg = "error: #{msg}"
		log(logMsg)
    end #err

	#
	# read:
	#
	# Input: none
	# Output: portion of text from @buffer that was processed (if any)
	#
	def read()

		while(true)

			# read: input on clientSocket
			data = @clientSocket.recv(1024)
			data.chomp!

			# check: dropped/closed connection
			if data == "" then
				dropped_connection()
				return nil
			end

			# update: @buffer
			@buffer = @buffer + data
			#puts "buffer on read :[#{@buffer}]" #DEBUG

			# validate: @buffer
			result = validate(data)
	
			# check: complete message from server?
			if result != nil then

				# process message
				command = result[0].to_s
				arguments = result[1].to_s
				process(command, arguments)
				break
			end

		end

		return true		

	end #read

	def buffer_clear()

		# validate: @buffer
		result = validate(@buffer)

		# check: complete message from server?
		if result != nil then

			# process message
			command = result[0].to_s
			arguments = result[1].to_s
			process(command, arguments)
		end

	end

    def write()

		# get input
        input = STDIN.gets()

		# chat
		if ((input.slice(0,4) == "chat")) then

			tmp = input[4...-1]
			tmp.lstrip!()
			tmp.rstrip!()

			input = ClientMsg.message("CHAT",[tmp])
			@clientSocket.write(input)
	        log("write: " + input)
			return

		end

		# display the help menu
		if ((input.slice(0,4) == "help")) then
			help_dialog()
			return
		end

		# list who is in the game still
		if ((input.slice(0,4) == "list")) then
			list_players()
			return
		end

		# play a card (p)
		if ((input.slice(0,4) == "play")) then

			card = input[4...-1].upcase()
			card.lstrip!()
			card.rstrip!()

			##############################
			play = checkPlayable(card)
			##############################

			if (play) then
				c = Card.new(card[0].chr.upcase(), card[1].chr.upcase())
				@player.discard(c)
				input = ClientMsg.message("PLAY",[card])
				@clientSocket.write(input)
			    log("player played: " + input)
				show_play(c)
			end
			return

		end

		# check for client disconnect command
        if (input.slice(0,4).eql?("quit")) then
			#TODO: this should just return to lobby - then if they exit again, drop connection
			@state = :lobby          
			log("signing off...")
            exit 0
        end

		# show current card(s)
		if ((input.slice(0,4) == "show")) then
			show_cards()
			return
		end

		# show top card
		if ((input.slice(0,3) == "top")) then
			show_top()
			return
		end

		input.chomp!
		puts "sorry, '#{input}' is not a recognized action. try typing 'help'."

    end #write

    def connect()

        begin # error handling block

			# Create socket w/ server 
            @clientSocket = TCPSocket.new(@hostname, @port)
            @descriptors.push(@clientSocket)         


			# send initial JOIN message to server
            msg = ClientMsg.message("JOIN", [@clientName])
            log("write: " + msg.to_s)
            @clientSocket.write(msg)

            return 0

        rescue Errno::ECONNREFUSED
			# server isn't up
            puts "connection refused: could not connect to #{@hostname} on port #{@port}."
            exit 0
        rescue SystemExit => e
            # On a system exit, exit gracefully
        end # error handling block

    end #connect

    def dropped_connection()
        puts "server connection dropped..."
        @clientSocket.close()
        @descriptors.delete(@clientSocket)
    end #dropped_connection

	#
	# Parse String:
	#
	# Input : comma delimited string of arguments
	# Output: array of arguments
	#
	def parse_str(str)
		return str.split(',')
	end


	#
	# validate:
	#
	# Input: none
	# Output: return array containing: (1) command, and (2) arguments
	#
	def validate(data)

		######################################
		# validating contents of the @buffer #
		######################################

		# match:
		#    command   (letters only; 2-9 characters)
		#    arguments (anything up to the first ']' character)
		re = /\[([a-zA-Z]{2,9})\|(.*?)\]/i
		m = @buffer.match re

		#puts "buffer matched #{@buffer}"

		# upon matching: (1) set command, (2) set command info, and (3) remove
		#  this portion of the message from @buffer
		if m != nil then
			command = m[1].upcase()
			info    = m[2]
			@buffer.sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
		else
			#puts "received #{data}" #DEBUG
			return nil
		end

		#puts "updated buffer: [#{@buffer}]"

		# validate: command
		if !(ClientMsg.valid?(command)) then
			# command not recognized
			return nil
		end

		#validate: info following command
		if (info.size() > 128) then
			err("message error: message with command '#{command}' and content '#{info}' violates message length constraints") #DEBUG
			return nil
		end	

		return [command,info]

	end

    ######################################################################
	#                                                                    #
    #                           client states                            #
	#                                                                    #
    ######################################################################

	def lobby()
		#puts "state: lobby" ###DEBUG
	end

	def start()
		#puts "state: start" ###DEBUG
		@state = :wait
	end

	def wait()
		#puts "state: wait" ###DEBUG
	end

	def play()
		#puts "state: play" ###DEBUG
	end

    ######################################################################
	#                                                                    #
    #                    client states helper methods                    #
	#                                                                    #
    ######################################################################

	#
	# process:
	#
	# Input: a legal UNO command & its arguments (validated in method 'validate')
	# Output: none - makes appropriate call to handler method
	#
	def process(command, args)

		# check: nil/empty entries are illegal
		if (command == nil || command == "" || args == nil) then
			raise "illegal call to 'process()': command & arguments are nil"
		end

		#
		# call appropriate handler method based on command:
		#

		if (command == "ACCEPT") then
			handle_accept(args)
		elsif (command == "CHAT") then
			handle_chat(args)
		elsif (command == "DEAL") then
			handle_deal(args)
		elsif (command == "GG") then
			handle_gg(args)
		elsif (command == "GO") then
			handle_go(args)
		elsif (command == "INVALID") then
			handle_invalid(args)
		elsif (command == "PLAYED") then
			handle_played(args)
		elsif (command == "PLAYERS") then
			handle_players(args)
		elsif (command == "STARTGAME") then
			handle_startgame(args)
		elsif (command == "UNO") then
			handle_uno(args)
		elsif (command == "WAIT") then
			handle_wait(args)
		else
			# error - shouldn't get invalid messages from the server
			err("error in method 'process'. unrecognized command '#{command}'")
		end

	end

	#
	# Handle Accept:
	#
	# the server may change the user's name to resolve any issues with
	# uniqueness. correct name (if needed) and create the Player object.
	#
	def handle_accept(name)
		@clientName = name
		@player = Player.new(@clientName, 0)

		log("creating player with name #{name}")
	end

	#
	# Handle Chat:
	#
	# parse the server message into the two components (sender-name & message).
	#
	def handle_chat(msg)
		list = parse_str(msg)
		name = list.delete_at(0)
		msg = list.join(',')

        log("server: #{name}: #{msg}")
		puts "#{name}: #{msg}"
	end

	#
	# Handle Deal:
	#
	# parse string of card(s) & add to player hand
	#
	def handle_deal(msg)
        log("server: [DEAL|#{msg}]")
		puts ("dealt [#{msg}]")

		# parse string of cards
		list = parse_str(msg)

		# construct Card object(s) & add to player hand
		list.each { |card|
			prefix = card[0].chr
			suffix = card[1].chr
			@player.cards << Card.new(prefix,suffix)
		}
	end

	def handle_gg(name)

		show_win(name)
		
		# state: lobby
		@state = :lobby 
	end

	def handle_go(card)
		@top = card

        log("server: [GO|#{card}]")
		show_go()

		# state: play
		@state = :play
	end

	def handle_invalid(msg)
        err("server-error: #{msg}")
		puts("server:, #{msg}")
	end

	def handle_played(msg)
		list = parse_str(msg)
		name = list[0]
		card = list[1]
		@top = card

		log("server: [#{name}|#{card}]")

		# state: wait
		if (name == @player.getName()) then
			@state = :wait
		else
			puts "player '#{name}' played [#{card}]"
		end

	end

	def handle_players(msg)

		# TODO:
		# right now I just overwrite the player list with any updates from
		# the server. If better AI is to be implemented, new name from
		# the server should be specically located and added to the tracking
		# system for AI gameplay. 

		prev = @players_list            #old list as strings
		@players_list = parse_str(msg)  #new list

		if prev.size() < @players_list.size() then # player connected

			# locate the new name
			name = ""
			@players_list.each { |new|
				if !(prev.include?(new)) then
					name = new
				end
			}

			if name != @player.getName()
				puts "player '#{name}' has connected"
			end
			log("server: new player '#{name}' connected: [PLAYERS|#{msg}]")

		else # (prev.size() >= @players_list.size()) --> player disconnected

			# locate the new name
			name = ""
			prev.each { |old|
				if !(@players_list.include?(old)) then
					name = old
				end
			}

			log("server: player '#{name}' has disconnected: [PLAYERS|#{msg}]")
			puts "player '#{name}' has disconnected"

		end

	end

	def handle_startgame(msg)
		@players_list = parse_str(msg)

        log("server: starting game: [PLAYERS|#{msg}]")
		start_game_dialog()

		@state = :start
	end

	def handle_uno(name)
        log("server: player #{name} said 'UNO!': [UNO|#{name}]")
		show_uno(name)
	end

	def handle_wait(name)
        log("server: game in progress: creating player with name #{name} & waiting...")
		puts "game currently in progess: you are in line for the next game :)"
		@clientName = name
		@player = Player.new(@clientName, 0)
	end

    ######################################################################

	#
	# Check Playable:
	#
	# Input : Card
	# Output: Boolean value indicating if the player has a certain card
	#          & whether of not that card can be played at this time
	#
	def checkPlayable(card)

		# check: currently this player's turn
		if (@state != :play) then
			log("it is not your turn to play!")
			puts "it is not your turn to play!"
			return false
		end

		# check: type
		if (!card.kind_of?(String)) then
			log("invalid string type: #{card} is not a valid card")
			puts "#{card} is not a valid card"
			return false
		end

		# check: card not nil
		if (card == nil || card == "") then
			log("'nil' or '\"\"' is not a valid card ")
			puts "'nil' or '\"\"' is not a valid card "
			return false
		end

		# check: valid card length
		if card.length() > 2 then
			log("#{card} is not a valid card: cards have ONLY a color & an identifier")
			puts "#{card} is not a valid card"
			return false
		end

		if (card[0] == nil || card[1] == nil) then
			log("#{card} is not a valid card (either color or identifier is nil)")
			puts "#{card} is not a valid card"
			return false
		end

		# check: no play (NN)
		if (card == "NN") then
			log("player unable to play - request additional card or be skipped")
			puts "server: couldn't play, eh? prepare to get another card or be skipped..."
			return true
		end

		# check: does player have this card
		cards = @player.getCards()
		pre = card[0].chr
		suf = card[1].chr
		found = false
		cards.each { |c|
			if (c.prefix == pre && c.suffix == suf) then
				found = true
			elsif (c.suffix == "W" && suf == "W") then # special: is this card a wild?
				found = true
			elsif (c.suffix == "F" && suf == "F") then # special: is this card a wild draw 4?
				found = true
			end			
		}
		if (!found) then
			log("player doesn't have a #{card}")
			puts"hey there, you don't have a #{card}!"
			return false
		end 

		# store components of top card
		t_prefix = @top[0].chr
		t_suffix = @top[1].chr

		# check: can this card be played on the given top card?

		if (pre == t_prefix) then    # same color
			return true
		elsif (suf == t_suffix) then # same identifier
			return true
		elsif (suf == "W") then      # wild 
			return true
		elsif (suf == "F") then      # wild draw 4
			return true
		else
			log("#{card} cannot be played on a #{t_prefix}#{t_suffix}")
			puts "#{card} cannot be played on a #{t_prefix}#{t_suffix}"
			return false
		end

	end

    ######################################################################
	#                                                                    #
    #                    client game display methods                     #
	#                                                                    #
    ######################################################################

	def start_game_dialog()
		list = @players_list.join(", ")
		name = @player.getName()
	
		puts "-----------------------------------------------------------------"
		puts "|                                                               |"
		puts "|" +  "UNO game is beginning! Welcome, #{name}!".center(63) +  "|"
		puts "|                                                               |"
		puts "-----------------------------------------------------------------"
		list_players()
	end

	def help_dialog()
		puts "-----------------------------------------------------------------"
		puts "| UNO Help Menu:                                                |"
		puts "|                                                               |"
		puts "|    'chat'        chat with other players                      |"
		puts "|    'help'        show help menu                               |"
		puts "|    'list'        show players in this game                    |"
		puts "|    'play XX'     play card XX                                 |"
		puts "|    'quit'        quit current game                            |"
		puts "|    'show'        show current cards                           |"
		puts "|    'top'         show current top card                        |"
		puts "|                                                               |"
		puts "-----------------------------------------------------------------"
	end

	def list_players()
		list = @players_list.join(", ")
		puts "-----------------------------------------------------------------"
		puts "|"     +    "Players: #{list}".center(63)    +    "|"
		puts "-----------------------------------------------------------------"

	end

	def show_go()
		puts "-----------------------------------------------------------------"
		puts "|"     +    "Your Turn! Top Card: [#{@top}]".center(63)   +    "|"
		puts "|"           +    "My #{@player}".center(63)     +             "|"
		puts "-----------------------------------------------------------------"
	end


	def show_cards()
		puts "-----------------------------------------------------------------"
		puts "|"               +   "#{@player}".center(63)    +              "|"
		puts "-----------------------------------------------------------------"
	end

	def show_play(card)
		puts "-----------------------------------------------------------------"
		puts "|"        +      "Played: [#{card}]".center(63)    +          "|"
		puts "-----------------------------------------------------------------"
	end

	def show_top()
		puts "-----------------------------------------------------------------"
		puts "|"        +      "Top Card: [#{@top}]".center(63)    +          "|"
		puts "-----------------------------------------------------------------"
	end

	def show_quit()
		name = @player.getName()
		puts "-----------------------------------------------------------------"
		puts "|                                                               |"
		puts "|"    +    "Leaving UNO Game; Bye, #{name}!".center(63)    +   "|"
		puts "|                                                               |"
		puts "-----------------------------------------------------------------"		
	end

	def show_uno(name)
		puts "-----------------------------------------------------------------"
		puts "|"         +       "#{name}: UNO!".center(63)       +           "|"
		puts "-----------------------------------------------------------------"		
	end

	def show_win(name)

		if name == "" then
			puts "-----------------------------------------------------------------"
			puts "|"+"Sorry, The Game Ended Due To Insufficient Players...".center(63)+"|"
			puts "-----------------------------------------------------------------"
			log("server: game ended due to insufficient players")
		elsif name == @player.getName() then
			puts "-----------------------------------------------------------------"
			puts "|"   +   "Congratulations, #{name}! You Won!".center(63)  +   "|"
			puts "-----------------------------------------------------------------"
			log("congratulations, player won!: [GG|#{name}]")
		else
			puts "-----------------------------------------------------------------"
			puts "|"         +       "#{name} Wins!".center(63)      +           "|"
			puts "-----------------------------------------------------------------"
			log("player #{name} won!: [GG|#{name}]")
		end

	end

end #GameClient
