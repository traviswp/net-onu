#!/usr/bin/ruby


def loops

	# regular for loop in Ruby
	# ... dots - exclusive
	# .. dots  - inclusive
	for ss in 1...10
		print ss, " Hello\n";
	end

end

def branches (p)	

	if p < 0
		puts "less than 0: " + p.to_s
	elsif p == 0
		puts "equals 0: " + p.to_s
	else
		puts "greater than 0: " + p.to_s
	end

end

def iterate

	# Some useful array methods:	
	#
	# array_name.
	#			 push (args)     - append to end
	#			 pop             - get last element
	#			 shift           - get first element
	#    		 unshif (args)   - prepend to beginning
	#
	presidents = ["Ford", "Carter", "Reagan", "Bush1", "Clinton", "Bush2"]

	#
	# Loops
	#

	# Forward interation
	for ss in 0...presidents.length
		print ss, ": ", presidents[ss], "\n"; 
	end

	# Backward iteration
	for ss in 0...presidents.length
		print ss, ": ", presidents[-ss -1], "\n";
	end

	p=5
	while p > 0
		puts p	
		p-=1
	end

	#
	# Iterators
	#

	# You can use commans (,) or pluses (+) for string concatentation
	presidents.each {|prez| print "--> " + prez + "\n"}

	# Also, rather than using {} you can use do ... end
	presidents.each do
		|prez|
		print "<"
		print prez
		print ">\n"	
	end

end


# Main
loops

branches(5)
branches(-1)
branches(0)

iterate
