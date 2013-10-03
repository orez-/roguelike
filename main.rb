require './vision'
require './cave'

def color text, color
  s = "\033["
  s << color.to_s << "m" << text.to_s << "\033[0m"
  s
end

class Entity
  attr_reader :x
  attr_reader :y
  attr_reader :vis
  def initialize x, y, cave
    @x = x
    @y = y
    @cave = cave
    @vis = Vision::Visibility.new cave
    @vis.compute_visibility @x, @y
  end

  def move kwargs
    nx = @x + (kwargs[:x] || 0)
    ny = @y + (kwargs[:y] || 0)
    unless @cave.solid? nx, ny
      @x, @y = nx, ny
      @vis.compute_visibility @x, @y
      return true
    end
    false
  end
end


class World
  attr_reader :dude
  def initialize
    @cave = CaveLib::Cave.new CaveLib::STRAT3
    @dude = Entity.new *@cave.open_spot, @cave
  end

  def to_s
    toS = ""
    @cave.raw_map.each_with_index do |row, y|
      row.each_with_index do |elem, x|
        if @dude.x == x && @dude.y == y
          toS << color("@", 94)
        elsif @dude.vis.seen? x, y
          symb = (elem ? "#" : ".")
          toS << ((@dude.vis.visible? x, y) ? symb : color(symb, 90))
        else
          toS << color(" ", 30)
        end
      end
      toS << "\n"
    end
    toS
  end
end


world = World.new
str = ""

while str.chr != "\u0003"
  puts world.to_s
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  world.dude.move(y: -1) if str.chr == "w"
  world.dude.move(x: -1) if str.chr == "a"
  world.dude.move(y: 1) if str.chr == "s"
  world.dude.move(x: 1) if str.chr == "d"
  world.dude.vis.seen_all if str.chr == "o"
end
