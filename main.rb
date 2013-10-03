require './vision'
require './cave'

def color text, color
  s = "\033["
  s << color.to_s << "m" << text.to_s << "\033[0m"
  s
end


class Item
  attr_reader :x
  attr_reader :y
  attr_reader :luminescence
  def initialize x, y, world, kwargs={}
    @x = x
    @y = y
    @world = world
    @luminescence = kwargs[:luminescence] || 0
    @lum = Vision::Visibility.new world, self
    @lum.compute_visibility @x, @y
  end

  def distance_to x, y
    (@x - x).abs + (@y - y).abs
  end

  # Returns true if this Item casts light on the given square
  def lights? x, y
    @lum.visible? x, y
    # distance_to(x, y) < @luminescence
  end
end


class Entity < Item
  attr_reader :x
  attr_reader :y
  attr_reader :vis
  def initialize x, y, world, kwargs={}
    @x = x
    @y = y
    @world = world
    @luminescence = kwargs[:luminescence] || 0
    @lum = Vision::Visibility.new world, self
    @lum.compute_visibility @x, @y
    @vis = Vision::Visibility.new world
  end

  def compute_visibility
    @vis.compute_visibility @x, @y
  end

  # Returns true if this Entity casts light on the given square
  # def lights? x, y
  #   ;
  # end

  def move kwargs
    nx = @x + (kwargs[:x] || 0)
    ny = @y + (kwargs[:y] || 0)
    unless @world.cave.solid? nx, ny
      @x, @y = nx, ny
      @lum.compute_visibility @x, @y
      return true
    end
    false
  end
end


class World
  attr_reader :dude
  attr_reader :cave
  attr_reader :luminescence
  def initialize
    @cave = CaveLib::Cave.new CaveLib::STRAT3
    @items = [Item.new(*@cave.open_spot, self, luminescence: 5)]
    @dude = Entity.new *@cave.open_spot, self, luminescence: 5
    @entities = [@dude]
    recompute_visibilities
  end

  def recompute_visibilities
    @entities.each {|entity| entity.compute_visibility}
  end

  def add_item item
    @items.push item
  end

  def tick
    recompute_visibilities
  end

  def to_s
    toS = ""
    @cave.raw_map.each_with_index do |row, y|
      row.each_with_index do |elem, x|
        if @dude.x == x && @dude.y == y
          toS << color("@", 94)
        elsif @dude.vis.seen? x, y
          symb = (elem ? "#" : ".")
          if @dude.vis.visible? x, y
            if @dude.lights? x, y
              toS << symb
            else
              toS << color(symb, 93)
            end
          else
            toS << color(symb, 90)
          end
        else
          toS << color(" ", 30)
        end
      end
      toS << "\n"
    end
    toS
  end

  # Returns true if there are lights here, false otherwise.
  def lights? x, y
    @entities.any? {|entity| entity.lights? x, y} ||
    @items.any? {|item| item.lights? x, y}
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
  world.add_item Item.new(world.dude.x, world.dude.y, world, luminescence: 5) if str.chr == "l"
  world.tick
end
