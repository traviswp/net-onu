#!/usr/local/bin/ruby

class Card

	#
	# A prefix consists of a color (or 'N' for "no color") 
	# Notice:
	#     - only the server can "issue" a non-colored card (e.g. prefix "N"). 
	#       the player must specify a color when playing and of the cards that
	#       can be represented by the valid suffixes (listed below). 
	#
	
	PREFIX = ["R", "G", "B", "Y"] #, "N"]

	#
	# A suffix consists of a valid number, action, or identifier
	#	- valid numbers   : 0-9
	#	- valid actions   : D (draw two), S (skip), U (reverse)
	#	- valid identifier: W (wild), F (wild draw four)
	#
	
	SUFFIX = ["D", "S", "U", "W", "F", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] 

	attr_accessor :prefix, :suffix

	#
	# Constructor
	#

	def initialize(prefix=nil,suffix=nil)
		@prefix = prefix
		@suffix = suffix
	end #initialize

	#
	# Get Color: get the prefix of the card
	#
	def getColor()
		return @prefix
	end

	#
	# Get Identifier: get the suffix of the card
	#
	def getIdentifier()
		return @suffix
	end

	#
	# Validation method for determining a play is valid.
	# Server will call this method to verify that the card 
	# being played is valid. 
	#
	def valid_str?(card)

		if (card == nil) then
			return false
		end

		# check input 'card' - verify it is a string
		if !(card.kind_of? String)
			return false
		end #if

		# check input 'card' length
		len = card.length()
		if len < 1 || len > 2
			return false
		end #if
 
		# inspect the 'card' - verify prefix & suffix
		card = card.upcase
		if ((card[0] != nil) && (card[1] != nil)) then
			prefix = card[0].chr
			suffix = card[1].chr
		else 
			return false
		end

		# NN = no play, which is a valid card sequence
		if (card == "NN") then
			return true
		end

		return (check_prefix(prefix) and check_suffix(suffix))

	end #valid?

	def valid_card?(card)

		# check card type
		if !(card.kind_of? Card)
			return false
		end

		# NN = no play, which is a valid card sequence
		if ((card.prefix == "N") && (card.suffix == "N")) then
			return true
		end

		return ((check_prefix(card.prefix)) && (check_suffix(card.suffix)))
 
	end #valid_card?

	def to_s()
		return "#{@prefix}#{@suffix}"
	end #to_s

	def eql?(card)
		return @prefix == card.prefix && @suffix = card.suffix
	end #eql?

	def check_prefix(prefix)
		return (PREFIX.include? prefix)
	end #check_prefix

	def check_suffix(suffix)
		return (SUFFIX.include? suffix)
	end #check_suffix

end #Card
