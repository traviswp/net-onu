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
        @timeout      = 3                       # Client timeout for select call

        @descriptors.push(STDIN)                # Client can write manually write to server

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
    end #err

    def read() 

        msg = @clientSocket.gets()

        if msg == nil then
            dropped_connection()
            return nil
        else
            log("read: " + msg)
            return msg
        end #if

    end #read

    def write()

        msg = STDIN.gets()

        if msg.slice(0,4).eql?("quit") || msg.slice(0,4).eql?("exit") then
            log("signing off...")
            exit 0
        end

        @clientSocket.write(msg)
        log("write: " + msg)

    end #write

    def connect()

        begin 

            @clientSocket = TCPSocket.new(@hostname, @port)
            #@running = true
            @descriptors.push(@clientSocket)         

            msg = ClientMsg.message("join", [@clientName])
            log("write: " + msg)
            @clientSocket.write(msg)

            return 0

        rescue Errno::ECONNREFUSED
            puts "connection refused: could not connect to #{@hostname} on port #{@port}."
            exit 0
        rescue SystemExit => e
            # On a system exit, exit gracefully

        end #begin

    end #connect

    def dropped_connection()
        puts "server connection dropped..."
        @clientSocket.close()
        @descriptors.delete(@clientSocket)
    end #dropped_connection

end #GameClient
