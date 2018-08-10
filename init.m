% initiate some information which help to inpaint image
% Input:
%   image_data: image array
%   Config: patch size and the mark color which point out the missing area
% Output:
%   image_data: image array
%   Information: some information help to inpaint image
% 
function [image_data, Information] = init(image_data, Config)
    %% check
    if mod(Config.patch_size,2)==0
        error('patch_size should be a odd.')
    end
    %% calculate
    % mask: missing pixel will be marked as 0
    mark_color = Config.mark_color;
    mask = ~(image_data(:,:,1)==mark_color(1) & image_data(:,:,2)==mark_color(2) & image_data(:,:,3)==mark_color(3));
    mask_3d = cat(3,mask,mask,mask);
    image_data = rgb2lab(image_data);
    % source_region and target_region
    source_region = mask;
    target_region = 1-mask;
    % confidence of pixel
    pixel_confidence = double(mask);
    % boundary_map, the pixel in boundary will be marked as 1
    boundary_map = 1-mask;
    se = strel('square',3);
    boundary_map = imdilate(boundary_map, se) - boundary_map;
    priority_map = zeros(size(boundary_map));
    % Boundary
    [row, col] = find(boundary_map==1);
    % update_sub, the coordination of the patch whos priority need to be calculate 
    update_sub = [row col];
    is_empty = ~any(boundary_map(:));
    Boundary = struct('map', boundary_map, 'update_sub', update_sub, 'is_empty', is_empty);
    % Gradient, image gradient in x axis and y axis
    gx = image_data(:,[2:end,end],:);
    gx = gx - image_data;
    gy = image_data([1,1:end-1],:,:);
    gy = gy - image_data;
    for i=1:size(update_sub,1)
        r = update_sub(i,1);
        c = update_sub(i,2);
        if c+1<=size(image_data,2) && mask(r,c+1)==1
            gx(r,c,:) = image_data(r,c+1,:)-image_data(r,c,:);
        elseif c-1>=1 && mask(r,c-1)==1
            gx(r,c,:) = image_data(r,c-1,:)-image_data(r,c,:);
        end
        if r-1>=1 && mask(r-1,c)==1
            gy(r,c,:) = image_data(r-1,c,:) - image_data(r,c,:);
        elseif r+1<=size(image_data,1) && mask(r+1,c)==1
            gy(r,c,:) = image_data(r+1,c,:)-image_data(r,c,:);
        end
    end
    gx = gx.*mask_3d;
    gy = gy.*mask_3d;
    Gradient = struct('gx',gx,'gy',gy);
    % Information
    Information = struct('mask',mask, 'Boundary', Boundary, 'priority_map', priority_map, 'Config', Config,...
                        'pixel_confidence', pixel_confidence, 'Gradient', Gradient, 'source_region', source_region, 'target_region', target_region);
end