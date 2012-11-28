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

        # parameters for select
        @timeout      = 3                       # Client timeout for select call
        @descriptors  = Array.new()             # Collection of sockets
        @descriptors.push(STDIN)                # Client socket (standard input)

		@player       = nil
		@top          = nil

		@state  = :lobby
		@states = [:lobby, :start, :wait, :play]

        log("Game client #{@hostname} started on port #{@port}")

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
            puts "\nclient application interrupted: shutting down..."
            exit 0
        rescue SystemExit => e
            # On a system exit, exit gracefully
        rescue StandardError => e
            puts 'Exception: ' + e.message()
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
        puts "log: " + msg.to_s
    end #log

    def err(msg)
        puts "log: error: " + msg.to_s
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
			puts "buffer on read :[#{@buffer}]"

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
        msg = STDIN.gets()

		# check for client disconnect command
        if (msg.slice(0,4).eql?("quit") || msg.slice(0,4).eql?("exit")) then

            log("signing off...")
            exit 0

        end

		# list who is in the game still (l)

		# show current cards (s)

		# play a card (p)
		if ((msg.slice(0,1) == "p") || (msg.slice(0,1) == "P")) then

			card = msg[2...-1].upcase

			##############################
			play = checkPlayable(card)
			##############################

			if (play) then
				c = Card.new(card[0].chr.upcase(), card[1].chr.upcase())
				@player.discard(c)
				msg = ClientMsg.message("PLAY",[card])
				@clientSocket.write(msg)
			    log("write: " + msg)

			else
				return
			end

			##############################

		# chat
		else

			tmp = msg.chomp()
			msg = ClientMsg.message("CHAT",[tmp])
			@clientSocket.write(msg)
	        log("write: " + msg)

		end

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

		puts "buffer matched #{@buffer}"
		#puts m

		# upon matching: (1) set command, (2) set command info, and (3) remove
		#  this portion of the message from @buffer
		if m != nil then
			command = m[1].upcase()
			info    = m[2]
			@buffer.sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
		else
			puts "received #{data}" #DEBUG
			return nil
		end

		puts "updated buffer: [#{@buffer}]"

		# validate: command
		if !(ClientMsg.valid?(command)) then
			# command not recognized
			return nil
		end

'''
		if (command == "ACCEPT") then
			pass = true
		elsif (command == "CHAT") then
			pass = true
		elsif (command == "DEAL") then
			pass = true
		elsif (command == "GG") then
			pass = true
		elsif (command == "GO") then
			pass = true
		elsif (command == "INVALID") then
			pass = true
		elsif (command == "PLAYED") then
			pass = true
		elsif (command == "PLAYERS") then
			pass = true
		elsif (command == "STARTGAME") then
			pass = true
		elsif (command == "UNO") then
			pass = true
		elsif (command == "WAIT") then
			pass = true
		else
			# command not recognized
			return nil
		end
'''

		#validate: info following command
		if (info.size() < 1 || info.size() > 128) then
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
		if (command == nil || command == "" || args == nil || args == "") then
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
		puts "creating player with name #{name}" # DEBUG
		@clientName = name
		@player = Player.new(@clientName, 0)
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

        log("read: #{name}: #{msg}")
	end

	#
	# Handle Deal:
	#
	# parse string of card(s) & add to player hand
	#
	def handle_deal(msg)
        log("read: dealt: [#{msg}]") # DEBUG

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
		if name == @player.getName()
			log ("read: you win!")
		else
	        log("read: player #{name} wins.")
		end
		
		# state: lobby
		@state = :lobby 
	end

	def handle_go(card)
		@top = card
        log("read: GO (top card is #{card})")
		puts @player.to_s

		# state: play
		@state = :play
	end

	def handle_invalid(msg)
        err("read: server-error: #{msg}")
	end

	def handle_played(msg)
		list = parse_str(msg)
		name = list[0]
		card = list[1]
		@top = card

        log("read: player #{name} played: #{card}")

		# state: wait
		if (name == @player.getName()) then
			@state = :wait
		end
	end

	def handle_players(msg)
		#list = parse_str(msg)		
        log("read: new player joined: players: #{msg}")
	end

	def handle_startgame(msg)
		#list = parse_str(msg)
        log("read: starting game: players: #{msg}")
		@state = :start
	end

	def handle_uno(name)
        log("read: player #{name} said 'UNO!'")
	end

	def handle_wait(name)
        log("read: game in progress: creating player with name #{name} & waiting...") # DEBUG
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
			log("it is not your turn to play yet!")
			return false
		end

		# check: type
		if (!card.kind_of?(String)) then
			log("(1) #{card} is not a valid card")
			return false
		end

		# check: card not nil
		if (card == nil || card == "") then
			log("you did not play a card (empty)")
			return false
		end

		# check: valid card length
		if card.length() > 2 then
			log("(2) #{card} is not a valid card")
			return false
		end

		if (card[0] == nil || card[1] == nil) then
			log("(3) #{card} is not a valid card")
			return false
		end

		# check: no play (NN)
		if (card == "NN") then
			log("couldn't play, eh?")
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
			log("you don't have a #{card}")
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
			return false
		end

	end

end #GameClient
