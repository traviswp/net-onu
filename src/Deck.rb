#!/usr/bin/env ruby

require 'Card'

class Deck

	CARDS = [

			# Regular cards (color: R,G,Y,B & number: 0-9)
			"R0","R1","R1","R2","R2","R3","R3","R4","R4","R5","R5","R6","R6","R7","R7","R8","R8","R9","R9",
			"G0","G1","G1","G2","G2","G3","G3","G4","G4","G5","G5","G6","G6","G7","G7","G8","G8","G9","G9",
			"Y0","Y1","Y1","Y2","Y2","Y3","Y3","Y4","Y4","Y5","Y5","Y6","Y6","Y7","Y7","Y8","Y8","Y9","Y9",
			"B0","B1","B1","B2","B2","B3","B3","B4","B4","B5","B5","B6","B6","B7","B7","B8","B8","B9","B9",

			# Action cards (color: R,G,Y,B & action: D (draw two), S (skip), U (reverse)
			"RD","RD","RS","RS","RU","RU",
			"GD","GD","GS","GS","GU","GU",
			"YD","YD","YS","YS","YU","YU",
			"BD","BD","BS","BS","BU","BU",

			# Wild cards (four regular wilds & four wild draw-fours)
			"NW","NW","NW","NW",
			"NF","NF","NF","NF",				
	]

	attr_accessor :cards, :discard_pile, :top_card

	#
	# Constructor
	#

	def initialize()

		# playing deck
		@cards = []
		CARDS.each { |c|
			prefix = c[0].chr
			suffix = c[1].chr
			@cards << Card.new(prefix,suffix)
		}

		# discard pile
		@discard_pile = []

		@top_card = nil

		shuffle()

	end #initialize

	#
	# Deck Accessor/Manipulation Methods
	#

	def shuffle()
		#@cards.shuffle!() # not supported in 1.8.6?
		@cards = @cards.sort_by{ rand }
		@discard_pile.unshift(@cards.pop())
		setTopCard()
		badTop!()
	end #shuffle

	def replenish!(n)

		if (size() <= n) then

			# store remaining cards on the playing deck
			tmp = @cards

			# store the top card of the discard pile
			top = @top_card
			@discard_pile.delete(@top_card)
			puts "top card is #{top}"

			# revert any colored wilds/wild-draw-fours back to non-colored cards
			@discard_pile.each{ |c|
				
				# replace: wild
				if c.getIdentifier == "W" then
					@discard_pile.delete(c)
					@discard_pile << Card.new("N","W")
				end

				# replace: wild-draw-four
				if c.getIdentifier == "F" then
					@discard_pile.delete(c)
					@discard_pile << Card.new("N","F")
				end
			}

			# reset the playing deck
			@cards = @discard_pile + tmp

			# reset the discard pile
			@discard_pile = []

			# reshuffle the playing deck
			shuffle()

			# reset the top card from before the replenish
			@discard_pile.unshift(top)
			setTopCard() 

		end

	end #replenish

	# deal 
	def deal(num)

		if (num.kind_of? Integer)

			# check: if the # of cards to be dealt is > # of cards in deck, 
			# replenish the deck. (if this isn't the case, replenish! is a no-op 
			replenish!(num)

			if (num > 0 and num < 8)
				cards = []
				num.times{
					cards << @cards.delete_at(0)
				}
				return cards
			end #if
		end #if

		return nil

	end #deal

	def discard(card)
		#if((card.kind_of? Card) && (card != nil))
		if card != nil then
			@discard_pile.unshift(card)  # prepend card
			setTopCard() 
			return
		end #if
		return "no put pack"
	end #discard

	def put_back(cards)
		if (cards != nil) then 
			cards.each { |card|
				@discard_pile << card
			}
		end
	end

	def setTopCard()
		return @top_card = @discard_pile[0]
	end #setTopCard

	def	badTop!()
		while ((@top_card.to_s == "NF") || (@top_card.to_s == "NW")) do
			@discard_pile.unshift(@cards.pop())
			setTopCard()
		end
		return
	end

	def empty?()
		return @cards.empty?()
	end

	def size()
		return @cards.size()
	end

	def to_s()
		result = ""
		@cards.each{ |card|
			result << card.to_s + ","
		}
		result[-1] = "\n"
		return result
	end 

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
		l = "The Deck: "
		@cards.each { |c|
			l = l + "#{c},"
		}
		l[-1] = ""
		l = l + " -- [#{@cards.size()}]\n"
		#puts l + " -- [#{@cards.size()}]"

		l += "The Discard Pile: "
		@discard_pile.each { |c|
			l = l + "#{c},"
		}
		l[-1] = ""
		l = l + " -- [#{@discard_pile.size()}]"
		#puts l + " -- [#{@discard_pile.size()}]"

		return l
		
	end #showDeck

end #Deck
