% initiate some information which help to inpaint image
% Input:
%   image_data: image array
%   patch_size: 
%   target_region: 
% Output:
%   image_data: image array
%   Information: some information help to inpaint image
% 
function [image_data, Information] = init(image_data, target_region, patch_size)
    %% check
    if mod(patch_size,2)==0
        error('patch_size should be odd.')
    end
    %% calculate
    % mask: missing pixel will be marked as 0
    mask = ~target_region;
    mask_3d = repmat(mask, 1, 1, 3);
    
    % confidence of pixel
    pixel_confidence = double(mask);
    
    % boundary_map: the valid pixels around target_region
    boundary_map = double(target_region);
    se = strel('square',3);
    boundary_map = imdilate(boundary_map, se) - boundary_map;
    
    priority_map = zeros(size(boundary_map));
    
    % Boundary
    [row, col] = find(boundary_map==1);
    % update_coor, the coordination of the patch whos priority need to be calculate 
    update_coor = [row col];
    is_empty = ~any(boundary_map(:));
    Boundary = struct('map', boundary_map, 'update_coor', update_coor, 'is_empty', is_empty);
    
    % normal vector
    [ny, nx] = gradient(double(~mask));
    length = (sqrt(nx.^2 + ny.^2));
    nx = nx ./ length;
    nx(~isfinite(nx))=0; % handle NaN and Inf
    ny = ny ./ length;
    ny(~isfinite(ny))=0;
    NormalVector = struct('nx', nx, 'ny', ny);
    
    % Gradient, image gradient in x axis and y axis
    gx = image_data([2:end,end],:,:);
    gx = gx - image_data;
    gy = image_data(:,[2:end,end],:);
    gy = gy - image_data;
    for i=1:size(update_coor, 1)
        r = update_coor(i,1);
        c = update_coor(i,2);
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
    gx = sum(gx.*mask_3d, 3)/size(image_data, 3);
    gy = sum(gy.*mask_3d, 3)/size(image_data, 3);
    Gradient = struct('gx',gx,'gy',gy);
    
    % stable_patch_map
    % if a patch do not contain missing pixels, it is stabel
    stable_patch_index_map = (conv2(mask, ones(patch_size, patch_size), 'valid') == patch_size^2);

    % Information
    Information.mask = mask;
    Information.Boundary = Boundary;
    Information.priority_map = priority_map;
    Information.pixel_confidence = pixel_confidence;
    Information.Gradient = Gradient;
    Information.patch_size = patch_size;
    Information.image_data_CIELab = rgb2lab(image_data);
    Information.stable_patch_index_map = stable_patch_index_map;
    Information.NormalVector = NormalVector;
end