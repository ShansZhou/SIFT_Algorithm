function octaves_DoG = calDOG( octaves )

    numOfOctaves = size(octaves,1);
    cellDoG = cell(numOfOctaves,1);
    
    for i = 1:numOfOctaves
        
        cellDoG{i} = zeros (size(octaves{i},1), size(octaves{i},2), size(octaves{i},3), size(octaves{i},4)-1);
        num = size(octaves{i},4);
        for j = 2: num
            cellDoG{i}(:,:,:,j-1) = octaves{i}(:,:,:,j) - octaves{i}(:,:,:,j-1);
        end
            
    end
    
    octaves_DoG = cellDoG;
end

