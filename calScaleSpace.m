function scaleSpace = calScaleSpace(img, numOfOctave, scales)

img_gray = double(rgb2gray(img))/double(255.0);

%firstSigma = 0.5;
%kernelSize = 15;

image = imresize(img_gray, 2, 'bilinear');
sigma_initial = sqrt(2);
sigma_current = sigma_initial;
totalScales = scales + 3;
octavesCell = cell(numOfOctave,1);
image_initial = image;
image_previous = image_initial;
accumSigmas = zeros(numOfOctave, totalScales);

for octave = 1: numOfOctave
    sigma = zeros(size(image_initial,1), size(image_initial,2), size(image_initial,3), totalScales);
    octavesCell{octave} = sigma;
    for level = 1:totalScales
        if octave ==1 && level ==1
            accumSigmas(octave,level) = sqrt(((0.5*2)^2) +(sigma_current^2));
        elseif level ==1
            accumSigmas(octave,level) = sqrt(((accumSigmas(octave-1,3)/2)^2)+(sigma_current^2));
        else
            accumSigmas(octave,level) = sqrt((accumSigmas(octave,level-1)^2)+(sigma_current^2));
        end
        k = (2^((level)/scales));
        blurredImg = gaussianBlur(image_previous,sigma_current);
        image_previous = blurredImg;
		octavesCell{octave}(:, :, :, level) = blurredImg; 
		sigma_current  = sigma_initial * k;    
    end
    
    sigma_current = sigma_initial;
    image_initial = reduceInHalf(octavesCell{octave}(:,:,:,totalScales-3));
    image_previous = image_initial;
end

scaleSpace = cell(2,1);
scaleSpace{1} = octavesCell;
scaleSpace{2} = accumSigmas;

  	function reduceInHalf = reduceInHalf(image)
		reduceInHalf=image(1:2:end,1:2:end) ;	
	end
end

