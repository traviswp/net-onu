require 'fileutils'

system('clear')

################################################################################
# inform user of the running script
puts "executing #{__FILE__}..."

# change to log directory
log_path = File.expand_path("../logs/")
Dir.chdir(log_path)

# display dir contents
puts "\nThe following log files will be deleted:"
puts

swp_flag = false
log_flag = false

dir_contents = Dir.entries(".")
dir_contents.each{ |file|

    if file[-1].chr == "~" then
        puts "swp log file: #{file}"
        swp_flag = true
    elsif file != "." && file != ".." && file[-7 .. -1] == "log.txt" then
        puts "log file: #{file}"
        log_flag = true
    end
}
# check that there were files to delete
if !swp_flag && !log_flag then

    puts "no files to delete"
    
else

    # prompt user for verification
    print "\nAre you sure you want to delete these log files? (y/n): "

    response = STDIN.getc
    if response.chr == "y"
        if swp_flag then
            system('rm *~')
        end
        if log_flag then
            system('rm *log.txt')
        end
    end

end
################################################################################

