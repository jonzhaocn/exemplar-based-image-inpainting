% initiate some information which help to inpaint image
% Input:
%   image_data: image array
%   patch_size: 
%   target_region: 
% Output:
%   image_data: image array
%   Information: some information help to inpaint image
% 
function [image_data, Information] = init(image_data, patch_size, target_region)
    %% check
    if mod(patch_size,2)==0
        error('patch_size should be a odd.')
    end
    %% calculate
    % mask: missing pixel will be marked as 0
    mask = 1 - target_region;
    mask_3d = cat(3,mask,mask,mask);
    % source_region and target_region
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
        % gx(r,c) = image(r,c+1) - image(r,c)
        if c+1<=size(image_data,2) && mask(r,c+1)==1
            gx(r,c,:) = image_data(r,c+1,:)-image_data(r,c,:);
        % if the pixels on I(r,c)'s right is missing, using the left one
        % instead
        else
            if c-1>=1 && mask(r,c-1)==1
                gx(r,c,:) = image_data(r,c-1,:)-image_data(r,c,:);
            else
                gx(r,c,:) = 0;
            end
        end
        if r-1>=1 && mask(r-1,c)==1
            gy(r,c,:) = image_data(r-1,c,:) - image_data(r,c,:);
        else
            if r+1<=size(image_data,1) && mask(r+1,c)==1
                gy(r,c,:) = image_data(r+1,c,:)-image_data(r,c,:);
            else
                gy(r,c,:) = 0;
            end
        end
    end
    gx = gx.*mask_3d;
    gy = gy.*mask_3d;
    Gradient = struct('gx',gx,'gy',gy);
    % stable_patch_map
    % if a patch do not contain missing pixels, it is stabel
    missing_label = 999;
    stable_patch_index = im2col(image_data(:,:,1)+(1-mask)*missing_label, [patch_size, patch_size], 'sliding');
    stable_patch_index = all(stable_patch_index~=missing_label);
    % image_pixel_index
    image_pixel_index = reshape(1:numel(mask), size(mask));
    % Information
    Information.mask = mask;
    Information.Boundary = Boundary;
    Information.priority_map = priority_map;
    Information.pixel_confidence = pixel_confidence;
    Information.Gradient = Gradient;
    Information.patch_size = patch_size;
    Information.image_data_CIELab = rgb2lab(image_data);
    Information.stable_patch_index_map = stable_patch_index;
    Information.image_pixel_index = image_pixel_index;
end