#!/usr/local/bin/ruby

#
# Protocol
#
module ClientMsg

    @valid_server_commands = ["accept", "chat", "deal", "gg", "go", "invalid", "played", "players", "startgame", "tts", "wait"]

    @valid_client_commands = ["join", "play"]

    @default = "I'm sorry, I don't know what to do with that."

    def message(command, info)

        args = info

        ############################################################################
        #                                                                          #
        #                            Server Messages                               #
        #                                                                          #
        ############################################################################

        #
        # This message is sent to the server from the client telling the server 
        # that a client is joining and is using the nickname Name.
        #    
        # JOIN = "[join|USERNAME]\n"
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
        # PLAY = "[play|CARD]\n"
        #
        play = "[play|#{args}]\n"


        ############################################################################

        cmd = @valid_client_commands.find { |c| c == command }
        msg = ""



        # Return the message w/ valid command & the specified arguments
        case cmd

        when @valid_client_commands[0]
            msg = join + "\n"
        when @valid_client_commands[1]
            msg = play + "\n"
        else
            msg = INVALID + @default + "\n"
        end #case

        return msg
    end #message


end #ClientMsg
