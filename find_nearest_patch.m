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
function nearest_patch = find_nearest_patch(image_data, coordinate, Information)
    % information
    mask = Information.mask;
    patch_size = Information.patch_size;
    half_patch_size = floor(patch_size/2);
    stable_patch_index_map = Information.stable_patch_index_map;
    
    % get the target patch and it's mask according to the coordiante
    [patch_mask, row_offset, col_offset] = get_patch_data(mask, coordinate, patch_size);
    target_patch = get_patch_data(image_data, coordinate, patch_size);
    
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
    
    % we should set the forbid area to avoid to obtain a patch that has some missing pixels
    ssd_map(stable_patch_index_map==0)=inf;
    
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