function normal_vector = get_normal_vector2(mask, coordination, patch_size)
    [mask, row, col] = get_patch_data(mask, coordination, patch_size);
    [row, col] = ndgrid(-row, col);
    mask = logical(1-mask);
    row = row(mask);
    col = col(mask);
    normal_vector = normr([col(:) row(:)]);
    normal_vector = sum(normal_vector, 1) / size(normal_vector, 1);
end