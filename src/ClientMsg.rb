#!/usr/local/bin/ruby

#
# Protocol
#
module ClientMsg

	#
	# Legal (recognized) server commands
	#
    @server_commands = ["ACCEPT", "CHAT", "DEAL", "GG", "GO", "INVALID", "PLAYED", "PLAYERS", "STARTGAME", "UNO", "WAIT"]

    #
    # Legal client commands
    #
    # Hash: {"command" => "arg_count"}
    #
    @commands = ["CHAT", "JOIN", "PLAY"]
    @valid_client_commands = {@commands[0] => 1,   # chat
                              @commands[1] => 1,   # play
                              @commands[2] => 1}   # join
                              
    @keys                  = @valid_client_commands.keys()
    @default               = "unknown command"

	def ClientMsg.valid?(cmd)
		return @server_commands.include?(cmd)
	end

	def ClientMsg.include?(cmd)
		return @commands.include?(cmd)
	end

    #
    # message(command, info)
    #
    # Input : A command represented as a string and an array of additional
    #         information.
    # 
    # Output: A fully constructed, pipe delimited, message that is intended to
    #         be sent to the Server as interaction from the Client.
    #         If the command cannot be processed or if an illegal amount of
    #         arguments are passed in as info (or both), then the message will
    #         return nil. 
    #
    def ClientMsg.message(command, info)

        # Determine if the command is valid & that there are an appropriate amount
        # of "arguments" passed in for that command 
        cmd = @keys.find { |c| c.downcase() == command.downcase() }
		
		val = 0
        if (cmd != nil) then
			cmd = cmd.upcase()
            val = @valid_client_commands[cmd]
        end #if

        argc = info.size()

        if (val == argc) then

            # format the arguments to the message before returning the string
            # that is to be sent to the server.
			args = info[0]			
			
            ####################################################################
            #                                                                  #
            #                          Client Messages                         #
            #                                                                  #
            ####################################################################
    
            #
            # This message is sent to the server from the client with a message that 
            # the client wants to say to the other clients. This message will be 
            # broadcasted by the server with the sender name at the beginning of 
            # the message.
            #    
            #chat = "[chat|MESSAGE]"
            #
            chat = "[CHAT|#{args}]"
            
            #
            # This message is sent to the server from the client telling the server 
            # that a client is joining and is using the nickname Name.
            #    
            # JOIN = "[join|USERNAME]"
            #    
            join = "[JOIN|#{args}]"
    
            #
            # This message is sent to the server from the client when the client 
            # plays a card. The card value will be the card that they client is 
            # playing. If a player is unable to play, the player will send a Play 
            # command with NN as their card. This will make the server deal the 
            # player a card on the first time an NN is sent and move to the next 
            # player on the second time it is sent.
            #
            # PLAY = "[play|CARD]"
            #
            play = "[PLAY|#{args}]"
    
            ####################################################################
            #                                                                  #
            #                          Construct Message                       #
            #                                                                  #
            ####################################################################
    
            msg = ""
    
            # Return the message w/ valid command & the specified arguments
            case cmd
    
            when @commands[0]         # join message 
                msg = chat
            when @commands[1]         # play message
                msg = join
            when @commands[2]         # chat message
                msg = play
            end #case
    
            return msg

        else # bad arg count
            return nil
        end #if

    end #message

end #ClientMsg
