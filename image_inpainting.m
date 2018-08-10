% this script is the entry of the program
% 
clear;
clc;
% config
image_path = '4.png';
mark_color = [0,0,0];
Config = struct('patch_size',11, ...
                'mark_color', mark_color);
image_data = imread(image_path);
% init 
[image_data, Information] = init(image_data, Config);
% while there are some missing pixels in image, inpaint the image 
while ~Information.Boundary.is_empty
    % calculate the priority of the patch in boundary, select the patch
    % which has the biggest priority to inpaint
    [coordinate, Information] = calculate_priority(image_data, Information);
    % inpaint vioulently
    image_data = inpaint_vioulently(image_data, coordinate, Information);
    figure(1);
    imshow(lab2rgb(image_data));
    % update some infomation which help to inpaint image
    Information = update_information(image_data, coordinate, Information);
end
imwrite(lab2rgb(image_data), 'image_inpainted.png');