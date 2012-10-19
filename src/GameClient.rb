#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'ClientMsg'

class GameClient

    #
    # public class methods
    #
    public

    def initialize(hostname, port, clientName)
        @hostname     = hostname                # Server address to connect to
        @port         = port                    # Server port to connect to
        @clientName   = clientName              # Client's name
        @running      = false                   # Boolean to detect server status
        @playing      = false                   # Boolean to detect game play status
        @clientSocket = []                      # Client socket (TCPSocket)
        @descriptors  = Array.new()             # Collection of socket
                                                #    [should only hold 1 socket]
        @descriptors.push(STDIN)                # Client can write manually write to server
        connect()                               # Connect to server

        log("Game Client #{@hostname} started on port #{@port}")
    end #initialize

    def run()

        while true

            result = select(@descriptors, nil, nil, 0.5)
            
            if result != nil then
            
                # Iterate over tagged 'read' descriptors
                for socket in result[0]
                
                    # ServerSocket: Handle connection
                    if socket == @clientSocket then
                        read()
                    elsif socket.eof? then
                        socket.close
                        log(ClientMsg::DROPPED)
                        @descriptors.delete(socket)
                        running = false
                    elsif socket == STDIN then
                        write()
                    end #if
                
                end #for

                # Iterate over tagged 'write' descriptors
                for socket in result[1]
                    
                    if socket == STDIN then
                        message()
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

    def read()
        puts @clientSocket.read()
    end #read

    def write()
        @clientSocket.write(STDIN.gets)
    end #write

    def connect()
        @clientSocket = TCPSocket.new(@hostname, @port)
        @running = true
        @descriptors.push(@clientSocket)
        @clientSocket.write(ClientMsg::JOIN)
    end

end #GameClient
