require './vision'
require './cave'
require './item_data'

def color text, color=nil
  return text.to_s if color.nil?
  s = "\033["
  s << color.to_s << "m" << text.to_s << "\033[0m"
  s
end


class Item
  attr_reader :x
  attr_reader :y
  attr_reader :floor
  attr_reader :symb
  attr_reader :color
  attr_reader :luminescence
  def initialize x, y, floor, kwargs={}
    @floor = floor
    @symb = kwargs[:symb] || '?'
    @color = kwargs[:color]
    @luminescence = kwargs[:luminescence] || 0
    @lum = Optics::Light.new floor
    move_to x, y
  end

  def distance_to x, y=nil
    x, y = x.x, x.y if y.nil?
    (@x - x).abs + (@y - y).abs
  end

  def change_floor floor
    @floor = floor
    @lum.floor = floor
  end

  def move_to x, y, floor=nil
    @x = x
    @y = y
    change_floor floor unless floor.nil? || floor == @floor
    @lum.compute_visibility @x, @y, @luminescence
  end

  # Returns true if this Item casts light on the given square
  def lights? x, y
    @lum.visible? x, y
  end

  private :change_floor
end


class Entity < Item
  attr_reader :vis
  attr_reader :nightvision
  attr_reader :equipment
  def initialize x, y, floor, kwargs={}
    super x, y, floor, kwargs
    @nightvision = 3
    @vis = Optics::Vision.new floor
    @equipment = nil
  end

  def luminescence= new_val
    @luminescence = new_val
    @lum.compute_visibility @x, @y, @luminescence
  end

  def compute_visibility
    @vis.compute_visibility @x, @y, @nightvision
  end

  def change_floor floor
    super floor
    @vis.floor = floor
  end

  def drop_item
    unless @equipment.nil?
      @equipment.move_to @x, @y, @floor
      @floor.add_item @equipment
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

  # Move by :x in the x direction and :y in the y direction
  def move kwargs
    nx = @x + (kwargs[:x] || 0)
    ny = @y + (kwargs[:y] || 0)
    unless @floor.cave.solid? nx, ny
      move_to nx, ny
      return true
    end
    false
  end
end


class World
  attr_reader :dude
  def initialize
    @floor = Floor.new  # TODO: no.
    @dude = Entity.new *@floor.cave.open_spot, @floor, symb: '@', color: 94
    @floor.add_entity @dude
    @floor.recompute_visibilities
  end

  def tick
    @dude.floor.recompute_visibilities
  end

  def pick_up entity=nil, item=nil
    entity ||= @dude
    item = entity.floor.remove_item entity.x, entity.y, item
    entity.give_item item unless item.nil?
    item
  end

  def to_s
    toS = ""
    floor = @dude.floor
    floor.cave.raw_map.each_with_index do |row, y|
      row.each_with_index do |elem, x|
        if @dude.vis.seen? x, y  # I've seen it before (or right now)
          symb = elem ? "#" : "."
          if @dude.vis.visible? x, y  # I see it right now
            symb, clr = ((floor.symb_at x, y) || [symb, 93])  # get the entity or item
            if floor.lights?(x, y)  # lit up
              toS << color(symb, clr)
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
end


class Floor
  attr_reader :cave
  attr_reader :luminescence
  def initialize
    @cave = CaveLib::Cave.new CaveLib::STRAT3
    @items = [Item.new(*@cave.open_spot, self, ItemData::TORCH)]
    @entities = []
    recompute_visibilities
  end

  def recompute_visibilities
    @entities.each {|entity| entity.compute_visibility}
  end

  # Adds an item to be found on the Floor
  def add_item item
    @items.push item
  end

  def add_entity entity
    @entities.push entity
  end

  # If item is nil : Get the top item at x, y; nil if no items there
  # Otherwise ensure that the given item is close enough to be grabbed
  # if the item is found, remove it from the floor
  def remove_item x, y, item=nil
    if item.nil?  # grab the top one off the stack
      index = @items.index {|item| item.distance_to(x, y) == 0}
      return nil if index.nil?
      item = @items[index]
      @items.delete_at index  # remove from the floor
    else  # fail if you're not close enough to the given item to grab it
      return nil unless (item.floor == self && item.x == x && item.y == y)
      @items.delete item
    end
    item
  end

  def symb_at x, y
    [@entities, @items].each do |iterable|
      element = iterable.find {|element| element.distance_to(x, y) == 0}
      return [element.symb, element.color] unless element.nil?
    end
    nil
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
  world.add_item Item.new(world.dude.x, world.dude.y, world, ItemData::TORCH) if str.chr == "l"
  world.tick
end
