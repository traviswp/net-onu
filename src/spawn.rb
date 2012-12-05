
system('clear')

# setup workspace
#puts "setting up workspace..."
#system("gedit *.rb &")

# start server
#puts "starting a server..."
#system("xterm -hold -title Server -e ruby server.rb &")
#sleep(2)

# start clients
names  = ["Travis","Zeus","RonSwanson","DanTheMan","Mary","BigMike","Snookie", "ChuckNorris"]
colors = ["black", "white"]

puts "spawning #{names.size()} clients & connecting to server..."
for i in 0...names.size()
	name = names[i]
	bgcolor = colors[0]
	fgcolor = colors[1]#i+1 % colors.size()]
	x = 200 * i
	y = 100 * i
	system("xterm -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{name} -e ruby client.rb -u #{name} -a &")
	sleep(0.5)
end

names2  = ["Jimmy","Pat","DannyBoy99","BartSimpson","Luke","Matthew","Mark","JohnTheBaptist"]

puts "spawning #{names.size()} clients & connecting to server..."
sleep(1)
for i in 0...names2.size()
	name = names2[i]
	bgcolor = colors[0]
	fgcolor = colors[1]#i+1 % colors.size()]
	x = 3300 - 200 * i
	y = 100 * i
	system("xterm -geometry 80x25-#{x}-#{y} -bg #{bgcolor} -fg #{fgcolor} -title #{name} -e ruby client.rb -u #{name} -a &")
	sleep(0.5)
end

