#!/usr/local/bin/ruby

#
# client_parse_args()
#
def client_parse_args(argv)

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
    argv.clear
end

#
# server_parse_args ()
#
def server_parse_args(argv)

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
    argv.clear
end

