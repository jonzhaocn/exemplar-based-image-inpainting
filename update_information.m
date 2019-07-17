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
    patch_size = Information.patch_size;
    image_pixel_index = Information.image_pixel_index;
    normal_vector_matrix = Information.normal_vector_matrix;
    %% update mask
    old_mask = mask;
    [~, row_offset, col_offset] = get_patch_data(mask, coordinate, patch_size);
    mask(row_offset+coordinate(1), col_offset+coordinate(2)) = 1;
    mask_3d = repmat(mask, 1,1,3);
    %% update Boundary
    % update Boundary.map and normal_vector
    windows_size = patch_size+4;
    [mask_patch, row_offset, col_offset] = get_patch_data(mask, coordinate, windows_size);
    
    % normal vector
    [Nx, Ny] = gradient(double(1-mask_patch));
    Normal = cat(3, Nx, Ny);
    Normal = Normal ./ (sqrt(Nx.^2 + Ny.^2));
    Normal(~isfinite(Normal))=0; % handle NaN and Inf
    
    boundary_map = 1-mask_patch;
    se = strel('square',3);
    boundary_map = imdilate(boundary_map, se) - boundary_map;
    
    row_indicator = row_offset>-(windows_size-1)/2 & row_offset<(windows_size-1)/2;
    col_indicator = col_offset>-(windows_size-1)/2 & col_offset<(windows_size-1)/2;
    row_offset = row_offset(row_indicator);
    col_offset = col_offset(col_indicator);
    
    % update normal_vector
    normal_vector_matrix(row_offset+coordinate(1), col_offset+coordinate(2), :) = Normal(row_indicator, col_indicator, :);
    % update Boundary.map
    Boundary.map(row_offset+coordinate(1), col_offset+coordinate(2)) = boundary_map(row_indicator, col_indicator);
    
    % update Boundary.is_empty
    if ~any(Boundary.map(:))
        Boundary.is_empty = true;
    end
    % update Boundary.update_sub
    index = Boundary.map .* image_pixel_index;
    update_index = index(row_offset+coordinate(1), col_offset+coordinate(2));
    update_index(update_index==0) = [];
    [row, col] = ind2sub(size(Boundary.map), update_index(:));
    Boundary.update_sub = [row col];
    %% update priority_map
    % erase priority_map near the update area
    priority_map(row_offset+coordinate(1), col_offset+coordinate(2)) = 0;
    %% update pixel_confidence
    update_pixel = (~old_mask & mask).* image_pixel_index;
    update_pixel(update_pixel==0) = [];
    patch_pixel_confidence = get_patch_data(pixel_confidence, coordinate, patch_size);
    pixel_confidence(update_pixel) = sum(patch_pixel_confidence(:))/numel(patch_pixel_confidence);
    %% update Gradient
    gx = Gradient.gx;
    gy = Gradient.gy;
    
    half_length = floor((patch_size+2)/2);
    for r =max(1, coordinate(1)-half_length): min(size(gx,1), coordinate(1)+half_length)
        for c = max(1, coordinate(2)-half_length): min(size(gx, 2), coordinate(2)+half_length)
            
            if mask(r,c)==0
                continue;
            end
            
            % gx(r,c) = image(r+1,c) - image(r,c)
            if r+1<=size(image_data,1) && mask(r+1,c)==1
                gx(r,c,:) = image_data(r+1,c,:)-image_data(r,c,:);
            % if the pixels below I(r,c) is missing, using the above one instead
            else
                if r-1>=1 && mask(r-1,c)==1
                    gx(r,c,:) = image_data(r-1,c,:)-image_data(r,c,:);
                else
                    gx(r,c,:) = 0;
                end
            end
            
            % gy
            if c+1<=size(image_data, 2) && mask(r,c+1)==1
                gy(r,c,:) = image_data(r,c+1,:) - image_data(r,c,:);
            else
                if c-1>=1 && mask(r,c-1)==1
                    gy(r,c,:) = image_data(r,c-1,:)-image_data(r,c,:);
                else
                    gy(r,c,:) = 0;
                end
            end
            
        end
    end
    
    Gradient.gx = gx .* mask_3d;
    Gradient.gy = gy .* mask_3d;
    %% save Information
    Information.mask = mask;
    Information.Boundary = Boundary;
    Information.priority_map = priority_map;
    Information.pixel_confidence = pixel_confidence;
    Information.Gradient = Gradient;
    Information.normal_vector_matrix = normal_vector_matrix;
end