# http://roguebasin.roguelikedevelopment.org/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels
module CaveLib
  STRAT1 = [0.45, [[5, lambda {|s, x, y| s.wallcount?(x, y) >= 5}]]]
  STRAT2 = [0.45, [[5, lambda {|s, x, y| s.wallcount?(x, y) >= 5 ||
                                         s.wallcount?(x, y) == 0}]]]
  STRAT3 = [0.40, [[4, lambda {|s, x, y| s.wallcount?(x, y) >= 5 ||
                                         s.wallcount?(x, y, 2) <= 3}],
                   [3, lambda {|s, x, y| s.wallcount?(x, y) >= 5}]]]

  class Cave
    attr_reader :width
    attr_reader :height
    attr_reader :raw_map
    def initialize strat
      @height = 23
      @width = 79
      gen_map *strat
    end

    # returns some open spot
    def open_spot
      20.times do  # timeout if it's not working
        x = rand(@width)
        y = rand(@height)
        return [x, y] unless solid? x, y
      end
      @height.times do |y|
        @width.times do |x|
          return [x, y] unless solid? x, y
        end
      end
      raise "No open spots!"
    end

    # number of walls surrounding (and including) the given square in a radius r
    def wallcount? x, y, r=1
      s = 0
      (1 + r * 2).times do |ox|
        (1 + r * 2).times do |oy|
          s += 1 if (get(x + ox - r, y + oy - r))
        end
      end
      s
    end

    def clone_rawmap
      Marshal.load(Marshal.dump(@raw_map))
    end

    def solid? x, y
      @raw_map[y][x]
    end

    def oob x, y
      ((0 > y) || (0 > x) || @raw_map[y].nil? || @raw_map[y][x].nil?)
    end

    def get x, y, default=true
      return default if oob x, y
      @raw_map[y][x]
    end

    def gen_map p_wall_init, spawn_params
      @raw_map = (0...@height - 2).collect{(0...@width - 2).collect{rand() < p_wall_init}}
      temp = clone_rawmap

      spawn_params.each do |iterations, condition|
        iterations.times do
          (@width - 2).times do |x|
            (@height - 2).times do |y|
              temp[y][x] = condition.call(self, x, y)
            end
          end
          @raw_map = temp
          temp = clone_rawmap
        end
      end

      # ensure the borders are closed off
      @raw_map.each {|row| row.unshift(true); row.push(true)}
      @raw_map.unshift([true] * @width)
      @raw_map.push([true] * @width)
    end

    def to_s
      toS = ""
      @raw_map.each do |row|
        row.each do |elem|
          toS << (elem ? "#" : ".")
        end
        toS << "\n"
      end
      toS
    end
  end
end
