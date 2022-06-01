import math
import cv2

"""
"""


class Point:

    def __init__(self, x, y):
        self.x = int(x)
        self.y = int(y)


class Rectangle:

    def __init__(self, x, y, w, h, angle):

        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.angle = angle

    def draw(self, image, colour=(0, 255, 0)):
        pts = self.get_vertices_points()
        im = draw_polygon(image, pts, colour)
        return im


    def rotate_rectangle(self, theta):
        pt0, pt1, pt2, pt3 = self.get_vertices_points()

        # Point 0
        rotated_x = math.cos(theta) * (pt0.x - self.x) - math.sin(theta) * (pt0.y - self.y) + self.x
        rotated_y = math.sin(theta) * (pt0.x - self.x) + math.cos(theta) * (pt0.y - self.y) + self.y
        point_0 = Point(rotated_x, rotated_y)

        # Point 1
        rotated_x = math.cos(theta) * (pt1.x - self.x) - math.sin(theta) * (pt1.y - self.y) + self.x
        rotated_y = math.sin(theta) * (pt1.x - self.x) + math.cos(theta) * (pt1.y - self.y) + self.y
        point_1 = Point(rotated_x, rotated_y)

        # Point 2
        rotated_x = math.cos(theta) * (pt2.x - self.x) - math.sin(theta) * (pt2.y - self.y) + self.x
        rotated_y = math.sin(theta) * (pt2.x - self.x) + math.cos(theta) * (pt2.y - self.y) + self.y
        point_2 = Point(rotated_x, rotated_y)

        # Point 3
        rotated_x = math.cos(theta) * (pt3.x - self.x) - math.sin(theta) * (pt3.y - self.y) + self.x
        rotated_y = math.sin(theta) * (pt3.x - self.x) + math.cos(theta) * (pt3.y - self.y) + self.y
        point_3 = Point(rotated_x, rotated_y)

        return point_0, point_1, point_2, point_3

    def get_vertices_points(self):
        x0, y0, width, height, _angle = self.x, self.y, self.w, self.h, self.angle
        b = math.cos(math.radians(_angle)) * 0.5
        a = math.sin(math.radians(_angle)) * 0.5
        pt0 = Point(int(x0 - a * height - b * width), int(y0 + b * height - a * width))
        pt1 = Point(int(x0 + a * height - b * width), int(y0 - b * height - a * width))
        pt2 = Point(int(2 * x0 - pt0.x), int(2 * y0 - pt0.y))
        pt3 = Point(int(2 * x0 - pt1.x), int(2 * y0 - pt1.y))
        pts = [pt0, pt1, pt2, pt3]
        return pts

    

    # Green's Theorem - Finds area of any simple polygon that only requires the coordinates of each vertex
    def _area(self, p):
        return 0.5 * abs(sum(x0 * y1 - x1 * y0
                             for ((x0, y0), (x1, y1)) in self._segments(p)))

    def _segments(self, p):
        return zip(p, p[1:] + [p[0]])

    def __str__(self):
        return "Rectangle: x: {}, y: {}, w: {}, h: {}, angle: {}".format(self.x, self.y, self.w, self.h, self.angle)


def draw_polygon(image, pts, colour=(255, 255, 255), thickness=1):
    """
    Draws a rectangle on a given image.
    :param image: What to draw the rectangle on
    :param pts: Array of point objects
    :param colour: Colour of the rectangle edges
    :param thickness: Thickness of the rectangle edges
    :return: Image with a rectangle
    """

    for i in range(0, len(pts)):
        n = (i + 1) if (i + 1) < len(pts) else 0
        cv2.line(image, (pts[i].x, pts[i].y), (pts[n].x, pts[n].y), colour, thickness)

    return image



def show_image(img):
    cv2.namedWindow("Display window", cv2.WINDOW_AUTOSIZE)
    cv2.imshow("Display Window", img)
    cv2.waitKey(0)


def check_intersection_is_line(rec):
    """
    :param rec: Rectangle Object
    Checks if Rectangle has a non-zero area, by looking at the x and y point ensuring that at l
    east two points on each axis are different.
    :return: bool: True or False
    """
    point_0_rec2, point_1_rec2, point_2_rec2, point_3_rec2 = rec.get_vertices_points()

    x_axis = (point_0_rec2.x, point_1_rec2.x, point_2_rec2.x, point_3_rec2.x)

    y_axis = (point_0_rec2.y, point_1_rec2.y, point_2_rec2.y, point_3_rec2.y)

    x_axis = set(x_axis)
    y_axis = set(y_axis)

    x_axis_len = len(set(x_axis))
    y_axis_len = len(set(y_axis))

    if y_axis_len <= 1 or x_axis_len <= 1 or int(rec.h) == 0 or int(rec.w) == 0:
        return True
    else:
        return False