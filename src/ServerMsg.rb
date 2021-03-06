#!/usr/bin/env ruby

#
# Protocol
#
module ServerMsg

    #
    # Legal server commands
    #
    # Hash: {"command" => "arg_count"}
    #
    @commands = ["ACCEPT", "CHAT", "DEAL", "GG", "GO", "INVALID", "PLAYED", "PLAYERS", "STARTGAME", "UNO", "WAIT"]
    @valid_server_commands = {@commands[0]  => 1,            # accept
							 @commands[1]  => 2,            # chat
							 @commands[2]  => 7,            # deal
							 @commands[3]  => 1,            # gg
							 @commands[4]  => 1,            # go
							 @commands[5]  => 1,            # invalid
							 @commands[6]  => 2,            # played
							 @commands[7]  => 100,          # players
							 @commands[8]  => 100,          # startgame
							 @commands[9]  => 1,            # uno
							 @commands[10] => 1}            # wait
                              
    @keys                  = @valid_server_commands.keys()
    @default               = "unknown command"
    

	#
	# Legal (known) client commands
	#
    @client_commands = ["CHAT", "JOIN", "PLAY"]
    
	def ServerMsg.valid?(cmd)
		return @client_commands.include?(cmd)
	end


    #
    # formatMessage(list)
    #
    # Input : An array of strings, concatentates them together and separates
    #         them by the pipe ("|") character. 
    #
    # Output: Returns a single string that is pipe delimited
    # 
    def ServerMsg.formatMessage(list, argc)
        
        p_list = ""
        if argc == 1 then                          # arg is the only string in list
            p_list = list[0]
            return p_list 
        else
            for i in 0...argc-1                    # process the list by looping through
                p_list = p_list + list[i] + ","    # concatenating the strings and
            end                                    # separating them with the commas
            p_list = p_list + list[argc-1]
            return p_list
        end #if    

    end #formatMessage

    def ServerMsg.message(command, info)

		# initial type check
		if !(info.kind_of? Array)
			return nil
		end

        # Determine if the command is valid & that there are an appropriate amount
        # of "arguments" passed in for that command 
        cmd = @keys.find { |c| c.downcase() == command.downcase() }
		
		val = 0
        if (cmd != nil) then
			cmd = cmd.upcase()
            val = @valid_server_commands[cmd]
        end #if
        
		argc = info.size()

        if ((argc > 0) && (argc <= val)) then

            # format the arguments to the message before returning the string
            # that is to be sent to the server. 
			if (cmd == "CHAT") 
				sendername = info[0]
				args = info[1]
			else
				args = formatMessage(info, argc)
            end #if
			
            ########################################################################
            #                                                                      #
            #                         Broadcasted Messages                         #
            #                                                                      #
            ########################################################################
    
			#
			#
			#
			chat = "[CHAT|#{sendername},#{args}]"

            #
            # gg = "good game" & signifies game over.
            #
            # This message is sent to all of the clients from the server when a player 
            # played their last card and won the game. The name sent is the name of 
            # the winner. After this is sent, the server will go back into a lobby state.
            #
            # gg        = "[gg|WINNER_NAME]"
            #
            gg = "[GG|#{args}]"
    
            #
            # This message is sent to the clients from the server telling all of the 
            # players who just played a card and what card they played.
            #
            # played    = "[played|PLAYERNAME,CARD]"
            #
            played = "[PLAYED|#{args}]"
            
            #
            # This message is sent to all of the currently connected clients from the 
            # server listing all of the players that are connected and waiting to play. 
            # In the event a client disconnects, another Players command will be sent 
            # out to show the new player list.
            #
            # PLAYERS   = "[players|NAME1,NAME2,...]"
            #
            players = "[PLAYERS|#{args}]"
    
            #
            # This message is sent to all of the currently connected clients from the 
            # server telling all of the clients that the game has started. This message 
            # also lists all of the players in the game.
            #
            # startgame = "[startgame|NAME1,NAME2,...]"
            #
            startgame = "[STARTGAME|#{args}]"
			
			#
			# This message is sent to all clients to indicate when a player has
			# only one remaining card.
			#
			# uno = "[uno|name]"
			#
			uno = "[UNO|#{args}]"
            
            ########################################################################
            #                                                                      #
            #                        Client Specific Messages                      #
            #                                                                      #
            ########################################################################
    
            #
            # This message is sent to a client from the server telling the client 
            # that they have been accepted into the game. The name coming back from 
            # the server may be different if the name the client sent with the join 
            # command was already taken. If this happens, a number will be appended 
            # to the end of the client's nickname.
            #
            # accept    = "[accept|USERNAME]"
            #
            accept    = "[ACCEPT|#{args}]"
            
            #
            # This message is sent to a client when it is getting dealt cards. 
            # This command will work when any number of cards is being dealt to a client.
            # The number being dealt will be as follows:
            #    -Initial deal: 7 cards will be dealt
            #    -Unable to play: 1 card will be dealt
            #    -Draw 2 is played by previous player: 2 cards will be dealt
            #    -Wild draw 4 card is played by previous player: 4 cards will be dealt
            #
            # The format of the cards in the message will be the first letter of the 
            # color (for example: R for red), followed by the number or character 
            # representing the type of card. If the card is a draw 2 card, the second 
            # character will be a D. If the card is a skip card, the character will be 
            # an S. If the card is a wild card, the characters will be NW, the N 
            # signifying that it doesn’t have a color. This will be changed to a color 
            # when it is played. If the card is a wild draw 4 card, the characters will 
            # be NF. The same rule about the second character of the wild card applies 
            # to the wild draw 4 card as well.
            #
            # A few examples of cards: a red 4 is R4, a green draw 2 is GD, 
            # a yellow skip is YS, a blue reverse is BU, a wild card is NW, 
            # a wild draw 4 card is NF, etc.
            # 
            # deal      = "[deal|CARD1,CARD2,...]"
            #
            deal      = "[DEAL|#{args}]"
    
    
            #
            # This message is sent to the client from the server telling the client 
            # that it is that client's turn. The card is the top card on the discard 
            # pile. The format of how the card will be look follows how the cards 
            # command formats the cards except if the card is a wild card, a color 
            # will be specified. So, for example, if the player that played the wild 
            # card specified the color to be yellow, the card would show up as YW. 
            # This is true for wild draw 4 cards as well, so if a player decided to 
            # chose red as their color, it would show up as RF.
            #
            # go        = "[go|TOPCARD]"
            #
            go        = "[GO|#{args}]"
            
            #
            # This message is sent to the client that just tried to play an invalid 
            # play. This can happen if the card can't be played in the given 
            # circumstances, for instance the player tried to play a green 7 on a 
            # yellow 5, or if the player tried to play a card that the player didn't 
            # have. The message field will tell the player why their play was an 
            # invalid play.
            #
            # invalid   = "[invalid|MESSAGE]"
            #
            invalid   = "[INVALID|#{args}]"
    
            #
            # This message is sent to the client from the server when the client tried 
            # to join after the game has started. The name field is their name and the 
            # same rules apply here as they do in the Accept command.    
            #
            # wait      = "[wait|RETURN_NAME]"
            #
            wait      = "[WAIT|#{args}]"
            
            ####################################################################
            #                                                                  #
            #                          Construct Message                       #
            #                                                                  #
            ####################################################################

            msg = ""
    
            # Return the message w/ valid command & the specified arguments
            case cmd
    
            when @commands[0]         #  accept message 
                msg = accept
            when @commands[1]         #  chat message
                msg = chat
            when @commands[2]         #  deal message
                msg = deal
            when @commands[3]         #  gg message
                msg = gg
            when @commands[4]         #  go message
                msg = go
            when @commands[5]         #  invalid message
                msg = invalid
            when @commands[6]         #  played message
                msg = played
            when @commands[7]         #  players message
                msg = players
            when @commands[8]         #  startgame message
                msg = startgame
            when @commands[9]         #  uno message
                msg = uno
            when @commands[10]        #  wait message
                msg = wait
            end #case
    
            return msg #+ "\n"

        else # bad arg count
            return nil
        end #if

    end #message

end #ServerMsg
