require 'fileutils'
require './vision'
require './cave'
require './item_data'
require './constants'

def color text, color=nil
  return text.to_s if color.nil?
  s = "\033["
  s << color.to_s << "m" << text.to_s << "\033[0m"
  s
end


class Item
  @default = ItemData::DEFAULT
  class << self
    attr_reader :default
  end
  attr_reader :x
  attr_reader :y
  attr_reader :floor
  attr_reader :symb
  attr_reader :name
  attr_reader :color
  attr_reader :luminescence
  def initialize x, y, floor, item_data, extra_data={}
    @floor = floor
    @default = self.class.default.merge item_data.merge extra_data  # Take values from extra, then data, then default
    @default.each do |key, value|
      raise "'#{key}' must be defined for '#{@default[:name]}'" if value.nil? && !(extra_data.has_key? key)
      instance_variable_set "@#{key}", value
    end
    @lum = Optics::Light.new floor
    move_to x, y
  end

  def distance_to x, y=nil
    x, y = x.x, x.y if y.nil?
    (@x - x).abs + (@y - y).abs
  end

  def floor= floor
    @floor = floor
    @lum.floor = floor
  end

  def clear_floor
    self.floor = nil
  end

  def move_to x, y, floor=nil
    @x = x
    @y = y
    self.floor = floor unless floor.nil? || floor == @floor
    @lum.compute_visibility @x, @y, @luminescence
  end

  # return the x coordinate, the y coordinate, and the current floor
  def location
    [@x, @y, @floor]
  end

  # Returns true if this Item casts light on the given square
  def lights? x, y
    @lum.visible? x, y
  end

  private :floor=
end


class Entity < Item
  @default = EntityData::DEFAULT
  attr_reader :vis
  attr_reader :nightvision
  attr_reader :equipment
  def initialize x, y, floor, entity_data, extra_data={}
    super x, y, floor, entity_data, extra_data
    @vis = Optics::Vision.new floor
  end

  def luminescence= new_val
    @luminescence = new_val
    @lum.compute_visibility @x, @y, @luminescence
  end

  def compute_visibility
    @vis.compute_visibility @x, @y, @nightvision
  end

  def floor= floor
    super floor
    @vis.floor = floor
  end

  def drop_item
    unless @equipment.nil?
      @equipment.move_to @x, @y, @floor
      @floor.add_item @equipment
      @equipment = nil
      self.luminescence = @default[:luminescence]  # TODO: still not right, might be more factors affecting you
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


class Trap < Item
  attr_reader :floor_direction
  attr_reader :destination
  @default = TrapData::DEFAULT
  def initialize x, y, floor, trap_data, extra_data={}
    super x, y, floor, trap_data, extra_data
  end

  def destination= loc
    nx, ny = loc
    ox, oy, floor_id = @destination
    @destination = loc + [floor_id] if ox == -1 && oy == -1
    @destination
  end
end

# Allows potentially infinite dungeons to be created without having to store
# potentially infinite dungeons in memory. Caches recently used Floors and
# saves LRU Floors to disk. Also Plans out the overall shape of the Dungeon and
# sews Floors' staircases together according to The Plan.
class FloorManager
  @direction_data = {
    UP => [TrapData::STAIRS_UP, TrapData::STAIRS_DOWN[:name]],
    DOWN => [TrapData::STAIRS_DOWN, TrapData::STAIRS_UP[:name]]
  }
  class << self
    attr_reader :direction_data
  end
  def initialize max_size=5
    @max_size = max_size
    @floors = {}
  end

  def loaded? floor_id
    @floors.has_key? floor_id
  end

  def [](floor_id)
    floor = @floors.delete floor_id
    if floor.nil?  # either load or create the floor
      filename = 'saves/temp/floor_' + floor_id
      if File.exists? filename  # load the floor
        File.open(filename, 'rb') do |file|
          floor = Marshal.load file
        end
      else  # create the floor
        floor = generate_new_floor floor_id
      end
    end
    self[floor_id] = floor  # force reorder
    floor
  end

  def []= key, val
    @floors.delete key  # force reorder
    @floors[key] = val
    if @floors.length > @max_size  # limit the cache
      floor = @floors.first[0]
      filename = 'saves/temp/floor_' + key
      File.open(filename, 'wb') {|file| Marshal.dump floor, file}
      @floors.delete floor
    end
    val
  end

  # Create a new floor, give it staircases, and connect the staircases with
  # existing ones on other floors if you can.
  def generate_new_floor floor_id
    floor = Floor.new floor_id
    exits(floor_id).each do |next_floor_id, direction|
      open_spot = floor.cave.open_spot  # pick a spot to put one of this floor's staircases

      stair_data, next_name = self.class.direction_data[direction]
      if loaded? next_floor_id  # might as well link the stairs now
        next_floor = @floors[next_floor_id]
        next_stairs = next_floor.trap_find do |stairs|  # get his stairs to us
          stairs.destination == [-1, -1, floor_id] &&  # he already knows about us
            stairs.name == next_name
        end
        next_stairs.destination = open_spot  # set him to go where our stairs let out
        stairs = Trap.new(
          *open_spot, floor, stair_data,
          destination: [next_stairs.x, next_stairs.y, next_floor_id])
      else  # just set a placeholder
        stairs = Trap.new(
          *open_spot, floor, stair_data,
          destination: [-1, -1, next_floor_id])
      end
      floor.add_trap stairs
    end
    floor
  end

  # This is The Plan
  def exits floor_id
    level, _, parallel = floor_id.partition "_"
    level = level.to_i
    parallel = parallel.to_i
    return [["2_1", DOWN]] if level == 1
    [["#{level + 1}_1", DOWN], ["#{level - 1}_1", UP]]
  end

  private :[]=, :generate_new_floor, :exits
end


class World
  attr_reader :dude
  def initialize
    @floors = FloorManager.new
    floor = @floors["1_1"]  # first floor
    trap_loc = floor.trap_find {|trap| trap.name == "stairs down"}.location
    # @dude = Entity.new *floor.cave.open_spot, floor, EntityData::DUDE
    @dude = Entity.new *trap_loc, EntityData::DUDE
    add_entity @dude
    @dude.floor.recompute_visibilities
  end

  def take_stairs entity, direction=(UP | DOWN)
    floor = entity.floor
    stairs = floor.trap_find {|trap| trap.location == entity.location &&
      (trap.floor_direction & direction) != 0}
    return nil if stairs.nil?
    floor.remove_entity entity
    entity.vis.forget_all  # TODO: not ideal, but works as a quick fix
    _, _, new_floor_id = *stairs.destination
    new_floor = @floors[new_floor_id]  # may fix the link
    x, y, _ = *stairs.destination
    new_floor.add_entity entity
    entity.move_to x, y, new_floor
  end

  def tick
    @dude.floor.recompute_visibilities
  end

  def pick_up entity=nil, item=nil
    entity ||= @dude
    item = entity.floor.remove_item entity.x, entity.y, item
    unless item.nil?
      entity.give_item item
      item.clear_floor  # make sure we don't accidentally keep a Floor in memory
    end
    item
  end

  def add_item item
    item.floor.add_item item
  end

  def add_entity entity
    entity.floor.add_entity entity
  end

  def tear_down
    FileUtils.rm_rf('saves/temp')
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
  def initialize floor_id
    bnum, _, pnum = floor_id.partition "_"
    @basement_num = bnum.to_i
    @parallel_num = pnum.to_i
    @cave = CaveLib::Cave.new CaveLib::STRAT3
    @items = [Item.new(*@cave.open_spot, self, ItemData::TORCH)]
    @entities = []
    @traps = []
    recompute_visibilities
  end

  def open_spot
    x, y = @cave.open_spot
    [x, y, self]
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

  def add_trap trap
    @traps.push trap
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
      return nil unless item.location == [x, y, self]
      @items.delete item
    end
    item
  end

  def remove_entity entity
    @entities.delete entity
  end

  def trap_find &block
    @traps.find &block
  end

  def symb_at x, y
    [@entities, @items, @traps].each do |iterable|
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

  def to_s
    "Floor #{self.floor_id}"
  end

  def floor_id
    "#{@basement_num}_#{@parallel_num}"
  end
end


if __FILE__ == $0
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
    world.take_stairs world.dude, UP if str.chr == "<"
    world.take_stairs world.dude, DOWN if str.chr == ">"
    world.add_item Item.new(*world.dude.location, ItemData::TORCH) if str.chr == "l"
    world.tick
  end
  world.tear_down
end
