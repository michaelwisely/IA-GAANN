# Deployment Script to delete current contents of IA-GAANN directory and replace with _Site
# NOTE: Make sure you have net-sftp installed.  If not, run "gem install net-sftp"
require 'io/console'
require 'net/sftp'

puts "============ IA-GAANN SFTP Deployment Script ============"

# Connection information
host = "minersftp.mst.edu"
local_directory = "_site/"
remote_directory = "/USERWEB/ia-gaann"

# Get connection credentials
print "Username: "
username = gets.chomp
print "Please enter your password: "
password = gets.chomp
# The code below will hide the password but it requires three return presses to move past - wierd.
# password = STDIN.raw(&:gets).chomp
# gets

# Simple method to print with an indention level specified
def level_print(message, count)

  if count > 0
    indention = ""
    indention += "  " until indention.length() == 2*count
    print indention
  end
    
  puts message
end

# Recursively delete files in a directory and then remove directory
# NOTE: Directories have to be empty in order to delete them apparently
# NOTE: Due to some permission issues that were experienced with using lstat method to identify file type, 
#       this relies on StatusException to identify the file type.  I.e., because sftp.remove expects a 
#       file, directories throw the error.  Making this assumption works for now, just be warned.
def delete_directory_contents(directory, sftp, level)
  level_print("Deleting: " + directory, level)
  sftp.dir.entries(directory).each do |file|
    begin
      sftp.remove!(directory + "/" + file.name)
      level_print("Deleted File: " + file.name, level + 1)
    rescue Net::SFTP::StatusException => e
      delete_directory_contents(directory + "/" + file.name, sftp, level + 1)
      sftp.rmdir(directory + "/" + file.name)
      level_print("Deleted Directory: " + file.name, level + 1)
      # puts "Error: " + e.description
    end
  end
end

print "Initializing connection to: " + host + " ... "
Net::SFTP.start(host, username, :password => password) do |sftp|
  puts "Connected!"
  
  # Delete existing files
  delete_directory_contents(remote_directory, sftp, 0)
  
  # Copy _Site contents to remote server
  print "Uploading " + local_directory + " to " + remote_directory + " ... "
  sftp.upload!(local_directory, remote_directory)
  puts "Complete!"
end
