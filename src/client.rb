#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'ClientClass.rb'

# Defaults
$port       = 5555
$hostname   = 'localhost'
$username   = 'player'

#
# parse_args () -- client can redefine $port, $hostname, and $username
#
def parse_args()

    # Parse command line arguments
    argc = 0
    ARGV.each { |arg|

        if (arg.to_s).eql?("-p")              # set port#
            $port = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-h")           # set hostname
            $hostname = ARGV[argc+1].to_s
        elsif (arg.to_s).eql?("-u")           # set the clients name
            $clientname = ARGV[argc+1].to_s
        end

        argc+=1                               # increment processed args        
    }
    
    # Empty ARGV
    ARGV.clear
end

#
# Main
#
parse_args()
unoGameClient = GameClient.new($hostname, $port, $username)
unoGameClient.run()
