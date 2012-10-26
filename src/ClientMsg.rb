#!/usr/local/bin/ruby

#
# Protocol
#
module ClientMsg

    #
    # Legal client commands
    #
    # Hash: {"command" => "arg_count"}
    #
    @commands = ["join", "play", "chat"]
    @valid_client_commands = {@commands[0] => 1,   # join
                              @commands[1] => 1,   # play
                              @commands[2] => 2}   # chat
                              
    @keys                  = @valid_client_commands.keys()
    @default               = "unknown command"

    #
    # formatMessage(list)
    #
    # Input : An array of strings, concatentates them together and separates
    #         them by the pipe ("|") character. 
    #
    # Output: Returns a single string that is pipe delimited
    # 
    def ClientMsg.formatMessage(list, argc)
        
        p_list = ""
        if argc == 1 then                          # arg is the only string in list
            p_list = list[0]
            return p_list 
        else
            for i in 0...argc-1                    # process the list by looping through
                p_list = p_list + list[i] + "|"    # concatenating the strings and
            end                                    # separating them with the pipe character
            p_list = p_list + list[argc-1]
            return p_list
        end #if
    
    end #formatMessage

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
        cmd = @keys.find { |c| c == command }
        if (cmd != nil) then
            val = @valid_client_commands[cmd]
        end #if
        argc = info.size()

        if (val == argc) then

            # format the arguments to the message before returning the string
            # that is to be sent to the server.  
            args = formatMessage(info, argc)
    
            ####################################################################
            #                                                                  #
            #                          Client Messages                         #
            #                                                                  #
            ####################################################################
    
            #
            # This message is sent to the server from the client telling the server 
            # that a client is joining and is using the nickname Name.
            #    
            # JOIN = "[join|USERNAME]"
            #    
            join = "[join|#{args}]"
    
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
            play = "[play|#{args}]"
    
            #
            # This message is sent to the server from the client with a message that 
            # the client wants to say to the other clients. This message will be 
            # broadcasted by the server with the sender name at the beginning of 
            # the message.
            #    
            #chat      = "[chat|SENDERNAME|MESSAGE]"
            #
            chat      = "[chat|~#{args}~]"
            
            ####################################################################
            #                                                                  #
            #                          Construct Message                       #
            #                                                                  #
            ####################################################################
    
            msg = ""
    
            # Return the message w/ valid command & the specified arguments
            case cmd
    
            when @commands[0]         # join message 
                msg = join
            when @commands[1]         # play message
                msg = play
            when @commands[2]         # chat message
                msg = chat
            end #case
    
            return msg + "\n"

        else # bad arg count
            return nil
        end #if

    end #message


end #ClientMsg
