#!/usr/bin/python

from __future__ import print_function
import os
from math import atan2, pi, cos, sin, copysign

from get_key import getch
from los import Visibility
from board import Board

board = Board()

def color(text, color):
    return "\033[%dm%s\033[0m" % (color, text)

def clear():
    os.system( [ 'clear', 'cls' ][ os.name == 'nt' ] )

def redraw():
    clear()
    for y, row in enumerate(board.my_map):
        for x, elem in enumerate(row):
            if dude.x == x and dude.y == y:
                elem = color("@", 94)
            elif board.vis_map[y][x]:
                if board.vis_map[y][x] == 1:
                    elem = color(elem, 90)  # 30
            else:
                elem = color(" ", 30)
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
        if board.is_solid(self.x, self.y):
            self.x, self.y = old_pos
        visibility.compute_visibility(self.x, self.y)


visibility = Visibility(board)

def place_dude_free():
    """ Place the dude in the first open space """
    for y in xrange(board.height()):
        for x in xrange(board.width()):
            if not board.is_solid(x, y):
                return Dude(x, y)

dude = place_dude_free()

key = 0
while key != u"\u0003":
    redraw()
    key = getch()
    dude.handle_key(key)
