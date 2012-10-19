#!/usr/local/bin/ruby

# Game Libraries
require 'PlayerQueue'

# Sockets are in the standard library
require 'socket' 

# Default server port
port = 5555

# Open socket to listen on the specified port
puts "starting server..."
$server = TCPServer.new('', port)

# Players queue
waiting_players_list = PlayerQueue.new()
active_players_list  = PlayerQueue.new()

#loop {
    #a = TCPServer.new('', 3333) # '' means to bind to "all interfaces", same as nil or '0.0.0.0'
#    connection = server.accept

    #read, write, error = IO.select([$socket], [$socket], [$socket], 3 )    
    
#    puts "received:" + connection.recv(1024)
#    connection.write 'got something--closing now--here is your response message from the server'

    
#    connection.close
#}

def accept_new_connection()
    puts "log: player '' has joined."
    #get username from client connection
    #make new player object
    #add to active_players_list
end

def accept_and_wait()
    puts "log: player '' is waiting for the next game."
    #get username from client connection
    #make new player object
    #add to waiting_players_list
end

def run()  

    game_in_progress = false

    while true

        # Check all sockets that need to be read from
        result = select([$server], nil, nil, 3.0)
        
        if result != nil then
            
            for socket in result[0]
            
                if socket == $server && !game_in_progress then    # Game open - add player
                    accept_new_connection()
                elsif socket == $server && game_in_progress then  # Game in progress - wait for next game
                    accept_and_wait()
#                elsif sock == @snmpSocket then
#                    get_snmp_message
#                elsif sock == @mailSocket then
#                    reject_mail
#                elsif sock == @messageSocket then
#                    get_message()
                else
                    puts "log: nothing to read from..."
                end  
            end  
        end
    end
end

run()




################################################################################


#connection.close
    
#    client = server.accept                         # Wait for a client to accept
#    client.puts(Time.now.ctime)                    # Send the time to the client

#    if (players.length() >= 4)
#        puts "Going to break - 4 players are connected!" 
#        break; 
#    end
    
#}

#client.puts "Closing the connection. Bye!"     #
#client.close                                   # Disconnect from the client
