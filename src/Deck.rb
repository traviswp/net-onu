#!/usr/local/bin/ruby

require 'Card'

class Deck

	$cards = [

			# Regular cards (color: R,G,Y,B & number: 0-9)
			"R0","R1","R1","R2","R2","R3","R3","R4","R4","R5","R5","R6","R6","R7","R7","R8","R8","R9","R9",
			"G0","G1","G1","G2","G2","G3","G3","G4","G4","G5","G5","G6","G6","G7","G7","G8","G8","G9","G9",
			"Y0","Y1","Y1","Y2","Y2","Y3","Y3","Y4","Y4","Y5","Y5","Y6","Y6","Y7","Y7","Y8","Y8","Y9","Y9",
			"B0","B1","B1","B2","B2","B3","B3","B4","B4","B5","B5","B6","B6","B7","B7","B8","B8","B9","B9",

			# Action cards (color: R,G,Y,B & action: D (draw), S (skip), R (reverse)
			"RD","RD","RS","RS","RR","RR",
			"GD","GD","GS","GS","GR","GR",
			"YD","YD","YS","YS","YR","YR",
			"BD","BD","BS","BS","BR","BR",

			# Wild cards (four regular wilds & four wild draw-fours)
			"NW","NW","NW","NW",
			"NF","NF","NF","NF",				
	]

	attr_accessor :deck, :discard_pile, :top_card

	#
	# Constructor
	#

	def initialize()
		@deck = $cards
		@discard_pile = []
		@top_card = nil
		shuffle()
	end #initialize

	#
	# Deck Accessor/Manipulation Methods
	#

	def shuffle()
		@deck.shuffle!()
	end #shuffle

	# deal 
	def deal( num )

		if (num.kind_of? Integer)

			if (num > 0 and num < 8)
				cards = []
				num.times{
					cards << @deck.pop()
				}
				return cards
			end #if

		end #if

		return nil
	end #deal

	def discard( card )
		if 
		if (card.kind_of? String)
			#puts "Discarding: " + card
			@discard_pile.unshift (card)  # prepend card
			setTopCard() 
		end #if

	end #discard

	def setTopCard()
		@top_card = @discard_pile[0]
	end #setTopCard

	#
	# Getters (unused so far - might not need these...)
	#

	def getTopCard()
		return @top_card
	end #getTopCard

	def getDeck()
		return @deck
	end #getDeck

	#
	# Testing methods
	#

	def showDeck()
		puts "The Deck: "
		@deck.each { |c|
			puts c
		}
	end #showDeck

	def showDiscard()
		puts "The Discard Pile: "
		@discard_pile.each { |c|
			puts c
		}
	end #showDiscard

end #Deck
