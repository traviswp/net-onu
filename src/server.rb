#!/usr/bin/env ruby

# Sockets are in the standard library
require 'ServerClass.rb'
require 'Constants'

include Constants

# Defaults
$port       = Constants::PORT
$min        = Constants::MIN
$max        = Constants::MAX
$timeout    = Constants::TIMEOUT
$lobby      = Constants::LOBBY
$debug_on   = false

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
        elsif (arg.to_s).eql?("-d")              # set the debug flag
            $debug_on = true
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
    unoGameServer = GameServer.new($port, $min, $max, $timeout, $lobby, $debug_on)
    unoGameServer.run()
end #if
