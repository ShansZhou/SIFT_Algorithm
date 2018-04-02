function [ orientation ] = assignOrientation( keypoints, octaves, accumSigmas )

keypointDescriptor = keypoints{1};

%% gradient magnitutde
magnitutde = cell(size(octaves,1),size(octaves{1},4),2);

for octave = 1:size(octaves,1)
    for scaleId = 1:size(octaves{octave},4)
        diffX = [0 0 0; -1 0 1; 0 0 0];
        diffXMat = imfilter(octaves{octave}(:,:,1,scaleId), diffX);
        diffY = [0 1 0; 0 0 0; 0 -1 0];
        diffYMat = imfilter(octaves{octave}(:,:,1,scaleId), diffY);
        
        magnMat = sqrt(diffXMat.*diffXMat + diffYMat.*diffYMat);
        orientMat = atan2(diffYMat, diffXMat);
        magnitutde{octave}{scaleId}{1} = magnMat;
        magnitutde{octave}{scaleId}{2} = orientMat;
    end
end

%% gradient histgram
orientationDescriptor = cell(size(keypointDescriptor, 1),size(keypointDescriptor,2));
sizeOfHistgram = 36;
hist = zeros(sizeOfHistgram,1);
counter = 0;
for octave = 1:size(keypointDescriptor, 1)
    for kptLayer = 1:size(keypointDescriptor,2)
        
        [rowKpt,colKpt] = find(keypointDescriptor{octave,kptLayer} == 1);
        accumSigma = accumSigmas(octave, kptLayer)*1.5;
        weightKernel = fspecial('gaussian',[round(accumSigma*6-1) round(accumSigma*6-1)], accumSigma);
        
        knlHeight = size(weightKernel,1);
        knlWidth = size(weightKernel,2);
        
        winHeight = size(magnitutde{octave}{kptLayer}{1},1);
        winWidth = size(magnitutde{octave}{kptLayer}{1},2);
        totWeighted = magnitutde{octave}{kptLayer}{1};
        
        for keypoint = 1:size([rowKpt colKpt],1)
            xfrom = round(colKpt(keypoint)-knlWidth/2);
            xto = round(colKpt(keypoint)+knlWidth/2-1);
            yfrom = round(rowKpt(keypoint)-knlHeight/2);
            yto = round(rowKpt(keypoint)+knlHeight/2-1);
            
            truncXKnlLeft = 0;
            truncXKnlRight = 0;
            truncYKnlTop = 0;
            truncYKnlBottom = 0;
            if(xfrom<1)
                xfrom = 1;
                truncXKnlLeft = knlWidth-(xto-xfrom)-1;
            end
            
            if(yfrom<1)
                yfrom = 1;
                truncYKnlTop = knlHeight-(yto-yfrom)-1;
            end
            
            if(xto>winWidth)
                xto = winWidth;
                truncXKnlRight = knlWidth-truncXKnlLeft-(xto-xfrom+1);
            end
            
            if(yto>winHeight)
                yto=winHeight;
                truncYKnlBottom = knlHeight - truncYKnlTop-(yto-yfrom+1);
            end
            weightKernelEval = weightKernel((1+truncYKnlTop):(size(weightKernel,1)-truncYKnlBottom),  ...
                (1+truncXKnlLeft):(size(weightKernel,2)-truncXKnlRight));
            
            maxKnl = max(max(weightKernelEval));  
            weightKernelEval = weightKernelEval.*(1/maxKnl);
            magnitudes = totWeighted(yfrom:yto,xfrom:xto);
            counter=counter+1;
            magnitudes = weightKernelEval.*magnitudes;
            
            %gets the matrix of orientations
            orientations = magnitutde{octave}{kptLayer}{2}(yfrom:yto,xfrom:xto);
            orientations = (orientations.*180)./pi; % + 180;
            
            %for each bucket get the magnitudes
            for bucket=1:36
                bucketRangeFrom = (bucket-19)*10;
                bucketRangeTo = (bucket-18)*10;
                
                [rowOr, colOr] = find(orientations<bucketRangeTo & orientations>=bucketRangeFrom);
                %                    indexes = sub2ind(size(weightedMagnitudes),rowOr,colOr);
                %                    hist(bucket) = sum(weightedMagnitudes(indexes));
                indexes = sub2ind(size(magnitudes),rowOr,colOr);
                hist(bucket) = sum(magnitudes(indexes));
                
            end
            
            %finds the position of highest peak of the histogram
            posMaxHist = find(hist==max(hist));
            
            %finds those that are within 80% of the highest peak
            posOtherHist = find(hist>(max(hist)-max(hist)*0.2)&hist~=hist(posMaxHist(1)));
            
            posAllHist = zeros(1,1);
            if(size(posOtherHist,1)>0)
                posAllHist = cat(2,posMaxHist,posOtherHist.');
            else
                posAllHist = posMaxHist;
            end          
            interpolatedOrientations = zeros(size(posAllHist,1),1);  
            for currentBestHist = 1:size(posAllHist,2)
                posHist = posAllHist(currentBestHist);
                x1 = posHist-1;
                x2 = posHist;
                x3 = posHist+1;
                
                y1 = 0;
                y2 = hist(x2);
                y3 = 0;
           
                %in order not to lose the topology
                if(x1<1)
                    y1 = hist(36);
                else
                    y1 = hist(x1);
                end
                
                if(x3>36)
                    y3 = hist(1);
                else
                    y3 = hist(x3);
                end
                
                valsX = [x1-0.5 x2-0.5 x3-0.5];
                
                valsY = [y1 y2 y3];
                
                pars = polyfit(valsX,valsY,2);
                
                xMax = (pars(2)*(-1))/(2*pars(1));
                if(xMax<0)
                    xMax = 36+xMax;
                end
                
                if(xMax>36)
                    xMax = xMax-36;
                end
                
                %now, convert to degrees
                xMax = xMax * 10;
                interpolatedOrientations(currentBestHist) = xMax;
            end
            
            %creates the structure with the data
            histDescriptor = struct('octave', octave, ...
                'layer', kptLayer, ...
                'position',[rowKpt(keypoint) colKpt(keypoint)], ...
                'histogram', hist, ...
                'bestHist', posAllHist.', ...
                'interpOrien', interpolatedOrientations.', ...
                'theBestHist', posMaxHist);

            orientationDescriptor{octave}{kptLayer}(rowKpt(keypoint),colKpt(keypoint)) = histDescriptor;
        end
    end
end

%returns orientation descriptor along with magnitudes and orientations
tempVal = cell(2);
tempVal{1} = orientationDescriptor;
tempVal{2} = magnitutde;

orientation = tempVal;

end

