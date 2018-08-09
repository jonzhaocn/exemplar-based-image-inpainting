function [data, row_offset, col_offset] = get_patch_data(whole_data, center_coordinate, patch_size)
    row_start = center_coordinate(1) - (patch_size-1)/2;
    row_end = center_coordinate(1) + (patch_size-1)/2;
    col_start = center_coordinate(2) - (patch_size-1)/2;
    col_end = center_coordinate(2) + (patch_size-1)/2;
    if row_start < 1
        row_start = 1;
    end
    if row_end > size(whole_data,1)
        row_end = size(whole_data,1);
    end
    if col_start < 1
        col_start = 1;
    end
    if col_end > size(whole_data,2)
        col_end = size(whole_data,2);
    end
    data = whole_data(row_start:row_end,col_start:col_end,:);
    row_offset = row_start:row_end;
    row_offset = row_offset' - center_coordinate(1);
    col_offset = col_start:col_end;
    col_offset = col_offset' - center_coordinate(2);
end