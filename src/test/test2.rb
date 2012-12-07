#
# read:
#
# Input: none
# Output: portion of text from @buffer that was processed (if any)
#
def read()

	# read: input on clientSocket
	data = @clientSocket.recv(1024)

	# check: dropped/closed connection
	if data == "" then
		dropped_connection()
		return nil
	end

	# update: @buffer
	@buffer = @buffer + data

	# validate: @buffer
	result = validate()
	
	# check: complete message from server?
	if result != nil then
		command = result[0]
		arguments = result[1]
		process(command, arguments)
	end

	return true		

end #read

#
# validate:
#
# Input: none
# Output: return array containing: (1) command, and (2) arguments
#
def validate()

	######################################
	# validating contents of the @buffer #
	######################################

	# match:
	#    command   (letters only; 2-9 characters)
	#    arguments (anything up to the first ']' character)
	re = /\[([a-zA-Z]{2,9})\|(.*?)\]/i
	m = @buffer.match re

	# upon matching: (1) set command, (2) set command info, and (3) remove
	#  this portion of the message from @buffer
	if m != nil then
		command = m[1].upcase()
		info    = m[2]
		@buffer.sub!(/\[([a-zA-Z]{2,9})\|(.*?)\]/i, "")
	else
		puts "received #{msg}" #DEBUG
		return nil
	end

	# validate: command
	if (command == "ACCEPT") then
		pass = true
	elsif (command == "CHAT") then
		pass = true
	elsif (command == "DEAL") then
		pass = true
	elsif (command == "GG") then
		pass = true
	elsif (command == "GO") then
		pass = true
	elsif (command == "INVALID") then
		pass = true
	elsif (command == "PLAYED") then
		pass = true
	elsif (command == "PLAYERS") then
		pass = true
	elsif (command == "STARTGAME") then
		pass = true
	elsif (command == "UNO") then
		pass = true
	elsif (command == "WAIT") then
		pass = true
	else
		# command not recognized
		return nil
	end

	#validate: info following command
	if (info.size() < 1 || info.size() > 128) then
		err ("message error: message with command '#{command}' and content '#{info}' violates message length constraints") #DEBUG
		return nil
	end	

	return [command,info]

end

#
# process:
#
# Input: a legal UNO command & its arguments (validated in method 'validate')
# Output: none - makes appropriate call to handler method
#
def process(command, args)

	# check: nil/empty entries are illegal
	if (command = nil || command == "" || args == nil || args == "")
		raise "illegal call to 'process()': command & arguments are nil"

	#
	# call appropriate handler method based on command:
	#

	if (command == "ACCEPT") then
		handle_accept(args)
	elsif (command == "CHAT") then
		handle_chat(args)
	elsif (command == "DEAL") then
		handle_deal(args)
	elsif (command == "GG") then
		handle_gg(args)
	elsif (command == "GO") then
		handle_go(args)
	elsif (command == "INVALID") then
		handle_invalid(args)
	elsif (command == "PLAYED") then
		handle_played(args)
	elsif (command == "PLAYERS") then
		handle_players(args)
	elsif (command == "STARTGAME") then
		handle_startgame(args)
	elsif (command == "UNO") then
		handle_uno(args)
	elsif (command == "WAIT") then
		handle_wait(args)
	else
		# error - shouldn't get invalid messages from the server
		err(message)
	end

end















