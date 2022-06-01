clear all;
close all;
fclose('all');

%------------------directory and format setting------------------
Dir_in = 'data/';
Dir_out = 'json/';
Dir_ann = 'annotation/';
In_format = 'txt';
im_format = 'png';
res = 0.1;
map_dim = [150 150];
im_dim = [map_dim(1)/res map_dim(2)/res];
ann_class_name = ["Car","Van","Truck","Pedestrian","Person_sitting","Cyclist","Tram","Misc","DontCare"];
ann_class_id = [0,1,2,3,4,5,6,7,8];


%---------------go through files and add annotations-------------
fprintf('------------CONVERSION STARTED-------------\n')
Files = dir(sprintf('%s*.%s',Dir_in,In_format));

for k=1:length(Files)
    %---------initialize different parts of COCO json format---------
    %categories
    s.categories = struct([]);
    for i=1:length(ann_class_id)
        scat.id = ann_class_id(i);
        scat.name = ann_class_name(i);
        s.categories = [s.categories,scat];
    end
    %annotations
    s.annotations = struct([]);
    %images
    s.images = struct([]);
    
    %-----read names of files containing test/train/val data-----
    FileName=Files(k).name; % e.g., train.txt
    [path,name,ext] = fileparts(FileName); % "/path/","train",".txt"
    fprintf('Processing labels for %s dataset...\n',name);
    %-----------get frame name for test/train/val data------------
    f_split = fopen(sprintf('%s%s',Dir_in,Files(k).name), 'rt');
    tline_split = fgetl(f_split);
    count = 0;
    valid = strcmp(class(tline_split),'char') == 1;
    
    while ischar(tline_split) && valid
        if strcmp(class(tline_split),'char') == 0
            %fprintf('filename not valid: %s', num2str(tline_split));
            valid = false;
        else
            count = count +1;
            %-------add this frame to "images" of the struct----------
            simg.id = str2num(tline_split);
            simg.file_name = sprintf('%s.%s',tline_split,im_format);
            s.images = [s.images,simg];

            %-------------read annotations for this frame-------------
            f_ann = fopen(sprintf('%s%s.%s',Dir_ann,tline_split,In_format), 'rt');
            tline_ann = fgetl(f_ann);
            count_line = 0;
            while ischar(tline_ann)
                if strcmp(class(tline_ann),'char') == 1
                    count_line = count_line +1;

                    %-------break the annotation into 15 parts--------
                    split = string(strsplit(tline_ann," ")); 
                    %-----------build a struct from labels------------
                    sann.id = str2num(sprintf('%s%s',num2str(count_line),num2str(simg.id)));
                    sann.image_id = simg.id;
                    sann.category_id = ann_class_id(find(ann_class_name == split(1)));
                    bbw = str2num(split(10))/res; bbh = str2num(split(11))/res;
                    tlx = str2num(split(12))/res+(im_dim(1)/2)-(bbw/2); tly = im_dim(2) - ((str2num(split(14))-0.27)/res+(im_dim(2)/2)+(bbh/2)); %LiDAR-CAM frame 0.27m transform
                    th = str2num(split(15));
                    if th>=deg2rad(90) % rotate Kitti theta 90 degrees clockwise to match COCO (0 is not front of car but x-axis in image)
                        th  = th - deg2rad(270);
                    else
                        th = th + deg2rad(90);
                    end
                    sann.bbox = [tlx tly bbw bbh th]; %[tlx,tly,w,h,theta] in Kitti image frame
                    sann.area = bbw * bbh; % [w*h] 
                    sann.iscrowd = 0;
                    %-----add this to "annotations" of the struct-----
                    s.annotations = [s.annotations,sann];
                end
                tline_ann = fgetl(f_ann);
            end
            fclose(f_ann);
        end
        %fprintf('dataset: %s file: %s %d objects\n',name,tline_split,count_line)% disp(count_line);
        tline_split = fgetl(f_split);
    end
    fclose(f_split);
    
    %-------------convert struct to json and save-------------
    js = jsonencode(s);
    js_filename= sprintf('%s%s.json',Dir_out,name); 
    f_js = fopen(js_filename,'w');
    fprintf(f_js, prettyjson(js));
    fclose(f_js);

    fprintf('dataset %s: processed %d frames\n', name,count);

end
fprintf('------------CONVERSION COMPLETE------------\n')

fclose('all');
