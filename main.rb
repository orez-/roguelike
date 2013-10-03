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
  attr_reader :symb
  attr_reader :luminescence
  def initialize x, y, world, kwargs={}
    @world = world
    @symb = kwargs[:symb] || '?'
    @luminescence = kwargs[:luminescence] || 0
    @lum = Optics::Light.new world, self
    move_to x, y
  end

  def distance_to x, y=nil
    x, y = x.x, x.y if y.nil?
    (@x - x).abs + (@y - y).abs
  end

  def move_to x, y
    @x = x
    @y = y
    @lum.compute_visibility @x, @y, @luminescence
  end

  # Returns true if this Item casts light on the given square
  def lights? x, y
    @lum.visible? x, y
  end
end


class Entity < Item
  attr_reader :vis
  attr_reader :nightvision
  attr_reader :equipment
  def initialize x, y, world, kwargs={}
    super x, y, world, kwargs
    @nightvision = 3
    @vis = Optics::Vision.new world
    @equipment = nil
  end

  def luminescence= new_val
    @luminescence = new_val
    @lum.compute_visibility @x, @y, @luminescence
  end

  def compute_visibility
    @vis.compute_visibility @x, @y, @nightvision
  end

  def drop_item
    unless @equipment.nil?
      @equipment.move_to @x, @y
      @world.add_item @equipment
      @equipment = nil
      self.luminescence = 0  # TODO: not 0, 'default'
    end
  end

  # Take an item, drop the one you had.
  # Don't give nil to drop an item, use drop_item instead
  def give_item item
    drop_item
    @equipment = item
    self.luminescence = item.luminescence
  end

  def move kwargs
    nx = @x + (kwargs[:x] || 0)
    ny = @y + (kwargs[:y] || 0)
    unless @world.cave.solid? nx, ny
      move_to nx, ny
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
    @items = [Item.new(*@cave.open_spot, self, luminescence: 5, symb: '(')]
    @dude = Entity.new *@cave.open_spot, self, symb: '@'
    @entities = [@dude]
    recompute_visibilities
  end

  def recompute_visibilities
    @entities.each {|entity| entity.compute_visibility}
  end

  # Adds an item to be found in the world
  def add_item item
    @items.push item
  end

  def pick_up entity=nil, item=nil
    entity ||= @dude
    if item.nil?  # pick up the top item
      index = @items.index {|item| entity.distance_to(item) == 0}  # close item
      item = @items[index] unless index.nil?
    else  # pick up the specified item
      return false unless entity.distance_to item == 0  # too far away
      index = @items.index item
    end
    return false if index.nil?  # couldn't find it
    @items.delete_at index  # remove from the world
    @dude.give_item item
  end

  def tick
    recompute_visibilities
  end

  def symb_at x, y
    [@entities, @items].each do |iterable|
      element = iterable.find {|element| element.distance_to(x, y) == 0}
      return element.symb unless element.nil?
    end
    nil
  end

  def to_s
    toS = ""
    @cave.raw_map.each_with_index do |row, y|
      row.each_with_index do |elem, x|
        if @dude.x == x && @dude.y == y
          toS << color("@", 94)  # can always see yourself
        elsif @dude.vis.seen? x, y  # I've seen it before (or right now)
          symb = elem ? "#" : "."
          if @dude.vis.visible? x, y  # I see it right now
            symb = ((symb_at x, y) || symb)  # get the entity or item
            if lights?(x, y)  # lit up
              toS << color(symb, 93)
            else  # nightvison
              toS << color(symb, 90)
            end
          else
            toS << color(symb, 30)  # memory
          end
        else
          toS << color(" ", 30)  # yet unseen
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
  world.dude.vis.remember_all if str.chr == "o"
  world.dude.vis.forget_all if str.chr == "p"
  world.pick_up if str.chr == ","
  world.dude.drop_item if str.chr == "."
  world.add_item Item.new(world.dude.x, world.dude.y, world, luminescence: 5, symb: '(') if str.chr == "l"
  world.tick
end
