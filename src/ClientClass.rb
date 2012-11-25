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
        @buffer = Array.new(@MAX_MSG_LEN)

        # parameters for select
        @descriptors  = Array.new()             # Collection of sockets
        @timeout      = 3                       # Client timeout for select call

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
                            err("unknown")
                        end #if

                    end #for

                end #if

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

    def read()
	
		msg = @clientSocket.gets()

		#buffer the msg 

        if msg == nil then
            dropped_connection()
            return nil
        else
			process(msg)
            return msg
        end #if

    end #read

    def write()

		# get input
        msg = STDIN.gets()

		# check for client disconnect command
        if (msg.slice(0,4).eql?("quit") || msg.slice(0,4).eql?("exit")) then

            log("signing off...")
            exit 0

        end

		# play
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

	def process(message)

		# Match (1) the command and (2) the content of the message
	    re = /\[([a-z]{2,9})\|([\w\W]{0,128})\]/i
		args = message.match re

		# Separate arguments if args is not nil 
		if args != nil then
		    command = args[1]
		    info    = args[2]
		else
		    return nil 
		end # if

		# call appropriate handler method based on command:

		if (command == "ACCEPT") then
			handle_accept(info)
		elsif (command == "CHAT") then
			handle_chat(info)
		elsif (command == "DEAL") then
			handle_deal(info)
		elsif (command == "GG") then
			handle_gg(info)
		elsif (command == "GO") then
			handle_go(info)
		elsif (command == "INVALID") then
			handle_invalid(info)
		elsif (command == "PLAYED") then
			handle_played(info)
		elsif (command == "PLAYERS") then
			handle_players(info)
		elsif (command == "STARTGAME") then
			handle_startgame(info)
		elsif (command == "UNO") then
			handle_uno(info)
		elsif (command == "WAIT") then
			handle_wait(info)
		else
			# error - shouldn't get invalid messages from the server
			err(message)
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
        log("read: deal: " + msg) # DEBUG

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

	#
	# Parse String:
	#
	# Input : comma delimited string of arguments
	# Output: array of arguments
	#
	def parse_str(str)
		return str.split(',')
	end

	def parse_message()
		#TODO: Implement ?
	end

end #GameClient
