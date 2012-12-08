#!/usr/bin/python

from __future__ import print_function
import os
import random
from math import atan2, pi, cos, sin, copysign

from get_key import getch
from los import Visibility

wall_lookup = [u"\u25AF",   # 
               u"\u2502",   # ^
               u"\u2500",   #  >
               u"\u2514",   # ^>
               u"\u2502",   #   v
               u"\u2502",   # ^ v
               u"\u250C",   #  >v
               u"\u251C",   # ^>v
               u"\u2500",   #    <
               u"\u2518",   # ^  <
               u"\u2500",   #  > <
               u"\u2534",   # ^> <
               u"\u2510",   #   v<
               u"\u2524",   # ^ v<
               u"\u252C",   #  >v<
               u"\u253C"]   # ^>v<

# raw_map = [[1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
#            [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
#            [1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0],
#            [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
#            [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
#            [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
#            [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
#            [0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0],
#            [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]]

raw_map = []

def get_at(x, y, default=0):
    if 0 <= y < len(raw_map) and 0 <= x < len(raw_map[y]):
        return raw_map[y][x]
    return default

def get_wallcount_diag(x, y):
    x -= 1
    y -= 1
    return sum([get_at(x + i % 3, y + i // 3, 1) for i in xrange(9) if i != 4])

def get_wallcount(x, y):
    mysum = (get_wallcount_diag(x, y - 1) != 8) and (get_at(x, y - 1))
    mysum += ((get_wallcount_diag(x + 1, y) != 8) and (get_at(x + 1, y) * 2))
    mysum += ((get_wallcount_diag(x, y + 1) != 8) and (get_at(x, y + 1) * 4))
    mysum += ((get_wallcount_diag(x - 1, y) != 8) and (get_at(x - 1, y) * 8))
    return mysum

def get_walltile(x, y):
    if raw_map[y][x] == 0:
        return u"\u2592"
    return wall_lookup[get_wallcount(x, y)]

def gen_map():
    global raw_map
    width = 79
    height = 23
    raw_map = [[int(random.random() < .45) for x in xrange(width - 2)] for y in xrange(height - 2)]
    temp = [[0 for _ in row] for row in raw_map]

    for _ in xrange(5):
        for x in xrange(width - 2):
            for y in xrange(height - 2):  # a tile becomes a wall if it was a wall and 4 or
                # more of its nine neighbors were walls, or if it was not a
                # wall and 5 or more neighbors were
                temp[y][x] = ((5 - get_at(x, y)) <= get_wallcount_diag(x, y))
        raw_map = temp
        temp = [[0 for _ in row] for row in raw_map]


    for row in raw_map:
        row[:] = [1] + row + [1]
    raw_map = [[1] * width] + raw_map + [[1] * width]

gen_map()

vis_map = [[0 for _ in row] for row in raw_map]

def clear_visibility():
    global vis_map
    vis_map = [[int(bool(i)) for i in v] for v in vis_map]

def color(text, color):
    return "\033[%dm%s\033[0m" % (color, text)

def clear():
    os.system( [ 'clear', 'cls' ][ os.name == 'nt' ] )

my_map = [[get_walltile(x, y) for x, elem in enumerate(row)]
            for y, row in enumerate(raw_map)]

def set_visible(x, y):
    vis_map[y][x] = 2

def is_solid(x, y):
    return get_at(x, y)

def oob(x, y):
    return not (0 <= y < len(raw_map) and 0 <= x < len(raw_map[y]))

def redraw():
    clear()
    for y, row in enumerate(my_map):
        for x, elem in enumerate(row):
            if dude.x == x and dude.y == y:
                elem = color("@", 94)
            elif vis_map[y][x]:
                if vis_map[y][x] == 1:
                    elem = color(elem, 90)  # 30
                # elif abs(dude.x - x) + abs(dude.y - y) > 10:
                #     elem = color(elem, 90)
            else:
                #elem = color(elem, 95)
                elem = " "
            print(elem, end="")
        print(end="\n")

class Dude(object):
    def __init__(self, x, y):
        self.x = x
        self.y = y
        visibility.compute_visibility(self.x, self.y)

    def handle_key(self, key):
        old_pos = (self.x, self.y)
        if key == "w":
            self.y -= 1
        if key == "s":
            self.y += 1
        if key == "a":
            self.x -= 1
        if key == "d":
            self.x += 1
        if raw_map[self.y][self.x]:
            self.x, self.y = old_pos
        visibility.compute_visibility(self.x, self.y)


visibility = Visibility(oob, is_solid, clear_visibility, set_visible)

def place_dude_free():
    for y in xrange(len(raw_map)):
        for x in xrange(len(raw_map[y])):
            if not raw_map[y][x]:
                return Dude(x, y)

dude = place_dude_free()

key = 0
while key != u"\u0003":
    redraw()
    key = getch()
    dude.handle_key(key)
