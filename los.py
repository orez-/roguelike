# http://playtechs.blogspot.ca/2007/03/2d-portal-visibility-part-1.html

portals = [[   1,  1,   1, -1,   1,  0 ],
		   [  -1,  1,   1,  1,   0,  1 ],
		   [  -1, -1,  -1,  1,  -1,  0 ],
		   [   1, -1,  -1, -1,   0, -1 ]]

def a_right_of_b(ax, ay, bx, by):
    return ax * by > ay * bx

class Visibility(object):
	def __init__(self, oob, is_solid, clear_visibility, set_visible):
		self.oob = oob
		self.is_solid = is_solid
		self.clear_visibility = clear_visibility
		self.set_visible = set_visible

	def compute_visibility(self, viewer_x, viewer_y):
		self.clear_visibility()
		for i in portals:
			self.compute_visibility2(viewer_x, viewer_y, viewer_x, viewer_y, *(i[0:4]))

	def compute_visibility2(self, viewer_x, viewer_y, target_x, target_y, ldx, ldy, rdx, rdy):
		if (self.oob(target_x, target_y)):
			return

		self.set_visible(target_x, target_y)

		if (self.is_solid(target_x, target_y)):
			return

		dx = 2 * (target_x - viewer_x)
		dy = 2 * (target_y - viewer_y)

		for i in portals:
			pldx = dx + i[0]
			pldy = dy + i[1]
			prdx = dx + i[2]
			prdy = dy + i[3]

			if a_right_of_b(ldx, ldy, pldx, pldy):
				cldx = ldx
				cldy = ldy
			else:
				cldx = pldx
				cldy = pldy
			if a_right_of_b(rdx, rdy, prdx, prdy):
				crdx = prdx
				crdy = prdy
			else:
				crdx = rdx
				crdy = rdy

			if a_right_of_b(crdx, crdy, cldx, cldy):
				self.compute_visibility2(viewer_x, viewer_y, target_x + i[4], target_y + i[5], cldx, cldy, crdx, crdy)
