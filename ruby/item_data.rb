require 'set'

require './constants'
require './item_properties'

# If a variable is mapped to nil it MUST be overwritten. If the default value
# is meant to be nil, simply omit it from the hash.
module ItemData
  DEFAULT = {name: 'unnamed item', symb: '?', luminescence: 0,
    properties: Set.new.freeze}
  TORCH = {name: 'torch', symb: '(', color: 33, luminescence: 5,
    properties: [P::HOT, P::WIELDABLE, P::WOODEN].to_set.freeze}
  SWORD = {name: 'iron sword', symb: ')',
    properties: [P::SWORD, P::WIELDABLE, P::IRON].to_set.freeze}
  TEAPOT = {name: 'iron teapot', symb: '(', color: 36,
    properties: [P::IRON].to_set.freeze}
end


module EntityData
  DEFAULT = {name: 'unnamed entity', symb: '@', luminescence: 0, nightvision: 3}
  DUDE = {name: 'dude', symb: '@', color: 94}
  BLACKSMITH = {name: 'blacksmith', symb: 'h', color: 92, luminescence: 20, wants: P::IRON & !P::SWORD}
end


module TrapData
  DEFAULT = {name: 'unnamed trap', symb: '^', luminescence: 0, floor_direction: 0}
  STAIRS_DOWN = {name: 'stairs down', symb: '>', floor_direction: DOWN, destination: nil}
  STAIRS_UP = {name: 'stairs up', symb: '<', floor_direction: UP, destination: nil}
end
