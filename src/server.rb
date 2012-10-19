#!/usr/local/bin/ruby

# Sockets are in the standard library
require 'ServerClass.rb'

# Defaults
$port       = 5555
$min        = 2
$max        = 10
$timeout    = 3
$lobby      = 60

#
# parse_args () -- server can redefine port#, timeout, min/max # of players, and lobby capacity
#
def parse_args ()

    # Parse command line arguments
    argc = 0
    ARGV.each { |arg|

        if (arg.to_s).eql?("-p")                 # set port#
            $port = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-tout")           # set timeout
            $timeout = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-min")            # set min # players
            $min = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-max")            # set max # players
            $max = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-lobby")          # set the lobby capacity
            $lobby = ARGV[argc+1].to_i
        end
        
        argc+=1                                  # increment processed args
    }
    
    # Empty ARGV
    ARGV.clear
end

#
# Main
#

if __FILE__ == $0 then
    parse_args()
    unoGameServer = GameServer.new($port, $min, $max, $timeout, $lobby)
    unoGameServer.run()
end #if
