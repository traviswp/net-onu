



	#
	# Next Player: returns the next
	#
	#def next_player(player)
	#	list_len = players().size()
	#	# TODO: still need to make it to where @step accounts for "skips"
	#	index = (position(player) + (@step * @direction)) % list_len
	#	return [](index)
	#end 

	#
	# Give Card: gives player n cards
	#
	def give_card(player, n)
		if has_player?(player) then
			players()[postition(player)].cards << @deck.deal(n)
		end
	end

	def waiting()
		#return @waiting.compact()
		return @waiting_list.getPlayers()
	end

	def min?()
		return (players.size() >= 2)
	end

	def add_player(player)
		if (players.size() < @max_players) then
			#@players_list[position(nil)] = player unless @players_list.include? player
			players << player unless players.include? player
			return true
		elsif (waiting.size() < @lobby) then
			#@waiting[position(nil)] = player unless @waiting.include? player
			@waiting << player unless @waiting.include? player
			return true
		else
			return false
		end
	end

	def remove_player(player)
		players[position(player)] = nil
	end

	def [](index)
		return players[index]
	end

	def position(player)
		return players.index(player)
	end

	def has_player?(player)
		return players.include? player
	end

