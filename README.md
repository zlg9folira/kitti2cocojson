# kitti2cocojson
A basic tool for converting Kitti object annotations to bbox annotation for LiDAR bird-eye-view object detection in coco JSON format.

ATTENTION: the conversion does not take bounding boxes inside camera images into account. This project uses bird-eye-view LiDAR coordinate system (2D) and all bbox coordinate references should be inside LiDAR frame.

## Kitti Labels
Kitti provides annotations in txt format for every frame. Every line in annotation file represents an object with 15 elements as shown in the this table. The first element is object class and the last element is bounding box rotation angle around vertical axis in camera 3D coordinate system.

<img width="693" alt="kitti_labels" src="https://user-images.githubusercontent.com/35779029/170735579-9da9c754-2615-4da9-ba7f-e17bff8ea5de.png">

## Sensor Coordinates
Kitti spatial references (even for 3D bounding boxes) are all in camera coordinate system. A one dimension CAM2LiDAR transformation would be required if annotations are used within Velodyne pointcloud data. This transformation should take place on "z" axis within camera frame.

<img width="694" alt="kitti_frames" src="https://user-images.githubusercontent.com/35779029/170731925-93c43497-4365-4f71-bd89-1ff3772c3663.png">

## Usage

### Prepare input annotation
Clone the repository and create required directories:

```
git clone https://github.com/zlg9folira/kitti2cocojson
cd kitti2cocojson && mkdir json data
```
Create a new folder called "annotations"  in which you put all Kitti label files (download labels from [Kitti 3D object detection dataset](http://www.cvlibs.net/datasets/kitti/eval_object.php?obj_benchmark=3d)). Your "annotations" folder should now contatin "000001.txt" "000002.txt" etc.

### Start annotation format conversion

Simply run "convert" script inside Matlab (tested on R2020b):
```
convert.m
```

The script will first scan all the files within "annotations" folder. Next, it will shuffle and split annotations based on split percentages specified in "convert.m" (defalut: 70/20/10 for train/test/val). This stage will generate "train.txt", "test.txt" and "val.txt" (inside "data" folder). The script will then read the name of frames for "train/test/val" splits and generates associated annotation JSON file (inside "json" folder).

Annotation generated by the script follow COCO JSON FORMAT (example below):

<img width="847" alt="coco" src="https://user-images.githubusercontent.com/35779029/170732913-5dee6175-225f-4838-9203-a84884fc80ad.png">



