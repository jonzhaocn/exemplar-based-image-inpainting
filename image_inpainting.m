clear;
clc;
image_path = '2.png';
mark_color = [0,0,0];
Config = struct('patch_size', 15, ...
                'mark_color', mark_color);
image_data = imread(image_path);
[image_data, Information] = init(image_data, Config);
while ~Information.Boundary.is_empty
    [coordinate, Information] = calculate_priority(image_data, Information);
    image_data = inpaint_vioulently(image_data, coordinate, Information);
    imshow(lab2rgb(image_data));
    Information = update_information(image_data, coordinate, Information);
end
imwrite(lab2rgb(image_data), 'image_inpainted.png');