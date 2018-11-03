% inpaint the image vioulently
% Input:
%   image_data:
%   coordinate:
%   Information:
% Output:
%   image_data

function image_data = brute_force_filling(image_data, coordinate, Information)
    % information
    mask = Information.mask;
    patch_size = Information.patch_size;
    
    % get the target patch and it's mask according to the coordiante
    [patch_mask, row_offset, col_offset] = get_patch_data(mask, coordinate, patch_size);
    patch_mask_3d = repmat(patch_mask, 1,1,3);
    patch_image_data = get_patch_data(image_data, coordinate, patch_size);
    
    % find the nearest patch 
    nearest_patch = find_nearest_patch(image_data, coordinate, Information);
    nearest_patch = nearest_patch(row_offset+(patch_size+1)/2, col_offset+(patch_size+1)/2, :);
    
    % inpaint the target patch
    patch_image_inpainting_data = patch_image_data .* patch_mask_3d + nearest_patch.* (1-patch_mask_3d);
    image_data(row_offset+coordinate(1), col_offset+coordinate(2),:) = patch_image_inpainting_data;
end