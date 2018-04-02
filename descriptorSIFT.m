function result_SIFT = descriptorSIFT(img)

numOfOctave = 4;
scales = 3;

scaleSpcae = calScaleSpace(img,numOfOctave, scales);
octaves = scaleSpcae{1};
accumSigmas = scaleSpcae{2};
octaves_DoG = calDOG(octaves);
keypoints = localiseKeyPoints(octaves_DoG, img);
orientation = assignOrientation(keypoints, octaves, accumSigmas);

keypointDesriptor = constructDesriptor2(orientation, keypoints);

%plotDescriptor(img, orientation, keypoints);

result_SIFT = keypointDesriptor;

end