function blurredImg = gaussianBlur(img, sigma)

    kernelSize = round(sigma*3 - 1); 
    if(kernelSize<1)
        kernelSize = 1; 
    end 
	kernel = fspecial('gaussian', [kernelSize kernelSize], sigma);
	blurredImg = imfilter(img,kernel,'replicate');

    
end

