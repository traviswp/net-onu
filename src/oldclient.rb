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
        @buffer = Array.new(@MAX_MSG_LEN)

        # parameters for select
        @descriptors  = Array.new()             # Collection of socket [should only hold 1 socket]
        @w_descriptors = Array.new()
        #@out
        @timeout      = 3                       # Client timeout for select call

        @descriptors.push(STDIN)                # Client can write manually write to server
        @w_descriptors.push(STDIN)
        connect()                               # Connect to server

        log("Game client #{@hostname} started on port #{@port}")
    end #initialize

    def run()

        begin # error handling block

            while true

                result = select(@descriptors, @w_descriptors, nil, @timeout)
#puts "after select"

result.each do |s| 
    puts s.to_s
end

                if result != nil then

                    # Iterate over tagged 'read' descriptors
                    for socket in result[0]
#puts "inside"
                        # ServerSocket: Handle connection
                        if socket == @clientSocket then
                        
                            # Read from server
                            puts "reading..."
                            read()
                            puts "after read..."
                            #check = @clientSocket.read() #######################   <<------- I think this is the problem...
                            #puts "[" + check.to_s + "]"
                            # Check server status (still connected?)
                            #if check == "" then
                            #if false then
                            #    puts "server connection dropped..."
                            #    socket.close()
                            #    @descriptors.delete(socket)
                            #    exit 0
                            #end
                            
                        elsif @clientSocket.eof? then
                            #socket.close()
                            log("eof?...")
                            #@descriptors.delete(socket)
                            #running = false
                        elsif socket == STDIN then
                            puts "writing..."
                            #write()
                        else
                            puts "what?"
                        end #if

                    end #for
                
                end #if

            end #while

        rescue Interrupt
            puts "\nclient application interrupted: shutting down..."
            exit 0
        rescue Exception => e
            puts 'Exception: ' + e.message()
            print detail.backgrace.join('\n')
            retry
        end # error handling block

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
        length = 0
        while (c = @clientSocket.getc())                # process msg 1 character at a time

            c = c.chr                                   # convert ASCII value to character

            # Construct msg buffer from server
            if !(c.eql?('[')) and !(c.eql?(']')) then
                puts "character = #{c}"
                buffer.push(c)
            end #if
            puts "what?"
            # Terminate msg
            if (c.eql?(']')) or (c.eql?("\n")) then
                break
            end #if
    puts "here"
            if (c.eql?("") or (c == nil) or c.eql?("\n")) then
                puts "thats what I thought..."
            end #if

            length+=1

        end #while
puts "buffer = " + buffer.to_s
        return buffer

    end #read

    def write()

        msg = STDIN.gets()
puts "not here though"
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

            #puts "my_name" + ClientMsg.message("join", [@clientName]) #TESTING
            
            @clientSocket.write(ClientMsg.message("join", [@clientName]))

            return 0

        #rescue Exception => e

        #    err("could not connect to #{@hostname} on port #{@port}")
        #    exit -1

        end #begin

    end #connect

end #GameClient
