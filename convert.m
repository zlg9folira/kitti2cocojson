clear all;
close all;
fclose('all');


%------------------directory and format setting------------------
Dir_in = '/Users/foadhm/Downloads/relidarperceptiondataset/data/';
Dir_out = '/Users/foadhm/Downloads/relidarperceptiondataset/json/';
Dir_ann = '/Users/foadhm/Downloads/relidarperceptiondataset/annotation/';
In_format = 'txt';
im_format = 'png';
train_portion = 70;test_portion=20;val_portion=10;
res = 0.1;
map_dim = [150 150];
img_size = [map_dim(1)/res map_dim(2)/res];
im_dim = [map_dim(1)/res map_dim(2)/res];
ann_class_name = ["Car","Van","Truck","Pedestrian","Person_sitting","Cyclist","Tram","Misc","DontCare"];
wanted_class_name = ["Car","Van","Truck"];
wanted_class_id = [0,1,2];
ann_class_id = [0,1,2,3,4,5,6,7,8];


%----------------------Verify split portions---------------------
if train_portion+test_portion+val_portion ~=100
    disp('Split portion between train-test-val is not valid (should sum up to 100)');
    quit(1);
end

%-----------------Shuffle annotations and split------------------
fprintf('-------DATASET PREPARATION STARTED---------\n')
f_frames = dir(sprintf('%s*.%s',Dir_ann,In_format));
n_frames = length(f_frames);
frames = [1:n_frames]+"";
for k=1:n_frames
    frames(k)=f_frames(k).name; % e.g., '000001.txt'
end
frames = frames(randperm(n_frames)); % shuffle
max_ind_train = floor(n_frames*train_portion/100);
max_ind_test = max_ind_train + floor(n_frames*test_portion/100);
max_ind_val = n_frames;

frames_train = frames(1:max_ind_train);
frames_test = frames(1 + max_ind_train: max_ind_test);
frames_val = frames(1 + max_ind_test: max_ind_val);

% write frame names into train.txt
fid = fopen(sprintf('%strain.%s',Dir_in,In_format),'wt');
for k=1:length(frames_train)
    C = strsplit(frames_train(k),"."); %separate name from ".txt"
    fprintf(fid,'%s\n',C(1));
end
fclose(fid);
fprintf('Saved %strain.%s\n',Dir_in,In_format);

% write frame names into test.txt
fid = fopen(sprintf('%stest.%s',Dir_in,In_format),'wt');
for k=1:length(frames_test)
    C = strsplit(frames_test(k),"."); %separate name from ".txt"
    fprintf(fid,'%s\n',C(1));
end
fclose(fid);
fprintf('Saved %stest.%s\n',Dir_in,In_format);

% write frame names into val.txt
fid = fopen(sprintf('%sval.%s',Dir_in,In_format),'wt');
for k=1:length(frames_val)
    C = strsplit(frames_val(k),"."); %separate name from ".txt"
    fprintf(fid,'%s\n',C(1));
end
fclose(fid);
fprintf('Saved %sval.%s\n',Dir_in,In_format);

fprintf('------DATASET PREPARATION COMPLETED--------\n')


%---------------go through files and add annotations-------------
fprintf('------------CONVERSION STARTED-------------\n')
Files = dir(sprintf('%s*.%s',Dir_in,In_format));

for k=1:length(Files)
    wanted_class_name_count = zeros(1,length(wanted_class_name));
    valid_image_list = [];
    valid = 0;
    %---------initialize different parts of COCO json format---------
    %categories
    s.categories = struct([]);
    for i=1:length(wanted_class_id)
        scat.id = wanted_class_id(i);
        scat.name = wanted_class_name(i);
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

            %-------------read annotations for this frame-------------
            f_ann = fopen(sprintf('%s%s.%s',Dir_ann,tline_split,In_format), 'rt');
            tline_ann = fgetl(f_ann);
            count_line = 0;
            valid_image = false;
            while ischar(tline_ann)
                if strcmp(class(tline_ann),'char') == 1
                    count_line = count_line +1;

                    %-------break the annotation into 15 parts--------
                    split = string(strsplit(tline_ann," ")); 
                    %-----------build a struct from labels------------
                    this_ann = ann_class_id(find(ann_class_name == split(1)));
                    if sum(split(1) == wanted_class_name) > 0

                        bbw = str2num(split(10))/res; bbh = str2num(split(11))/res;
                        tlx = str2num(split(12))/res+(im_dim(1)/2)-(bbw/2); tly = im_dim(2) - ((str2num(split(14))-0.27)/res+(im_dim(2)/2)+(bbh/2)); %LiDAR-CAM frame 0.27m transform
                        th = str2num(split(15));
                        th_orig = th;
                        % rotate Kitti theta 90 degrees clockwise to match COCO
                        if th>=deg2rad(90)
                            th  = th - deg2rad(270);
                        else
                            th = th + deg2rad(90);
                        end
                        
                        sann.category_id = ann_class_id(find(ann_class_name == split(1)));
                        sann.id = str2num(sprintf('%s%s',num2str(count_line),num2str(str2num(tline_split))));
                        sann.image_id = str2num(tline_split);
                        sann.bbox = [tlx tly bbw bbh th]; %[tlx,tly,w,h,theta] in Kitti image frame
                        
                        % rotate the bbox to calculate segmentation field
                        bb = sann.bbox;
                        x = [bb(1) bb(1)+bb(3) bb(1)+bb(3) bb(1)];
                        y = [bb(2) bb(2) bb(2)+bb(4) bb(2)+bb(4)];
                        % create a matrix of these points, which will be useful in future calculations
                        v = [x;y];
                        % choose a point which will be the center of rotation
                        x_center = bb(1)+bb(3)/2;
                        y_center = bb(2)+bb(4)/2;
                        % create a matrix which will be used later in calculations
                        center = repmat([x_center; y_center], 1, length(x));
                        % define a 60 degree counter-clockwise rotation matrix
                        theta = bb(end);       % pi/3 radians = 60 degrees
                        R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                        % do the rotation...
                        shift = v - center;     % shift points in the plane so that the center of rotation is at the origin
                        so = R*shift;           % apply the rotation about the origin
                        vo = so + center;   % shift again so the origin goes back to the desired center of rotation
                        % pick out the vectors of rotated x- and y-data
                        x_rotated = vo(1,:);
                        y_rotated = vo(2,:);
                        vr = [x_rotated;y_rotated];
                        
                        A = cell(1,1); A{1} = [x_rotated(1) y_rotated(1) x_rotated(2) y_rotated(2) x_rotated(3) y_rotated(3) x_rotated(4) y_rotated(4)];
                        sann.segmentation = A;
                        %sann.segmentation = [x_rotated(1) y_rotated(1) x_rotated(2) y_rotated(2) x_rotated(3) y_rotated(3) x_rotated(4) y_rotated(4)];
                        sann.area = bbw * bbh; % [w*h] 
                        sann.iscrowd = 0;
                            
                        % Make sure this ann is inside image
                        if (tlx+bbw/2>img_size(1) || tlx-bbw/2<0 || tly+bbh/2>img_size(2) || tly-bbh/2<0) == 1
                            % this ann is out of image frame
                            %fprintf("error for image %s\n",tline_split);
                        else
                            %-----Count ann-----
                            cc = find(ann_class_name == split(1));
                            wanted_class_name_count(cc) = wanted_class_name_count(cc) + 1; % count class
                            %-----add this to "annotations" of the struct-----
                            s.annotations = [s.annotations,sann];
                        end
                        
                        
                        if ~valid_image && sum(size(s.annotations)) > 0
                            valid_image = true;
                        end
                    end
                end
                tline_ann = fgetl(f_ann);
            end
            fclose(f_ann);
            
            %-------add this frame to "images" of the struct----------
            if valid_image
                simg.id = str2num(tline_split);
                simg.file_name = sprintf('%s.%s',tline_split,im_format);
                simg.height = img_size(2);
                simg.width = img_size(1);
                s.images = [s.images,simg];
                valid = valid +1;
            end

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

    fprintf('dataset %s: processed %d frames (%d valid)\n', name,count,valid);
    fprintf('\t%s:%d, %s:%d, %s:%d\n',wanted_class_name(1),wanted_class_name_count(1),wanted_class_name(2),wanted_class_name_count(2),wanted_class_name(3),wanted_class_name_count(3));
end
fprintf('------------CONVERSION COMPLETE------------\n')

fclose('all');
