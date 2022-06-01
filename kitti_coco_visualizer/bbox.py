#!/usr/bin/env python

import cv2
import numpy as np
import json
import helper
import math
from PIL import Image, ImageDraw

image_name = '000269'
image_id = int(image_name)
img = cv2.imread('%s.png'%image_name)
image = Image.open('%s.png'%image_name).convert("RGB")


f = open('train.json', 'r')
data = json.load(f)
f.close()

count = 0
bbox_list = []
for annotation in data['annotations']:
	if annotation['image_id']==image_id:
		bbox_list.append(annotation['bbox'])

draw = ImageDraw.Draw(image)
    

# method 1: using Pillow 
for bbox in bbox_list:
	theta = bbox[4]
	xmin = bbox[0]
	ymin = bbox[1]
	w = bbox[2]
	h = bbox[3]
	centre = np.array([xmin + w / 2.0, ymin + h / 2.0])
	original_points = np.array([[xmin, ymin],[xmin + w, ymin],[xmin + w, ymin + h],[xmin, ymin + h]])
	rotation = np.array([[np.cos(theta), np.sin(theta)], [-np.sin(theta), np.cos(theta)]])
	corners = np.matmul(original_points - centre, rotation) + centre
	corners = np.append(corners, corners[0])  # You need this to close the box
	draw.line((corners[0],corners[1],corners[2],corners[3],corners[4],corners[5],corners[6],corners[7],corners[8],corners[9]), fill="yellow", width=2)

image.save('%s_bbox.png'%image_name, quality=95)


# methhod 2: using CV
for bbox in bbox_list:
	degree = math.degrees(bbox[4]) #convert from range [-3.14,3.14] to [-180,180]
	p = helper.Point(bbox[0]+bbox[2]/2,bbox[1]+bbox[3]/2) #convert bbox [top left] coordinater to [center] 
	rec = helper.Rectangle(p.x,p.y,bbox[2],bbox[3],degree)
	rec.rotate_rectangle(degree)
	img = rec.draw(img)

  
 
cv2.imshow('image', img)
  
cv2.waitKey(0)
cv2.destroyAllWindows()
