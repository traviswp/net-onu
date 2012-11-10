#!/usr/bin/ruby

require 'tk'

# Supports multiple image formats
require 'tkextlib/tkimg'

root = TkRoot.new() { title "Uno - Main Menu" }


def setup (root)

	# Text entry
	#entry = TkEntry.new(root).pack("side"=>"top", "fill"=>"x")
	#entry.insert(0, "Entry on the top")

	# Simple label
	#label = TkLabel.new(root) { text "to the right" }
	#label.pack("side"=>"right")

	# Images - backgroud
	#image = TkPhotoImage.new('file'=>"images/uno.jpg")
	#img_label = TkLabel.new(root) { image image }.pack("anchor"=>"e")

	# Button
	#button = TkButton.new(root) { text "First, rightmost" }
	#button.pack()

	# Text box which can be written in -- good for 'chat''
	#text = TkText.new(root) { width 20; height 5 }.pack("side"=>"left")
	#text.insert('end', "Left in canvas")

	# Multi-line label
	#TkMessage.new(root) { text "Message in the Bottom" }.pack("side"=>"bottom")


	startButton = TkButton.new(root) { 
		text "Play!"

		# play screen
		command proc {
			p "Time To Play!"
		}	
	}
	startButton.pack()

	rulesButton = TkButton.new(root) { 
		text "Rules"

		# rules screen
		command proc {
			p "Show rules"
		}	
	}
	rulesButton.pack()

	exitButton = TkButton.new(root) { 
		text "Exit"

		# play screen
		command proc {		
			p "Exit"
			exit
		}
	}
	exitButton.pack()

	#
	# Bind a few special keys ...
	#

	# Allow the ESC key to close the application gracefully	
	root.bind("Escape") {
		p "Exit"	
		exit
	}

	# Allow the ENTER key to be another way of saying "Play!"
	#root.bind("Enter???") {
	#	
	#}

	#
	# Change image as you hover over it
	#	
	#image1 = TkPhotoImage.new { file "img1.gif" }
	#image2 = TkPhotoImage.new { file "img2.gif" }

	#b = TkButton.new(@root) {
	#  image    image1
	#  command  proc { doit }
	#}

	#b.bind("Enter") { b.configure('image'=>image2) }
	#b.bind("Leave") { b.configure('image'=>image1) }

end

def top_menu(root)

	menu_spec = [
	  [ ['File', 0],
		['New File',  proc{new_file}],
		['Open File', proc{open_file}],
		'---',
		['Save File', proc{save_file}],
		['Save As',   proc{save_as}],
		'---',
		['Quit',      proc{exit}]
	  ],
	  [ ['Edit', 0],
		['Cut',       proc{cut_text}],
		['Copy',      proc{copy_text}],
		['Paste',     proc{paste_text}]
	  ]
	]

	TkMenubar.new(nil, menu_spec, 'tearoff'=>false).pack('fill'=>'x', 'side'=>'top')

end

def test(root)
	require 'tk'


	def busy
	  begin
		$root.cursor "watch" # Set a watch cursor
		$root.update # Make sure it updates  the screen
		yield # Call the associated block
	  ensure
		$root.cursor "" # Back to original
		$root.update
	  end
	end


	$root = TkRoot.new {title 'Scroll List'}
	frame = TkFrame.new($root)


	list_w = TkListbox.new(frame, 'selectmode' => 'single')


	scroll_bar = TkScrollbar.new(frame,
		              'command' => proc { |*args| list_w.yview *args })


	scroll_bar.pack('side' => 'left', 'fill' => 'y')


	list_w.yscrollcommand(proc { |first,last|
		                         scroll_bar.set(first,last) })
	list_w.pack('side'=>'left')


	image_w = TkPhotoImage.new
	TkLabel.new(frame, 'image' => image_w).pack('side'=>'left')
	frame.pack


#	dir = Dir.open "../images/"
	list_contents = Dir["../images/*.*"]
#	list_contents = dir.entries
	list_contents.each {|x|
	  list_w.insert('end',x) # Insert each file name into the list
	}

	list_w.bind("ButtonRelease-1") {
	  index = list_w.curselection[0]
	  busy {
		tmp_img = TkPhotoImage.new('file'=> list_contents[index])
		scale   = tmp_img.height / 100
		scale   = 1 if scale < 1
		image_w.copy(tmp_img, 'subsample' => [scale,scale])
		tmp_img = nil # Be sure to remove it, the
		GC.start      # image may have been large
	  }
	}

	Tk.mainloop
end


# Main
setup (root)
#top_menu(root)
test(root)

# Main loop
#Tk.mainloop()







