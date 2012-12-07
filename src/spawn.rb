#!/usr/bin/env ruby

require 'Constants'
include Constants

# Defaults
$client_count = 5
$server_flag  = false
$host         = Constants::HOSTNAME
$port         = Constants::PORT

# names
$names   = ["Travis","Zeus","RonSwanson","DanTheMan","Mary","BigMike","Snookie", "ChuckNorris", "Jimmy","Pat","DannyBoy99","BartSimpson","Luke","Matthew","Mark","JohnTheBaptist"]
$colors  = ["black", "white"]

#
# spawn() - handle spawning of server/client(s)
#
def spawn()

    #
    # spawn instance of server
    #

    if $server_flag then
        begin
            puts "spawning instance of UNO server..."
            system("xterm -hold -title Server -e ruby server.rb &")
            sleep(2)
        rescue Exception => e
            puts "error: #{e.message}"
        end
    end

    #
    # spawn clients
    #

    # get monitor resolution
    dim_x, dim_y = `xrandr`.scan(/current (\d+) x (\d+)/).flatten

    puts "spawning #{$client_count} clients & connecting to server..."
    puts "---------------------------------------------------------------------"
    for i in 0...$client_count

        begin
	        sleep(0.5)
	        name = $names[ rand($names.size()) ]
	        bgcolor = $colors[0]
	        fgcolor = $colors[1]
	        x = (dim_x.to_i / 3) - 200 * i
	        y = 100 * i
            #x = rand( dim_x )
            #y = rand( dim_y )
            puts "client #{name} (#{x},#{y}) connecting to #{$host} on port #{$port}"
	        system("xterm -hold -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{name} -e 'ruby client.rb -u #{name} -p #{$port} -h #{$host} -a' &")
        rescue Exception => e
            puts "error: #{e.message} in client spawn: #{name} connecting to #{$host} on port #{$port}"
        end

    end
    puts "---------------------------------------------------------------------"

end


#
# parse_args() -- determine various spawn settings
#
def parse_args ()

    # Parse command line arguments
    argc = 0
    ARGV.each { |arg|

        if (arg.to_s).eql?("-s")                 # spawn server
            $server_flag = true
        elsif (arg.to_s).eql?("-n")              # set number of clients
            $client_count = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-p")              # set port#
            $port = ARGV[argc+1].to_i
        elsif (arg.to_s).eql?("-h")              # set host
            $host = ARGV[argc+1].to_s
        else
            puts "bad command line arg #{arg}"
        end
        
        argc+=1                                   # increment processed args
    }
    
    # Empty ARGV
    ARGV.clear
end

#
# Main
#

if __FILE__ == $0 then

    if ARGV.size() < 2 || ARGV.size() > 7 then

        puts "usage: ./#{$0} -n NUM_CLIENTS [-s] [-h HOSTNAME] [-p PORT]"

    else

        # determine settings
        parse_args()

        # clear screen to begin...
        system('clear')

        # handle spawning of processes
        spawn()

        # wait for a key to be pressed before killing all processes
        puts "press the enter key to kill spawned clients"
        char = STDIN.getc
        system('pkill xterm')

    end

end
