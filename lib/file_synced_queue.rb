#!/usr/bin/env ruby
#coding: utf-8
$KCODE ='u' if RUBY_VERSION.to_f < 1.9

require 'thread'
class FileSyncedQueue
  def initialize(path,max_limit=1000)
    @save_path = path
    unless File.exists? path and File.file? path then
      raise "ファイルじゃない。"  if File.exists? path and not File.file? path
    end
    @m = Mutex.new
    at_exit{
      self.save
    }
    @q =self.load                  if     File.exists? path
    @q = SizedQueue.new(max_limit) unless File.exists? path
    self.save 
  end
  def load
    @q = Marshal.load open(@save_path).read
  end
  def save
    f = open(@save_path,"w")
    Marshal.dump(@q,f)
    f.flush
    f.close
  end
  def push(val)
    @q.push val
    @m.synchronize{
      self.save    
    }
  end
  def pop()
    val = @q.pop
    @m.synchronize{
      self.save    
    }
    val
  end
  #
  alias enq push
  alias <<  push
  #
  alias shift pop
  alias deq   pop
end

if __FILE__ == $0 then
require "tempfile"
q = FileSyncedQueue.new( Tempfile.open("dump"))
t = Thread.new{
   loop{
      while a = q.pop 
        puts a
      sleep 10
      end
    }
}
s = Thread.new{
  loop{ 
    puts "push " + (1..(rand(10))).map{|e|  q.push e; e}.map.join(",")
    sleep 1
  }
}

s.join

end
