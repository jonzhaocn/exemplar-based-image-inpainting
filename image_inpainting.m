% this script is the entry of the program
% 
clear;
clc;
% config
image_path = './image/5.jpg';
patch_size = 11;
image_data = imread(image_path);
image_data = rgb2lab(image_data);
% get missing region from user
% missing region point out where the missing pixels are in image
figure(1), imshow(lab2rgb(image_data));
% use mouse to get some coordination by clicking
[x, y] = ginput;
% after clicking, you should press ENTER
% use these coordination to get the target region 
target_region = poly2mask(x, y, size(image_data,1), size(image_data, 2));
image_data = image_data.*(1-target_region);
% show the masked image
figure(1), imshow(lab2rgb(image_data));
imwrite(lab2rgb(image_data), 'masked_image.jpg');
% init
[image_data, Information] = init(image_data, patch_size, target_region);
% while there are some missing pixels in image, inpaint the image 
while ~Information.Boundary.is_empty
    % calculate the priority of the patch in boundary, select the patch
    % which has the biggest priority to inpaint
    [coordinate, Information] = calculate_priority(image_data, Information);
    % inpaint vioulently
    image_data = inpaint_vioulently(image_data, coordinate, Information);
    % comment the imshow() will speed up the program
    figure(1), imshow(lab2rgb(image_data));
    % update some infomation which help to inpaint image
    Information = update_information(image_data, coordinate, Information);
end
imwrite(lab2rgb(image_data), 'image_inpainted.jpg');