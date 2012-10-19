#!/usr/local/bin/ruby

#
# Protocol
#
class ServerMsg

    ############################################################################
    #                                                                          #
    #                          Broadcasted Messages                            #
    #                                                                          #
    ############################################################################

    #
    # This message is sent to all of the currently connected clients from the 
    # server listing all of the players that are connected and waiting to play. 
    # In the event a client disconnects, another Players command will be sent 
    # out to show the new player list.
    #
    PLAYERS   = "[players|NAME1,NAME2,...]"

    #
    # This message is sent to all of the currently connected clients from the 
    # server telling all of the clients that the game has started. This message 
    # also lists all of the players in the game.
    #
    START     = "[startgame|NAME1,NAME2,...]"

    #
    # This message is sent to the clients from the server telling all of the 
    # players who just played a card and what card they played.
    #
    PLAYED    = "[played|PLAYERNAME|CARD]"

    #
    # This message is sent to all of the clients from the server when a player 
    # played their last card and won the game. The name sent is the name of 
    # the winner. After this is sent, the server will go back into a lobby state.
    #
    GAMEOVER  = "[gg|NAME]"

    ############################################################################
    #                                                                          #
    #                         Client Specific Messages                         #
    #                                                                          #
    ############################################################################

    #
    # This message is sent to a client from the server telling the client 
    # that they have been accepted into the game. The name coming back from 
    # the server may be different if the name the client sent with the join 
    # command was already taken. If this happens, a number will be appended 
    # to the end of the client's nickname.
    #
    ACCEPT    = "[accept|RETURN_NAME]"

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
    #a wild draw 4 card is NF, etc.
    # 
    DEAL      = "[deal|CARD1,CARD2,...]"

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
    PLAY      = "[go|TOPCARD]"

    #
    # This message is sent to the client that just tried to play an invalid 
    # play. This can happen if the card can't be played in the given 
    # circumstances, for instance the player tried to play a green 7 on a 
    # yellow 5, or if the player tried to play a card that the player didn't 
    # have. The message field will tell the player why their play was an 
    # invalid play.
    #
    INVALID   = "[invalid|MESSAGE]"

    #
    # This message is sent to the server from the client with a message that 
    # the client wants to say to the other clients. This message will be 
    # broadcasted by the server with the sender name at the beginning of 
    # the message.
    #    
    CHAT      = "[chat|SENDERNAME|MESSAGE]"

    #
    # This message is sent to the client from the server when the client tried 
    # to join after the game has started. The name field is their name and the 
    # same rules apply here as they do in the Accept command.    
    #
    WAIT      = "[wait|RETURN_NAME]"

    #
    # This message is sent to a client when they join the server while it is 
    # in the lobby state. This will tell the player how much longer until the  
    # game begins.
    #
    TTS       = "[tts|TIME_BEFORE_GAME_STARTS]"

end #ServerMsg
