#!/usr/local/bin/ruby

#
# Protocol
#
class ClientMsg

    #
    # This message is sent to the server from the client telling the server 
    # that a client is joining and is using the nickname Name.
    #    
    JOIN = "[join|#{@hostname}]"

    #
    # This message is sent to the server from the client when the client 
    # plays a card. The card value will be the card that they client is 
    # playing. If a player is unable to play, the player will send a Play 
    # command with NN as their card. This will make the server deal the 
    # player a card on the first time an NN is sent and move to the next 
    # player on the second time it is sent.
    #
    PLAY = "[play|CARD]"

end #ClientMsg
