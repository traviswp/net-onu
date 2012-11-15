#!/usr/local/bin/ruby

class Card

	#
	# A prefix consists of a color (or 'N' for "no color") 
	# Notice:
	#     - only the server can "issue" a non-colored card (e.g. prefix "N"). 
	#       the player must specify a color when playing and of the cards that
	#       can be represented by the valid suffixes (listed below). 
	#
	
	$valid_prefix = ["R", "G", "B", "Y"] #, "N"]

	#
	# A suffix consists of a valid number, action, or identifier
	#	- valid numbers   : 0-9
	#	- valid actions   : D (draw two), S (skip), R (reverse)
	#	- valid identifier: W (wild), F (wild draw four)
	#
	
	$valid_suffix = ["D", "S", "R", "W", "F", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] 

	attr_accessor :prefix, :suffix

	#
	# Constructor
	#

	def initialize()#(prefix,suffix)
		self.prefix# = prefix 
		self.suffix# = suffix
	end #initialize

	#
	# Validation method for determining a play is valid.
	# Server will call this method to verify that the card 
	# being played is valid. 
	#

	# TODO: currently you pass in a string - if we want to utilize this
	#       class, we should pass in a card object...
	def isValid( card )

		# check input 'card' - verify it is a string
		if !(card.kind_of? String)
			#puts "not a string"
			return false
		end #if

		# check input 'card' length
		len = card.length()
		if len < 1 || len > 2
			#puts "not the right size"
			return false
		end #if
 
		# inspect the 'card' - verify prefix & suffix
		card = card.upcase
		#puts card
		prefix = card[0].chr
		suffix = card[1].chr

		return ($valid_prefix.include?(prefix) and $valid_suffix.include?(suffix))

	end #isValid

end #Card
