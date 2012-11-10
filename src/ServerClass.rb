#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
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
        @descriptors.push(@server_socket)                  # Add serverSocket to descriptors
        
        # enables the re-use of a socket quickly
        @server_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        # variables: player management
        @players_list     = PlayerQueue.new()
		@current_players  = 0                             # Current number of players connected (for next/current game)
		@total_players    = 0                             # Total number of players connected
        @min_players      = min                           # Min players needed for game
        @max_players      = max                           # Max players allowed for game
        @lobby            = lobby                         # Max # players that can wait for a game

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
				
				if (@game_in_progress && player_check)                          # game in progress
					puts "service: game in progress - check game state(s)"
					# TODO: add conditional logic to check for game-end
					@game_in_progress = false                                   # game end: deactivate game_in_progress
				elsif (@game_timer_on) 
					@current_time = Time.now().to_i
					puts "timer: " + ((@current_time-@start_time).abs()).to_s

					if ((@current_time-@start_time).abs() > @timeout)           # start game
						puts "service: starting game"
						@game_in_progress = true                                # set game_in_progress
						@game_timer_on = false                                  # turn timer off
					end #if
				elsif (player_check) 
					if (!@game_timer_on)
						puts "service: activate game timer"
						@game_timer_on = true                                   # activate game timer
						@start_time = Time.now().to_i                           # set start_time
					end #if
					if (@new_connection)
						puts "service: new connection & reset timer"
						@new_connection = false                                 # reset connection status
						@start_time = Time.now().to_i                           # reset start_time
					end #if
				elsif (@new_connection && @game_in_progress)                    # player joing after game is full/game started
					puts "service: add player to lobby & wait for next game"
					@new_connection = false
				elsif (@new_connection && !@game_in_progress)                   # player joing after game is full/game started
					puts "service: (initial) new connection"
					@new_connection = false
				end #if
				
                
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
    #
    # private class methods
    #
    #

    private
    
    def log(msg)
        puts "log: " + msg.to_s
    end #log
    
    def broadcast(msg, omit_sock)
        
        # Iterate over all known sockets, writing to everyone except for
        # the omit_sock & the serverSocket
        @descriptors.each do |client_socket|
            
            if client_socket != @server_socket && client_socket != omit_sock
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

        ##################################
        client_name = name_validation(args)
		
		# create Player object
		# add player to player list
		@current_players = @current_players + 1
		@total_players = @total_players + 1
        ##################################

        msg = ServerMsg.message("accept",[client_name])
        puts "message: " + msg
      
        new_socket.write(msg)

        # Broadcast 
        msg = "Client joined #{new_socket.peeraddr[2]}:#{new_socket.peeraddr[1]}\n"
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
            #exists = @playersList.find { |n| n.getName() == name }
            if exists then
                name = name + numId.to_s
                numId = numId + 1
            else
                break
            end #if

        end #while

        return name

    end #name_validation

end #GameServer
