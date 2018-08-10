% this function is used to find out the nearset patch of target patch which
% has the biggets priority
% Input;
%   image_data: image array
%   target_patch: the patch need to inpaint
%   patch_mask: the mask of target_patch, a binary martix, 1 means the pixel is existing
%   row_offset:
%   col_offset:
%   Information: some information help to inpaint image, a struction
% Output:
%   nearest_patch: the nearest patch of target patch
function nearest_patch = find_nearest_patch(image_data, target_patch, patch_mask, row_offset, col_offset, Information)
    % information
    target_region = Information.target_region;
    patch_size = Information.patch_size;
    half_patch_size = floor(patch_size/2);
    % if the target patch is incompleted or it's size is smaller than
    % patch_size^2
    if numel(patch_mask) < patch_size^2
        new_target_patch = zeros(patch_size, patch_size, size(target_patch,3));
        new_target_patch(row_offset + half_patch_size+1, col_offset+half_patch_size+1, :) = target_patch;
        target_patch = new_target_patch;
        new_patch_mask = zeros(patch_size, patch_size);
        new_patch_mask(row_offset + half_patch_size+1, col_offset+half_patch_size+1) = patch_mask;
        patch_mask = new_patch_mask;
    end
    % get the ssd between target patch and every patch in image data
    % ssd:Sum of squares of difference
    ssd_map_1 = ssd_patch_channel(image_data(:,:,1), target_patch(:,:,1), patch_mask);
    ssd_map_2 = ssd_patch_channel(image_data(:,:,2), target_patch(:,:,2), patch_mask);
    ssd_map_3 = ssd_patch_channel(image_data(:,:,3), target_patch(:,:,3), patch_mask);
    ssd_map = ssd_map_1 + ssd_map_2 + ssd_map_3;
    ssd_map = normalize_matrix(ssd_map);
    % set forbid_area
    % we should set the forbid area to avoid to obtain a patch that has
    % some missing pixels
    se = strel('disk', patch_size);
    forbid_area = imdilate(target_region, se);
    LARGE_CONST = 100;
    ssd_map = ssd_map + forbid_area(half_patch_size+1:size(forbid_area,1)-half_patch_size, ...
                half_patch_size+1:size(forbid_area, 2)-half_patch_size) * LARGE_CONST;
    % select the nearest patch
    [~, index] = min(ssd_map(:));
    [row, col] = ind2sub(size(ssd_map), index);
    row = row + half_patch_size;
    col = col + half_patch_size;
    nearest_patch = image_data(row-half_patch_size:row+half_patch_size, col-half_patch_size:col+half_patch_size, :);
end
% get ssd in single channel
function ssd_map = ssd_patch_channel(image_channel, target_patch_channel, patch_mask)
    target_patch_channel = target_patch_channel .* patch_mask;
    ssd_map = filter2(patch_mask, image_channel.^2, 'valid') + sum(sum(target_patch_channel.^2)) ...
        - 2*filter2(target_patch_channel, image_channel, 'valid');
end

function norm_matrix = normalize_matrix(matrix)
    min_value = min(matrix(:));
    max_value = max(matrix(:));
    norm_matrix = (matrix - min_value) / (max_value - min_value);
end