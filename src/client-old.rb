#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'socket' 

$socket

# Defaults
$pname      = 'client.rb'
$port       = 5555
$hostname   = 'localhost'
$clientname = 'player'

#
# parse_args () -- client can redefine port#, hostname, and their own name
#
def parse_args ()

    # The program name is stored in $0
    $pname = $0

    # Parse command line arguments
    argc = 0
    ARGV.each { |arg|

        if (arg.to_s).eql?("-p")              # get the port
            $port = ARGV[argc+1].to_i
            #puts $port
        elsif (arg.to_s).eql?("-h")           # get the hostname
            $hostname = ARGV[argc+1].to_s
            #puts $hostname
        elsif (arg.to_s).eql?("-u")           # get the clients name
            $clientname = ARGV[argc+1].to_s
            #puts $clientname
        end
        argc+=1                               # increment processed args
        
    }
    
    # Empty ARGV
    ARGV.clear
end

#
# main ()
#
def main ()

    # Check if default parameters have been redefined
    parse_args()

    # Main loop
    run = true
    while (run)

        # Open the socket
        $socket = TCPSocket.new($hostname, $port)

        read, write, error = IO.select([$socket], [$socket], nil, 3 )

        if read == $socket                                   # Reading from server
            in_msg = $socket.read
            puts "server: " + in_msg
        elsif write = $socket                                # Writing to server
            out_msg = $clientname + " wants to connect!"    
            puts "log: " + out_msg
            $socket.write out_msg
        else
            puts "..."
        end        
        
        #------------------------#

        # Read lines from socket
        #while line = $socket.gets
        #    puts line.chop
        #end

        print "Continue: "
        input = gets.chomp()
        if input.eql?("n")
            run = false
        end


        # Close the socket before ending
        $socket.close
    end
    
end


# Main
main()
