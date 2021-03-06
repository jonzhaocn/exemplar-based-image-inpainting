% this function is used to calculate priority of patch in boundary and
% return the coordination of the patch which has the biggest priority
% Input:
%   image_data: image array
%   Information: some information of image, it is a strcutre
% Output:
%   coordinate: the coordinate of the patch which has the biggest priority
%   Information: some information of image, it is a strcutre
function [coordinate, Information] = calculate_priority(image_data, Information)
    % information
    Boundary = Information.Boundary;
    priority_map = Information.priority_map;
    pixel_confidence = Information.pixel_confidence;
    Gradient = Information.Gradient;
    patch_size = Information.patch_size;
    NormalVector = Information.NormalVector;
    % 
    image_size = size(image_data);
    for i = 1:size(Boundary.update_coor, 1)
        row = Boundary.update_coor(i,1);
        col = Boundary.update_coor(i,2);
        % incompleted patch
        if row<(patch_size+1)/2 || row>image_size(1)-(patch_size-1)/2
            continue
        end
        if col<(patch_size+1)/2 || col>image_size(2)-(patch_size-1)/2
            continue
        end
        % confidence
        patch_pixel_confidence = get_patch_data(pixel_confidence, [row, col], patch_size);
        patch_confidence = sum(patch_pixel_confidence(:))/numel(patch_pixel_confidence);
        % isophote
        gx = Gradient.gx(row, col);
        gy = Gradient.gy(row, col);
        isophote = [-gy, gx];
%       normal vector
        nx = NormalVector.nx(row, col);
        ny = NormalVector.ny(row, col);
        normal_vector = [nx, ny];
        Imax = 255;
        priority_map(row, col) = patch_confidence * abs((isophote * normal_vector')/Imax + 1e-3);
    end
    [value, index] = max(priority_map(:));
    if value == 0
        [r, c] = find(Boundary.map==1, 1, 'first');
        coordinate = [r, c];
    else
        [r, c] = ind2sub(size(priority_map), index);
        coordinate = [r, c];
    end
    % save
    Information.priority_map = priority_map;
end