% inpaint the image vioulently
% Input:
%   image_data:
%   coordinate:
%   Information:
% Output:
%   image_data

function image_data = inpaint_vioulently(image_data, coordinate, Information)
    % information
    patch_set = Information.patch_set;
    mask = Information.mask;
    Config = Information.Config;
    patch_size = Config.patch_size;
    % 
    [patch_mask, row_offset, col_offset] = get_patch_data(mask, coordinate, patch_size);
    patch_mask_3d = cat(3, patch_mask, patch_mask, patch_mask);
    patch_image_data = get_patch_data(image_data, coordinate, patch_size);
    patch_image_data = patch_image_data(:);
    % the patch is incompleted
    if numel(patch_mask) < patch_size^2
        patch_set_mask = false(patch_size, patch_size);
        patch_set_mask(row_offset+(patch_size+1)/2, col_offset+(patch_size+1)/2) = patch_mask;
        patch_set_mask_3d = cat(3, patch_set_mask, patch_set_mask, patch_set_mask);
    else
        patch_set_mask_3d = patch_mask_3d;
    end
    distance = patch_set(patch_set_mask_3d(:),:) - repmat(patch_image_data(patch_mask_3d(:)), 1, size(patch_set,2));
    distance = sum(distance.^2, 1);
    [~, nearest_patch_index] = min(distance);
    nearest_patch = patch_set(:, nearest_patch_index);
    nearest_patch = reshape(nearest_patch, patch_size, patch_size, size(image_data,3));
    nearest_patch = nearest_patch(row_offset+(patch_size+1)/2, col_offset+(patch_size+1)/2, :);
    patch_image_inpainting_data = reshape(patch_image_data, size(patch_mask_3d)) .* patch_mask_3d + nearest_patch.* (1-patch_mask_3d);
    image_data(row_offset+coordinate(1), col_offset+coordinate(2),:) = patch_image_inpainting_data;
end