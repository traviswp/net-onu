#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'ServerMsg'
require 'PlayerList'

include ServerMsg

class GameServer

    #
    #
    # public class methods
    #
    #

    public
    
    def initialize(port, min, max, timeout, lobby)

        @port             = port                          # Port #
        @minPlayers       = min                           # Min players needed for game
        @maxPlayers       = max                           # Max players allowed for game
        @lobby            = lobby                         # Max # players that can wait for a game
        @gameTimerOn      = false                         # Time until game starts
        @gameInProgress   = false                         # Game status boolean

        # parameters for select
        @descriptors      = Array.new()                   # Collection of the server's sockets
        @serverSocket     = TCPServer.new("", port)       # The server socket (TCPServer)
        @timeout          = timeout                       # Default timeout

        @descriptors.push(@serverSocket)                  # Add serverSocket to descriptors
        
        #enables the re-use of a socket quickly
        @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        log("Game Server started on port #{@port}")

        # Players queue
        @playersList = PlayerQueue.new()

    end #initialize
    
    def run()

        begin # error handling block
        
            while true

                result = select(@descriptors, nil, nil, @timeout)

                if result != nil then
                
                    # Iterate over tagged 'read' descriptors
                    for socket in result[0]
                    
                        # ServerSocket: Handle connection
                        if socket == @serverSocket then
                            accept_new_connection()
                        else
                            
                            # ClientSocket: Read
                            if socket.eof? then
                                msg = "Client left #{socket.peeraddr[2]}:#{socket.peeraddr[1]}"
                                broadcast(msg, socket)
                                socket.close
                                @descriptors.delete(socket)
                            else #chat
                                msg = "[#{socket.peeraddr[2]}|#{socket.peeraddr[1]}]:#{socket.gets()}"
                                broadcast(msg, socket)
                            end #if
                            
                        end #if
                    
                    end #for            

                end #if

				#service game state
                
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
        @descriptors.each do |clientSocket|
            
            if clientSocket != @serverSocket && clientSocket != omit_sock
                clientSocket.write(msg)
            end #if
            
        end #each
        
        log(msg)
                    
    end #broadcast
    
    def accept_new_connection()
        
        # Accept connect & add to descriptors
        newSocket = @serverSocket.accept
        @descriptors.push(newSocket)

        # Send acceptance message
        args = newSocket.gets()

        ##################################
        clientName = name_validation(args)
        ##################################

        msg = ServerMsg.message("accept",[clientName])
        puts "message: " + msg
      
        newSocket.write(msg)

        # Broadcast 
        msg = "Client joined #{newSocket.peeraddr[2]}:#{newSocket.peeraddr[1]}\n"
        broadcast(msg, newSocket)

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
