import cv2
import numpy as np

class Vision:
    def __init__(self):
        pass

    def detect_color(self, image, lower_bound, upper_bound):
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, lower_bound, upper_bound)
        contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        return contours