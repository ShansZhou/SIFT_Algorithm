
function descriptor = constructDesriptor2(orientationDef, keypoints) 

    windowSize = 16;
    keypointDescriptor = keypoints{1};
    numOfKeypoints = keypoints{4};
    kptDescriptors = repmat(struct('octave',0,'kptLayer',0,'kptDescriptor',zeros(4,4,8),'kptX',0,'kptY',0),numOfKeypoints,1);
    counter = 0; 
    for octave = 1:size(keypointDescriptor, 1)
        for kptLayer = 1:size(keypointDescriptor,2)

            [rowKpt, colKpt] = find(keypointDescriptor{octave,kptLayer} == 1);           
            if(size(rowKpt,1)==0)
                continue; 
            end  
            keypointData = orientationDef{1}{octave}{kptLayer}; 
            magnitudes = orientationDef{2}{octave}{kptLayer}{1};
            orientations = orientationDef{2}{octave}{kptLayer}{2};
            
            %for each keypoint
            for keypoint = 1:size([rowKpt colKpt],1)        
                keypointDetail = keypointData(rowKpt(keypoint),colKpt(keypoint));            
                %for each of the main orientations of the keypoint 
                for orient = 1:size(keypointDetail.bestHist,1)
                    kptDescriptor = zeros(128,1);
                    counter = counter+1;
                    degreeInd = orient; 
                    %get the degree to rotate
                    degrees = keypointDetail.interpOrien(degreeInd); 
                    %the gaussian weights for the window 
                    gaussWeight = getGaussWeights(windowSize, windowSize/2);
                    row = rowKpt(keypoint);
                    col = colKpt(keypoint);
                    v=[row, col]'; 
                     c=[size(magnitudes,1)/2, size(magnitudes,2)/2]' ; 
                    rotAngle=degrees; 
                    rotAngle = 360 - rotAngle; 
                    rotMagnitudes= imrotate(magnitudes,rotAngle);
                    %the rotation is also performed for orientations
                    rotOrientations= imrotate(orientations,rotAngle);
                    %this is rotation matrix such as explained by Erik
                    RM=[cosd(rotAngle) -sind(rotAngle) 
                           sind(rotAngle) cosd(rotAngle)];

                    temp_v=RM*(v-c);
                    rot_v = temp_v+c;
                    difmat = [(size(rotMagnitudes,1) - size(magnitudes,1))/2, (size(rotMagnitudes,2) - size(magnitudes,2))/2]';
                    rot_v2 = rot_v + difmat;

                    rotRow = rot_v2(1);
                    rotCol = rot_v2(2);

                    %the window is 16 x 16 pixels in the keypoint level 
                    for x = 0:windowSize-1
                        for y = 0:windowSize-1

                            %first identify subregion I am in 
                            subregAxisX = floor(x/4); 
                            subregAxisY = floor(y/4); 
                            yCoord = rotRow + y - windowSize/2; 
                            xCoord = rotCol + x - windowSize/2; 
                            yCoord = round(yCoord); 
                            xCoord = round(xCoord); 
                            %get the magnitude 
                            if(yCoord>0&&xCoord>0&&yCoord<=size(rotMagnitudes,1) && xCoord<=size(rotMagnitudes,2)) 
                                magn = rotMagnitudes(yCoord,xCoord); 
                                %multiply the magnitude by gaussian weight 
                                magn = magn*gaussWeight(y+1,x+1); 

                                orientation = rotOrientations(yCoord,xCoord);
                                orientation = orientation + pi;
                                %calculate the respective bucket
                                bucket = (orientation)*(180/pi); 
                                bucket = ceil(bucket/45); 
                                kptDescriptor((subregAxisY*4+subregAxisX)*8 + bucket) = ...
                                              kptDescriptor((subregAxisY*4+subregAxisX)*8 + bucket) + magn;
                            end 
                        end 
                    end 
                    %normalize the vector 
                    sqKptDescriptor = kptDescriptor.^2; 
                    sumSqKptDescriptor = sum(sqKptDescriptor);
                    dem = sqrt(sumSqKptDescriptor); 
                    kptDescriptor = kptDescriptor./dem; 
                    %threshold 
                    kptDescriptor(find(kptDescriptor>0.2))=0.2; 
                    %Renormalizing
                    sqKptDescriptor = kptDescriptor.^2; 
                    sumSqKptDescriptor = sum(sqKptDescriptor);
                    dem = sqrt(sumSqKptDescriptor); 
                    kptDescriptor = kptDescriptor./dem; 
                    kptDescriptors(counter) = struct('octave',octave,'kptLayer',kptLayer, ...
                                    'kptDescriptor',kptDescriptor, ... 
                                        'kptX',colKpt(keypoint),'kptY',rowKpt(keypoint));                    
                end 
            end 
        end 
    end 

    descriptor = kptDescriptors; 

    function getGaussWeights = getGaussWeights(windowSize, sigma)
        k = fspecial('Gaussian', [windowSize windowSize], sigma);
        k = k.*(1/max(max(k))); 
        getGaussWeights = k; 
    end 
            
end 