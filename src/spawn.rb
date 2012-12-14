#!/usr/bin/env ruby

require 'Constants'
include Constants

# Defaults
$client_count = 5
$server_flag  = false
$play         = false
$host         = Constants::HOSTNAME
$port         = Constants::PORT

# names
$names   = ["Zeus","RonSwanson","DanTheMan","Mary","BigMike","Snookie", "ChuckNorris", "Jimmy","Pat","DannyBoy","BartSimpson","Luke","Matthew","Mark","JohnTheBaptist"]
$colors  = ["black", "white","red","blue","green","yellow","purple"]

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
    # spawn auto clients
    #

    # get monitor resolution
    dim_x, dim_y = `xrandr`.scan(/current (\d+) x (\d+)/).flatten

    puts "spawning #{$client_count} clients & connecting to server..."
    puts "--------------------------------------------------------------------------------"
    for i in 0...$client_count

        begin
	        sleep(0.5)
	        name = $names[ rand( $names.size()) ]
			termName = "Auto:#{name}"
	        bgcolor = $colors[ rand( 6 ) ]
			if bgcolor == "yellow" || bgcolor == "white" then
				fgcolor = $colors[0]
			else
		        fgcolor = $colors[1]
			end
	        x = (dim_x.to_i / 3) - 200 * i
	        y = 100 * i

            puts "client #{name} connecting to #{$host} on port #{$port} & starting in auto mode"
	        system("xterm -hold -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{termName} -e 'ruby client.rb -u #{name} -p #{$port} -h #{$host} -a' &")
        rescue Exception => e
            puts "error: #{e.message} in manual client spawn: #{name} connecting to #{$host} on port #{$port}"
        end

    end
    puts "--------------------------------------------------------------------------------"
	
	#
	# spawn a manual client if flag was set
	#

	if $play then
        begin
	        sleep(0.5)
	        name = "Travis"
			termName = "Manual:#{name}"
	        bgcolor = $colors[3]
	        fgcolor = $colors[4]
	        x = (dim_x.to_i / 2)
	        y = (dim_y.to_i / 2)

            puts "manual client #{name} connecting to #{$host} on port #{$port} in manual mode"
	        system("xterm -hold -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{termName} -e 'ruby client.rb -u #{name} -p #{$port} -h #{$host}' &")
        rescue Exception => e
            puts "error: #{e.message} in client spawn: #{name} connecting to #{$host} on port #{$port}"
        end
	    puts "--------------------------------------------------------------------------------"
	end

end


#
# parse_args() -- determine various spawn settings
#
def parse_args ()

    # Parse command line arguments
    argc       = 0
	expectVal  = false
    ARGV.each { |arg|

        if (arg.to_s).eql?("-s")                 # spawn server
            $server_flag = true
			expectVal = false
        elsif (arg.to_s).eql?("-n")              # set number of clients
            $client_count = ARGV[argc+1].to_i
			expectVal = true
        elsif (arg.to_s).eql?("-p")              # set port#
            $port = ARGV[argc+1].to_i
			expectVal = true
        elsif (arg.to_s).eql?("-h")              # set host
            $host = ARGV[argc+1].to_s
			expectVal = true
        elsif (arg.to_s).eql?("-play")           # set player flag
            $play = true
			expectVal = false
        else
			if expectVal then
				# verify that that the next arg is a valid int value
				expectVal = false
				next
			else
	            puts "bad command line arg #{arg}"
				return -1
			end
        end
        
        argc+=1
    }
    
    # Empty ARGV
    ARGV.clear
	return 0
end

def show_usage()
    puts "usage: ./#{$0} -n NUM_CLIENTS [-s] [-h HOSTNAME] [-p PORT] [-play]"
end

#
# Main
#

if __FILE__ == $0 then

    if ARGV.size() < 2 || ARGV.size() > 8 then
		show_usage()
    else
        # determine settings
        ret_val = parse_args()

		if ret_val == 0 then

		    # clear screen to begin...
		    system('clear')

		    # handle spawning of processes
		    spawn()

		    # wait for a key to be pressed before killing all processes
		    puts "press the enter key to kill spawned clients"
		    char = STDIN.getc
		    system('pkill xterm')
		else
			show_usage()
		end
    end
end
