#!/usr/local/bin/ruby

module ServerStates

	#
	# Server States
	#

	def lobby()

		# service: connections

			# send: [ACCEPT|...] or [WAIT|...]

			# send: [PLAYERS|...]

			# parse msg & determine action

		# service: chat

		# (service: timer)

		# service: game states

	end

	def startGame()
		# send [STARTGAME|...] (report all active players for game play)

		# call deal()

		# send [GO|CV] to first player
	end 

	def play()

		#loop

			# send [GO|CV]

			# (new state: waitForAction)
			

	end

	def deal()
		# send [DEAL|...] (initial deal: everyone gets 7 cards)
	end

	def waitForAction()

		# simply wait for current player to discard

			# if discard: (new state: discard)

			# if timeout:
			#    - drop/skip player? (new state: postDiscard)

	end

	def discard(card)

		attempt = 0

		# check if the play is valid
		# 	1. does player have that card
		# 	2. is card valid/playable?
		#
		# call: cardValidation(card)

		# determine card type & appropriate action to take:

			# valid number card

			# skip

			# reverse

			# draw 2

				# wild

			# draw 4

				# wild

			# wild

			# can't play (draw 1 card - if still can't play, skip player)

				# if attempt == 0 then 
				#     draw(1)
				#     attempt = 1
				# else 
				#     

		# if valid play: (new state: afterDiscard())

	end

	def afterDiscard()

		# send [PLAYED|playername,CV]

		# check: [UNO|playername]

		# 
		# check: endGame (new state: endGame)
		# or
		# (new state: play)
		#

	end

	def endGame()
		# send [GG|winning_player_name]
	end

	#######################################################################

	#
	# Server State Helper Methods
	#

	def draw(n)
		# send [DEAL|cards(1..n)] 
	end

	def cardValidation(card)
		# send [INVALID|message]
	end

	def getCurrentPlayerHand()

	end

end #ServerStates
