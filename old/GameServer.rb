#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'ServerMsg'

class GameServer

    #
    # public class methods
    #
    public
    
    def initialize(port, min, max, timeout, lobby)
        @port             = port                          # Port #
        @minPlayers       = min                           # Min players needed for game
        @maxPlayers       = max                           # Max players allowed for game
        @timeout          = timeout                       # Default timeout
        @lobby            = lobby                         # Max # players that can wait for a game
        @descriptors      = Array.new()                   # Collection of the server's sockets
        @serverSocket     = TCPServer.new("", port)       # The server socket (TCPServer)
        @gameTimerOn      = false                         # Time until game starts
        @gameInProgress   = false                         # Game status boolean
        @descriptors.push(@serverSocket)                  # Add serverSocket to descriptors
        
        #enables the re-use of a socket quickly
        @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

        log("Game Server started on port #{@port}")
    end #initialize
    
    def run()
        
        while true
            puts "[server] before select"
            result = select(@descriptors, nil, nil, @timeout)
            puts "[server] after select"
            if result != nil then
            
                # Iterate over tagged 'read' descriptors
                for socket in result[0]
                
                    # ServerSocket: Handle connection
                    if socket == @serverSocket then
                        puts "accepting..."
                        accept_new_connection()
                    else
                        
                        # ClientSocket: Read
                        if socket.eof? then
                            msg = "Client left #{socket.peeraddr[2]}:#{socket.peeraddr[1]}"
                            broadcast(msg, socket)
                            socket.close
                            #log(msg)
                            @descriptors.delete(socket)
                        else
                            msg = "[#{socket.peeraddr[2]}|#{socket.peeraddr[1]}]:#{socket.gets()}"
                            broadcast(msg, socket)
                            #log(msg)
                        end #if
                        
                    end #if
                
                end #for
            
            end #if
            
        end #while
        
    end #run
    
    #
    # private class methods
    #
    private
    
    def log(msg)
        puts "log: " + msg
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
        
        puts "added new socket to descriptors..."
        
        # Send acceptance message
        newSocket.write(ServerMsg::ACCEPT)
        
        puts "wrote to client.."
        
        # Broadcast 
        msg = "Client joined #{newSocket.peeraddr[2]}:#{newSocket.peeraddr[1]}\n"
        broadcast(msg, newSocket)
    
    end #accept_new_connection
    
    def accept_new_connection_wait()
        #TODO: Implement - if necessary
    end #accept_new_connection_wait

end #GameServer
