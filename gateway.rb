$LOAD_PATH.unshift File.dirname(__FILE__)        
require 'socket'

class Blind
  attr_accessor :id, :name, :height
  
  def initialize raw_data
    @id = raw_data[1][5,5]
    @name = raw_data[0][14..-1]
    @height = raw_data[1][11,3]
  end
end
class Gateway
  attr_accessor :socket, :blinds
  
  def initialize(host, port)
    @host = host
    @port = port
    @blinds = []
    self.socket = TCPSocket.new host, port
    puts self.socket.recv(1024)
    self.get_list
  end
  
  def get_list
    self.socket.write "$dat"
    list = self.socket.recv(1024).split("\r")
    rooms = list[8,3]
    list[11..-2].each_slice(2) do |raw_data|
        self.blinds.push Blind.new(raw_data)
      end
  end
  
  def print_list
    self.blinds.each_with_index do |blind, i|
      puts "#{i}.\t#{blind.name}"
    end
  end

  #0-255 0 is closed, 255 is open
  def set_blind blind, height
    height = height.to_s.rjust 3, '0'
    socket.write "$pss#{blind.id}-#{height}"
    socket.write "$rls"
  end
end

hd = Gateway.new "192.168.7.10", 522

if ARGV.length == 1
  hd.set_blind hd.blinds[0], ARGV[0]
else
  while true do 
    hd.print_list
    
    puts 'Which blind?'
    blind = hd.blinds[gets.strip.to_i]
    puts 'How closed? (0 is closed, 255 is open)'
    height = gets.strip.to_i
    
    hd.set_blind blind, height
  end
end
