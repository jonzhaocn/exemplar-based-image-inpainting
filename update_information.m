% update some information which help to inpaint image
% Input:
%   image_data:
%   coordinate:
% Output:
%   Information:
function Information = update_information(image_data, coordinate, Information)
    %% init
    mask = Information.mask;
    Boundary = Information.Boundary;
    priority_map = Information.priority_map;
    pixel_confidence = Information.pixel_confidence;
    Gradient = Information.Gradient;
    Config = Information.Config;
    patch_size = Config.patch_size;
    %% update mask
    old_mask = mask;
    [~, row_offset, col_offset] = get_patch_data(mask, coordinate, patch_size);
    mask(row_offset+coordinate(1), col_offset+coordinate(2)) = 1;
    mask_3d = cat(3, mask, mask, mask);
    %% update Boundary
    % update Boundary.map
    windows_size = patch_size+4;
    [boundary_map, row_offset, col_offset] = get_patch_data(mask, coordinate, windows_size);
    boundary_map = 1-boundary_map;
    se = strel('square',3);
    boundary_map = imdilate(boundary_map, se) - boundary_map;
    row_indicator = row_offset>-(windows_size-1)/2 & row_offset<(windows_size-1)/2;
    col_indicator = col_offset>-(windows_size-1)/2 & col_offset<(windows_size-1)/2;
    row_offset = row_offset(row_indicator);
    col_offset = col_offset(col_indicator);
    Boundary.map(row_offset+coordinate(1), col_offset+coordinate(2)) = boundary_map(row_indicator, col_indicator);
    % update Boundary.is_empty
    if ~any(Boundary.map(:))
        Boundary.is_empty = true;
    end
    % update Boundary.update_sub
    index = reshape(1:numel(Boundary.map), size(Boundary.map));
    index = Boundary.map .* index;
    update_index = index(row_offset+coordinate(1), col_offset+coordinate(2));
    update_index(update_index==0) = [];
    [row, col] = ind2sub(size(Boundary.map), update_index(:));
    Boundary.update_sub = [row col];
    %% update priority_map
    priority_map(row_offset+coordinate(1), col_offset+coordinate(2)) = 0;
    %% update pixel_confidence
    index = reshape(1:numel(mask), size(mask));
    update_pixel = (~old_mask & mask).* index;
    update_pixel(update_pixel==0) = [];
    patch_pixel_confidence = get_patch_data(pixel_confidence, coordinate, patch_size);
    pixel_confidence(update_pixel) = sum(patch_pixel_confidence(:))/numel(patch_pixel_confidence);
    %% update Gradient
    windows_size = patch_size + 4;
    [patch_image_data, row_offset, col_offset] = get_patch_data(image_data, coordinate, windows_size);
    row_indicator = row_offset>-(windows_size-1)/2 & row_offset<(windows_size-1)/2;
    col_indicator = col_offset>-(windows_size-1)/2 & col_offset<(windows_size-1)/2;
    row_offset = row_offset(row_indicator);
    col_offset = col_offset(col_indicator);
    gx = patch_image_data(:,[2:end,end],:)-patch_image_data;
    gy = patch_image_data([1,1:end-1],:,:)-patch_image_data;
    
    gx = gx(row_indicator, col_indicator,:);
    gy = gy(row_indicator, col_indicator,:);
    
    index = reshape(1:numel(mask), size(mask));
    index = get_patch_data(index, coordinate, windows_size-2);
    recount_map = zeros(size(row_offset,1), size(col_offset,1));
    row = row_offset==-(windows_size-3)/2 | row_offset==-(windows_size-5)/2 | row_offset==(windows_size-3)/2 | row_offset==(windows_size-5)/2;
    col = col_offset==-(windows_size-3)/2 | col_offset==-(windows_size-5)/2 | col_offset==(windows_size-3)/2 | col_offset==(windows_size-5)/2;
    recount_map(row,:) = 1;
    recount_map(:,col) = 1;
    for i =1:size(recount_map,1)
        for j = 1:size(recount_map,2)
            [r, c] = ind2sub(size(mask), index(i,j));
            if recount_map(i,j)==0 || mask(r,c)==0
                continue;
            end
            if c+1<=size(image_data,2) && mask(r,c+1)==1
                gx(i,j,:) = image_data(r,c+1,:)-image_data(r,c,:);
            else
                if c-1>=1 && mask(r,c-1)==1
                    gx(i,j,:) = image_data(r,c-1,:)-image_data(r,c,:);
                else
                    gx(i,j,:) = 0;
                end
            end
            if r-1>=1 && mask(r-1,c)==1
                gy(i,j,:) = image_data(r-1,c,:) - image_data(r,c,:);
            else
                if r+1<=size(image_data,1) && mask(r+1,c)==1
                    gy(i,j,:) = image_data(r+1,c,:)-image_data(r,c,:);
                else
                    gy(i,j,:) = 0;
                end
            end
        end
    end
    [r,c]= ind2sub(size(mask), index);
    r = r(:,1);
    c = c(1,:)';
    Gradient.gx(r,c,:) = gx;
    Gradient.gx = Gradient.gx .* mask_3d;
    Gradient.gy(r,c,:) = gy;
    Gradient.gy = Gradient.gy .* mask_3d;
    %% save Information
    Information.mask = mask;
    Information.Boundary = Boundary;
    Information.priority_map = priority_map;
    Information.pixel_confidence = pixel_confidence;
    Information.Gradient = Gradient;
end