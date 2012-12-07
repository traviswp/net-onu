require 'Constants'
include Constants

# Defaults
port = Constants::PORT
host = Constants::HOSTNAME

# clear screen to begin...
system('clear')

#
# spawn instance of server
#

#puts "starting a server..."
#system("xterm -hold -title Server -e ruby server.rb &")
#sleep(2)

names   = ["Travis","Zeus","RonSwanson","DanTheMan","Mary","BigMike","Snookie", "ChuckNorris"]
names2  = ["Jimmy","Pat","DannyBoy99","BartSimpson","Luke","Matthew","Mark","JohnTheBaptist"]
colors  = ["black", "white"]

#host = "cf416-20.cs.wwu.edu"
#port = 36714

#
# spawn clients
#

puts "spawning #{names.size()} clients & connecting to server..."
for i in 0...names.size()
	sleep(0.5)
	name = names[i]
	bgcolor = colors[0]
	fgcolor = colors[1]#i+1 % colors.size()]
	x = 200 * i
	y = 100 * i
	system("xterm -hold -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{name} -e 'ruby client.rb -u #{name} -p #{port} -h #{host} -a' &")
end

if false then
	puts "spawning #{names2.size()} clients & connecting to server..."
	for i in 0...names2.size()
		sleep(0.5)
		name = names2[i]
		bgcolor = colors[0]
		fgcolor = colors[1]#i+1 % colors.size()]
		x = 3300 - 200 * i
		y = 100 * i
		system("xterm -hold -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{name} -e 'ruby client.rb -u #{name} -p #{port} -h #{host} -a' &")
	end
end

# wait for a key to be pressed before killing all processes
puts "press the enter key to kill spawned clients"
char = STDIN.getc
system('pkill xterm')
