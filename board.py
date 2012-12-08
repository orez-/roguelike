import random

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

width = 79
height = 23

class Board(object):
    def __init__(self):
        self.raw_map = []
        self.gen_map()
        self.vis_map = [[0 for _ in row] for row in self.raw_map]
        self.my_map = [[self.get_walltile(x, y) for x, elem in enumerate(row)]
            for y, row in enumerate(self.raw_map)]

    def width(self):
        return width

    def height(self):
        return height

    def is_solid(self, x, y):
        return self.get_at(x, y)

    def set_visible(self, x, y):
        self.vis_map[y][x] = 2

    def is_visible(self, x, y):
        return self.vis_map[y][x] == 2

    def clear_visibility(self):
        self.vis_map = [[int(bool(i)) for i in v] for v in self.vis_map]

    def oob(self, x, y):
        return not (0 <= y < height and 0 <= x < width)

    def get_walltile(self, x, y):
        if self.raw_map[y][x] == 0:
            return u"\u2592"
        return wall_lookup[self.get_wallcount(x, y)]

    def get_at(self, x, y, default=0):
        if 0 <= y < len(self.raw_map) and 0 <= x < len(self.raw_map[y]):
            return self.raw_map[y][x]
        return default

    def get_wallcount_diag(self, x, y):
        x -= 1
        y -= 1
        return sum([self.get_at(x + i % 3, y + i // 3, 1) for i in xrange(9) if i != 4])

    def get_wallcount(self, x, y):
        mysum = (self.get_wallcount_diag(x, y - 1) != 8) and (self.get_at(x, y - 1))
        mysum += ((self.get_wallcount_diag(x + 1, y) != 8) and (self.get_at(x + 1, y) * 2))
        mysum += ((self.get_wallcount_diag(x, y + 1) != 8) and (self.get_at(x, y + 1) * 4))
        mysum += ((self.get_wallcount_diag(x - 1, y) != 8) and (self.get_at(x - 1, y) * 8))
        return mysum

    def gen_map(self):
        """ http://roguebasin.roguelikedevelopment.org/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels """
        self.raw_map = [[int(random.random() < .45) for x in xrange(width - 2)] for y in xrange(height - 2)]
        temp = [[0 for _ in row] for row in self.raw_map]

        for _ in xrange(5):
            for x in xrange(width - 2):
                for y in xrange(height - 2):  # a tile becomes a wall if it was a wall and 4 or
                    # more of its nine neighbors were walls, or if it was not a
                    # wall and 5 or more neighbors were
                    temp[y][x] = ((5 - self.get_at(x, y)) <= self.get_wallcount_diag(x, y))
            self.raw_map = temp
            temp = [[0 for _ in row] for row in self.raw_map]


        for row in self.raw_map:
            row[:] = [1] + row + [1]
        self.raw_map = [[1] * width] + self.raw_map + [[1] * width]