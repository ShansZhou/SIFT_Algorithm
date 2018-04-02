    image1 = imread('imgSource.jpg');
    image2 = imread('imgTemplate.jpg');
    
    result1 = descriptorSIFT(image1);
    result2 = descriptorSIFT(image2);
    
    matches = getMatches(result1, result2); 
     
    plotMatches(image1,image2,matches);  