# http://playtechs.blogspot.ca/2007/03/2d-portal-visibility-part-1.html

module Optics
  PORTALS = [[   1,  1,   1, -1,   1,  0 ],
             [  -1,  1,   1,  1,   0,  1 ],
             [  -1, -1,  -1,  1,  -1,  0 ],
             [   1, -1,  -1, -1,   0, -1 ]]

  def self.a_right_of_b(ax, ay, bx, by)
    ax * by > ay * bx
  end

  class Vision
    @may_cutoff = false
    class << self
      attr_reader :may_cutoff
    end
    def initialize floor
      self.floor = floor
      @vis_map = (0...@cave.height).collect{(0...@cave.width).collect{0}}
    end

    def floor= new_floor
      if new_floor.nil?
        @floor = nil
        @cave = nil
      else
        @floor = new_floor
        @cave = @floor.cave
      end
    end

    def visible? x, y
      @vis_map[y][x] == 2
    end

    def seen? x, y
      @vis_map[y][x] > 0
    end

    def set_visible x, y
      @vis_map[y][x] = 2
    end

    def clear_visibility
      @vis_map.each{|row| row.collect!{|elem| elem >= 1 ? 1 : 0}}  # normalize
    end

    def remember_all
      @vis_map.each{|row| row.collect!{|elem| elem < 1 ? 1: elem}}  # see all
    end

    def forget_all
      @vis_map.each{|row| row.collect!{0}}
    end

    def compute_visibility(viewer_x, viewer_y, cutoff=-1)
      clear_visibility
      PORTALS.each do |i|
        self.compute_visibility2(viewer_x, viewer_y, viewer_x, viewer_y, *(i[0...4]), cutoff)
      end
    end

    def compute_visibility2(viewer_x, viewer_y, target_x, target_y, ldx, ldy, rdx, rdy, cutoff=-1)
      return if (@cave.oob(target_x, target_y))
      return if cutoff <= 0 && self.class.may_cutoff
      set_visible(target_x, target_y) if ((cutoff > 0) || @floor.lights?(target_x, target_y))
      return if (@cave.solid?(target_x, target_y))

      dx = 2 * (target_x - viewer_x)
      dy = 2 * (target_y - viewer_y)

      PORTALS.each do |i|
        pldx = dx + i[0]
        pldy = dy + i[1]
        prdx = dx + i[2]
        prdy = dy + i[3]

        if Optics::a_right_of_b(ldx, ldy, pldx, pldy)
          cldx = ldx
          cldy = ldy
        else
          cldx = pldx
          cldy = pldy
        end
        if Optics::a_right_of_b(rdx, rdy, prdx, prdy)
          crdx = prdx
          crdy = prdy
        else
          crdx = rdx
          crdy = rdy
        end

        if Optics::a_right_of_b(crdx, crdy, cldx, cldy)
          compute_visibility2(viewer_x, viewer_y, target_x + i[4], target_y + i[5], cldx, cldy, crdx, crdy, cutoff - 1)
        end
      end
    end
  end


  class Light < Vision
    @may_cutoff = true  # light doesn't need to check farther than it projects
  end
end
