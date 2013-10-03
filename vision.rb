# http://playtechs.blogspot.ca/2007/03/2d-portal-visibility-part-1.html

module Vision
  PORTALS = [[   1,  1,   1, -1,   1,  0 ],
             [  -1,  1,   1,  1,   0,  1 ],
             [  -1, -1,  -1,  1,  -1,  0 ],
             [   1, -1,  -1, -1,   0, -1 ]]

  def self.a_right_of_b(ax, ay, bx, by)
    ax * by > ay * bx
  end

  class Visibility
    def initialize cave
      @cave = cave
      @vis_map = (0...cave.height).collect{(0...cave.width).collect{0}}
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

    def seen_all
      @vis_map.each{|row| row.collect!{|elem| elem < 1 ? 1: elem}}  # see all
    end

    def compute_visibility(viewer_x, viewer_y)
      clear_visibility
      PORTALS.each do |i|
        self.compute_visibility2(viewer_x, viewer_y, viewer_x, viewer_y, *(i[0...4]))
      end

      # POSTPROCESSING #
      # temp = @vis_map.collect{|row| row.collect{|elem| elem}}  # gotta edit the temp, don't want to propagate this
      # @vis_map[0...-1].each_with_index do |row, y|
      #   row[0...-1].each_with_index do |elem, x|
      #     [[0, 0, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1], [0, 1, 0, 0]].each do |wx, wy, cx, cy|
      #       if [[x + wx, y + wy], [x + (wx ^ 1), y + (wy ^ 1)],
      #           [x + cx, y + cy], [x + (cx ^ 1), y + (cy ^ 1)]].all?{
      #           |ox, oy| @cave.solid?(ox, oy) && visible?(ox, oy)}
      #         temp[y + (cy ^ 1)][x + (cx ^ 1)] = 2  # the literal corner case: all sides are visible but the corner cannot
      #       end
      #     end
      #   end
      # end
      # @vis_map = temp
    end

    def compute_visibility2(viewer_x, viewer_y, target_x, target_y, ldx, ldy, rdx, rdy, countdown=5)
      return if (@cave.oob(target_x, target_y))
      return if countdown <= 0
      
      set_visible(target_x, target_y)

      return if (@cave.solid?(target_x, target_y))

      dx = 2 * (target_x - viewer_x)
      dy = 2 * (target_y - viewer_y)

      PORTALS.each do |i|
        pldx = dx + i[0]
        pldy = dy + i[1]
        prdx = dx + i[2]
        prdy = dy + i[3]

        if Vision::a_right_of_b(ldx, ldy, pldx, pldy)
          cldx = ldx
          cldy = ldy
        else
          cldx = pldx
          cldy = pldy
        end
        if Vision::a_right_of_b(rdx, rdy, prdx, prdy)
          crdx = prdx
          crdy = prdy
        else
          crdx = rdx
          crdy = rdy
        end

        if Vision::a_right_of_b(crdx, crdy, cldx, cldy)
          compute_visibility2(viewer_x, viewer_y, target_x + i[4], target_y + i[5], cldx, cldy, crdx, crdy, countdown - 1)
        end
      end
    end
  end
end