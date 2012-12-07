#!/usr/bin/python

from __future__ import print_function
from math import atan2, pi, cos, sin, copysign
from get_key import getch
import os
from los import Visibility

wall_lookup = [u"\u25A0",   # 
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

raw_map = [[1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
           [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
           [1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0],
           [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
           [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
           [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
           [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
           [0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0],
           [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]]

vis_map = [[0 for _ in row] for row in raw_map]

# class Frustum(object):
#     def __init__(self, x, y, start=0, end=pi * 2):
#         self.x, self.y = int(x) + .5, int(y) + .5
#         self.start = start
#         self.end = end

#     @staticmethod
#     def get_square_at_angle(r, angle):
#         x, y = map(lambda q: (q + (2 * pi)) % (2 * pi), (cos(angle), sin(angle)))
#         if abs(x) > abs(y):
#             sx = copysign(r, x)
#             sy = y * abs(r / x)
#         else:
#             sx = x * abs(r / y)
#             sy = copysign(r, y)
#         return map(int, (sx, sy))

#     def get_squares(self, r):
#         sx, sy = self.get_square_at_angle(r, self.start)
#         ex, ey = self.get_square_at_angle(r, self.end)
#         if (sx, sy) == (ex, ey):
#             skip = True
#             lst = []
#         else:
#             lst = [(sx, sy)]
#             skip = False
#         while skip or (sx, sy) != (ex, ey):
#             skip = False
#             if sx == r and sy != r:
#                 sy += 1
#             elif sy == r and sx != -r:
#                 sx -= 1
#             elif sx == -r and sy != -r:
#                 sy -= 1
#             elif sy == -r and sx != r:
#                 sx += 1
#             lst.append((sx, sy))
#         return map(lambda (x, y): (int(x + self.x - .5), int(y + self.y - .5)), lst)

#     def angle(self):
#         return self.end - self.start

#     # only works if square is in frustum
#     def clip(self, x, y):
#         maxang = None
#         minang = None
#         one = None
#         two = None
#         for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
#             dx += x - self.x
#             dy += y - self.y
#             angle = (atan2(dy, dx) + (2 * pi)) % (2 * pi)
#             maxang = max(angle, maxang)
#             minang = min(angle, minang)

#         if minang > self.start:  # something worth keeping before the first edge
#             one = Frustum(self.x, self.y, self.start, minang)
#         if maxang < self.end:  # something worth keeping past the farther edge
#             self.start = maxang
#             two = self  # has to be self: we may need to divide further.
#         return filter(lambda q: q and q.angle() > .002, [one, two])


# def compute_visibility(x, y):
#     vis_map[:] = [[bool(e) for e in row] for row in vis_map]
#     frustums = [Frustum(x, y)]
#     i = 1
#     vis_map[y][x] = 1
#     did_stuff = True  # in an enclosed system this ought to be optional.
#     while did_stuff and frustums:  # still have something to look at.
#         did_stuff = False
#         new_frustums = []
#         for f in frustums:
#             for (sx, sy) in f.get_squares(i):
#                 if 0 <= sy < len(vis_map) and 0 <= sx < len(vis_map[sy]):
#                     did_stuff = True
#                     vis_map[sy][sx] = 2  # can see either way
#                     if not raw_map[sy][sx]:  # not solid: time to block
#                         nf = f.clip(sx, sy)
#                         new_frustums += nf
#                         if f not in nf:
#                             break
#                     else:  # keep on truckin
#                         new_frustums.append(f)
#         # frustums = new_frustums
#         i += 1

def clear_visibility():
    global vis_map
    vis_map = [[int(bool(i)) for i in v] for v in vis_map]

def color(text, color):
    return "\033[%dm%s\033[0m" % (color, text)

def clear():
    os.system( [ 'clear', 'cls' ][ os.name == 'nt' ] )

def get_wallcount(x, y):
    if raw_map[y][x] == 0:
        return u"\u2592"
    mysum = get_at(x, y - 1)
    mysum += get_at(x + 1, y) * 2
    mysum += get_at(x, y + 1) * 4
    mysum += get_at(x - 1, y) * 8
    return wall_lookup[mysum]

def get_at(x, y):
    return 0 <= y < len(raw_map) and 0 <= x < len(raw_map[y]) and raw_map[y][x]

my_map = [[get_wallcount(x, y) for x, elem in enumerate(row)]
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
                   elem = color(elem, 90)
            else:
                elem = " "
            # else:
            print(elem, end="")
            # else:
            #    print(" ", end="")
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
dude = Dude(1, 1)

key = 0
while key != u"\u0003":
    redraw()
    key = getch()
    dude.handle_key(key)
