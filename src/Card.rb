#!/usr/local/bin/ruby

class Card

	# A prefix consists of a color (or 'N' for "no color")
	$valid_prefix = ["r", "g", "b", "y", "n"]

	# A suffix consists of a valid number, action, or identifier
	#	- valid numbers   : 0-9
	#	- valid actions   : D (draw two), S (skip), R (reverse)
	#	- valid identifier: W (wild), F (wild draw four)
	$valid_suffix = ["d", "s", "r", "w", "f", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] 

	attr_accessor :prefix, :suffix

	#
	# Constructor
	#

	def initialize()
		prefix 
		suffix
	end #initialize

	#
	# 
	#

	def isValid( card )

		# check input 'card' - verify it is a string
		if !(card.kind_of? String)
			puts "not a string"
			return false
		end #if

		# check input 'card' length
		len = card.length()
		if len < 1 || len > 2
			puts "not the right size"
			return false
		end #if
 
		# inspect the 'card' - verify prefix & suffix
		card = card.downcase
		prefix = card[0].chr
		suffix = card[1].chr

		return ($valid_prefix.include?(prefix) and $valid_suffix.include?(suffix))

	end #isValid

end #Card
