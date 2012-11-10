#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'ClientClass'
require 'Constants'
include Constants

# client variables
$port       = Constants::PORT
$hostname   = Constants::HOSTNAME
$username   = Constants::USERNAME

#
# parse_args () -- client can redefine $port, $hostname, and $username
#

def parse_args()

    # Parse command line arguments
    argc = 0
    ARGV.each { |arg|

        if (arg.to_s).eql?("-p")                # set port#
            $port = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-h")             # set hostname
            $hostname = ARGV[argc+1].to_s
        elsif (arg.to_s).eql?("-u")             # set the clients name
            $username = ARGV[argc+1].to_s
        end

        argc+=1                                 # increment processed args        
    }
    
    # Empty ARGV
    ARGV.clear
end

#
# Main
#

if __FILE__ == $0 then

	# get command line arguments (if specified)
    parse_args()

	# initialize UNO game client
    unoGameClient = GameClient.new($hostname, $port, $username)

	# run client
    unoGameClient.run()

end #if
