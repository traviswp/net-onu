#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 
require 'ClientMsg'
include ClientMsg

class GameClient

    #
    #
    # public class methods
    #
    #
    
    public

    def initialize(hostname, port, clientName)
        @hostname     = hostname                # Server address to connect to
        @port         = port                    # Server port to connect to
        @clientName   = clientName              # Client's name
        @running      = false                   # Boolean to detect server status
        @playing      = false                   # Boolean to detect game play status
        @clientSocket = []                      # Client socket (TCPSocket)
        @MAX_MSG_LEN  = 1024                    # Max length of msg that will be read from server

        # parameters for select
        @descriptors  = Array.new()             # Collection of socket [should only hold 1 socket]
        #@out
        @timeout      = 3                       # Client timeout for select call

        @descriptors.push(STDIN)                # Client can write manually write to server
        connect()                               # Connect to server

        log("Game client #{@hostname} started on port #{@port}")
    end #initialize

    def run()

        while true

            result = select(@descriptors, nil, nil, @timeout)

            if result != nil then

                # Iterate over tagged 'read' descriptors
                for socket in result[0]
                
                    # ServerSocket: Handle connection
                    if socket == @clientSocket then
                        puts "reading..."
                        #read()
                        puts "socket = " + socket.to_s
                        puts "client socket = " + @clienSocket.to_s
                        puts "server: " + @clientSocket.recvfrom(@MAX_MSG_LEN).to_s
                    elsif @clientSocket.to_s == nil then
                        socket.close()
                        log("server connection dropped...")
                        @descriptors.delete(socket)
                        running = false
                    elsif socket == STDIN then
                        puts "writing..."
                        write()
                    end #if
                
                end #for
            
            end #if

        end #while

    end #run

    #
    #
    # private class methods
    #
    #
    
    private

    def log(msg)
        puts "log: " + msg
    end #log

    def err(msg)
        puts "log: error: " + msg
    end

    def read() 
    
        buffer = []                                     # msg buffer
        while (c = @clientSocket.getc())                # process msg 1 character at a time

            c = c.chr                                   # convert ASCII value to character

            # Construct msg buffer from server
            if !(c.eql?('[')) and !(c.eql?(']')) then
                puts "character = #{c}"
                buffer.push(c)
            end #if
            
            # Terminate msg
            if (c.eql?(']')) then
                break
            end #if

            length += 1

        end #while

        return buffer

    end #read

    def write()
        
        msg = STDIN.gets()

        if msg.slice(0,4).eql?("quit") then
            log("signing off...")
            exit 0
        end

        @clientSocket.write(msg)
    end #write

    def connect()

        begin 

            @clientSocket = TCPSocket.new(@hostname, @port)
            @running = true
            @descriptors.push(@clientSocket)         

            puts "my_name" + ClientMsg.message("join", $clientname) #TESTING
            
            @clientSocket.write(ClientMsg.message("join", $clientname))

            return 0

        #rescue Exception => e

        #    err("could not connect to #{@hostname} on port #{@port}")
        #    exit -1

        end #begin

    end #connect

end #GameClient
