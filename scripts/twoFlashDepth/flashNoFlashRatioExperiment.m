%% An algorithm that calculates depth using 2 flash-only images.  
% Andy Lin
% 
% The algorithm, inspired by Hany Farid, takes the ratio of the 2 images,
% and solves for the depth, using ray geometry, providing a crude depth.  
% Next, normal vectors are calculated using this crude depth map, and used
% to correct for the effects of lambertian surface reflectance, 
% providing a more accurate depth map.  
%
% TODO: fix paths


%GTDepthMap = '2FlashDepth/indObject/depthMaps/groundTruthDepthMapDown.mat';
GTDepthMap = 'twoFlashDepth/depthTargetDepths/GTDepthMap.mat';


%% load 1st image
%fullName = '2FlashDepth/indObject/idealDownFrontFlashImage.mat';  
fullName = 'twoFlashDepth/depthTargetDepths/50mmFront.pbrt.image.mat';  

load([s3dRootPath '/data/' fullName],'vci');
vciFlash = vci;
vcAddAndSelectObject('vcimage',vciFlash);
vcimageWindow;

%% load 2nd flash image (flash now placed in back)
%fullName = '2FlashDepth/indObject/idealDownBackFlashImage.mat';
fullName = 'twoFlashDepth/depthTargetDepths/50mmBack.pbrt.image.mat';  

multiplicationFactor = 1;  %to account for differences in exposure
load([s3dRootPath '/data/' fullName],'vci');
vciFlashBack = vci;
vcAddAndSelectObject('vcimage',vciFlashBack);
vcimageWindow;

%% Process images and obtain ratio image
% The ratio image consists of the image with the front flash divided by the
% image with the back flash.  
flashImage = imadjust(imageGet(vciFlash, 'results'), [], [], imageGet(vciFlash, 'gamma'));
flashImageBack = imadjust(imageGet(vciFlashBack, 'results'), [], [], imageGet(vciFlash, 'gamma'));

% calculate ratio image
HSVFlashImage = rgb2hsv(flashImage);
HSVFlashImageBack = rgb2hsv(flashImageBack);

temp = imageGet(vciFlash, 'results');
linearIntensityFlash = sum(temp, 3);
linearIntensityFlash = linearIntensityFlash * multiplicationFactor; %for exposure adjustment!
temp = imageGet(vciFlashBack, 'results');
linearIntensityFlashBack = sum(temp, 3); 
ratioImage = linearIntensityFlash./linearIntensityFlashBack;

%% Use ratio image to calculate crude depth
% After obtaining the ratio image, we can then go through the algebraic
% steps needed to calculate depth

% figure; imagesc(ratioImage);
fieldOfView = 25; % used for front back 100 experiment
sensorWidth = 36;
sensorHeight  = 24;
sensorDistance = sensorWidth/2 / tan(fieldOfView/2 * pi/180);
f = 50;  % f signifies distance between 2 flashes

% calculate alpha and phi for each pixel
xMatrix = linspace(-sensorWidth/2, sensorWidth/2, size(ratioImage,2));
xMatrix = repmat(xMatrix, [size(ratioImage,1), 1]);
yMatrix = linspace(-sensorHeight/2, sensorHeight/2, size(ratioImage,1))';
yMatrix = repmat(yMatrix, [1 size(ratioImage,2)]);
z = sensorDistance;
fakeD1 = sqrt(xMatrix.^2 + yMatrix.^2 + z.^2);
alpha = asin(xMatrix./fakeD1); 
phi   = asin(z./(fakeD1.*cos(alpha)));

%front back flash case
radical = abs(sqrt(4*cos(alpha).^2.*sin(phi).^2.*f.^2 - 4*f^2.*(1 - ratioImage)));
d1Test = (2.*f.^2)./(-2.*cos(alpha).*sin(phi).*f + radical);

figure; imagesc(d1Test);
colorbar; title('Calculated Depth (1st pass)'); caxis([80 150]);

%% First filter the depth map using a separable median, and bilateral filter
%This will provide better data for calculating the normal map later
pixelUnit = sensorWidth / size(ratioImage,2);

%filter the depth map for better noise characteristics
d1TestMedFiltered = medianFilter(d1Test,5);
d1TestMedFiltered = medianFilter(d1TestMedFiltered',5)';
d1TestFiltered = bilateralFilter(d1TestMedFiltered, 10, 4, 25);  
figure; imagesc(d1TestFiltered);
colorbar; title('Filtered Depth'); caxis([80 150]);

%% Estimate the surface normals using the crude depth map
% We perform surface normal estimation by taking the cross product of 2
% perpendicular vectors on the surface.  This vector is averaged amongst
% the 4 pairs of vectors around 1 point of the surface.


% test case - use GT depth map to calculate depth map
% this allows us to decouple the effect of a bad depth map calculation
% method with the 2flashdepth algorithm
%d1TestFiltered = imresize(groundTruthDepthMap, [400 600]);

% calculate normal vectors using averaged cross products
recordedLateralDistance = zeros(size(d1Test));
normalMap = zeros([size(d1Test,1) size(d1Test,2) 3]);
for i = 2:(size(d1TestFiltered, 2) - 1)
    for j = 2:(size(d1TestFiltered,1) -1)
        aRelief = d1TestFiltered(j - 1,i) - d1TestFiltered(j,i);
        bRelief = d1TestFiltered(j, i + 1) - d1TestFiltered(j,i);
        cRelief = d1TestFiltered(j + 1,i) - d1TestFiltered(j,i);
        dRelief = d1TestFiltered(j,i - 1) - d1TestFiltered(j,i);
        
        %lateralDistance = d1TestFiltered(j,i) * pixelUnit/sensorDistance;
        %%this does not make a lot of sense
        
        lateralDistance = d1TestFiltered(j,i) * tan(fieldOfView/size(ratioImage,2) * pi/180);
        lateralDistance = 100 * tan(fieldOfView/size(ratioImage,2) * pi/180);
        recordedLateralDistance(j,i) = lateralDistance;
        aVector = [0 lateralDistance -aRelief];
        bVector = [lateralDistance 0 -bRelief];
        cVector = [0 -lateralDistance -cRelief];
        dVector = [-lateralDistance 0 -dRelief];
        
        adNormal = cross(aVector, dVector);
        adNormal = adNormal./norm(adNormal);
        
        dcNormal = cross(dVector, cVector);
        dcNormal = dcNormal./norm(dcNormal);
        
        cbNormal = cross(cVector, bVector);
        cbNormal = cbNormal./norm(cbNormal);
        
        baNormal = cross(bVector, aVector);
        baNormal = baNormal./norm(baNormal);
        
        averageNormal = (adNormal + dcNormal + cbNormal + baNormal);
        averageNormal = averageNormal./norm(averageNormal);
        
        normalMap(j, i,:) = reshape(averageNormal, [1 1 3]);
    end
end

scaledNormalMap = normalMap./2 + .5;

figure; imshow(scaledNormalMap);
title('Calculated Normal Map');
%% Correcting for Lambert's Law error
% Depending on the relation of the surface normal, and the light direction,
% the intensity is attenuated according to the dot product (proportional to
% the cosine of the angle between the 2 vectors).  This effect was not
% taken into account during the initial calculation. 

linearIntensityFlashCorrected = linearIntensityFlash;
linearIntensityFlashBCorrected = linearIntensityFlashBack;

rayVectors1 = zeros([size(d1Test,1) size(d1Test,2) 3]);
rayVectors2 = zeros([size(d1Test,1) size(d1Test,2) 3]);

frontDot =  zeros([size(d1Test,1) size(d1Test,2)]);
backDot =  zeros([size(d1Test,1) size(d1Test,2)]);

%assuming field of view given above
fakeDistance = sensorWidth/2 / tan(fieldOfView/2 * pi/180);

numWidth = size(d1Test,2);
numHeight = size(d1Test,1);

for i = 1:(size(d1TestFiltered, 2))
    for j = 1:(size(d1TestFiltered,1)) 
        
        % calculate normal vector from front light
        fakeX = pixelUnit * (i - numWidth/2);
        fakeY = pixelUnit * (j - numHeight/2);
        tempVector = [-fakeX fakeY fakeDistance];
        tempVector = tempVector ./ norm(tempVector);
        rayVectors1(j, i, :) = reshape(tempVector, [1 1 3]);

        %use similar triangles to recalculate rayVectors2 (normal vectors
        %for back light
        fakeH = sqrt(fakeX^2 + fakeY^2 + fakeDistance^2);
        fake2RealRatio = (d1TestFiltered(j,i))/fakeH;
        realX = fake2RealRatio* fakeX;
        realY = fake2RealRatio * fakeY;
        realDistance = fake2RealRatio * fakeDistance;
        
        %for front back
        tempVector = [-realX realY realDistance + f];
        
        tempVector = tempVector ./ norm(tempVector);
        rayVectors2(j, i, :) = reshape(tempVector, [1 1 3]);
        frontDot(j,i) = sum(rayVectors1(j,i,:) .* normalMap(j,i,:));
        backDot(j,i) = sum(rayVectors2(j,i,:) .* normalMap(j,i,:));
        
        %calculate correction factors for both images
        linearIntensityFlashCorrected(j,i, :) = linearIntensityFlashCorrected(j,i, :) ./ frontDot(j,i) ; 
        linearIntensityFlashBCorrected(j,i, :) = linearIntensityFlashBCorrected(j,i, :) ./ backDot(j,i) ; 
    end
end 

ratioImage = linearIntensityFlashCorrected./linearIntensityFlashBCorrected;

%% Use ratio image to calculate distance (2nd pass)
% We've corrected for Lambert's Law, so now we can compute the calculated
% distance once again using the identical math.

xMatrix = linspace(-sensorWidth/2, sensorWidth/2, size(ratioImage,2));
xMatrix = repmat(xMatrix, [size(ratioImage,1), 1]);
yMatrix = linspace(-sensorHeight/2, sensorHeight/2, size(ratioImage,1))';
yMatrix = repmat(yMatrix, [1 size(ratioImage,2)]);
z = sensorDistance;

fakeD1 = sqrt(xMatrix.^2 + yMatrix.^2 + z.^2);
alpha = asin(xMatrix./fakeD1); 
phi   = asin(z./(fakeD1.*cos(alpha)));

%front back flash case
radical = abs(sqrt(4*cos(alpha).^2.*sin(phi).^2.*f.^2 - 4*f^2.*(1 - ratioImage)));
d1Test = (2.*f.^2)./(-2.*cos(alpha).*sin(phi).*f + radical);

figure; imagesc(d1Test);
colorbar; title('Calculated Depth (2nd pass)'); caxis([80 150]);

%% Filter the depth map using a separable median, and bilateral filter (2nd pass)
%This will provide better data 

%filter the depth map for better noise characteristics
d1TestMedFiltered = medianFilter(d1Test,5);
d1TestMedFiltered = medianFilter(d1TestMedFiltered',5)';
d1TestFiltered = bilateralFilter(d1TestMedFiltered, 10, 4, 25);  
figure; imagesc(d1TestFiltered);
colorbar; title('Filtered Depth (2nd pass)'); caxis([80 150]);

%% Compare the depth map to the ground truth
import = load(GTDepthMap);
groundTruthDepthMap = import.depthMap; %ProcessedMedian;
figure; imagesc(groundTruthDepthMap);
colorbar; title('Ground Truth Depth Map'); caxis([60 120]);
%% Summary
% We were able to calculate a reasonable depth map from the 2-flash
% algorithm.  Benefits of this algorithm compared to traditional 2-camera
% stereo algorithms include better accuracy for uniform (non-textured)
% regions and superior resolution.  We have yet to make a formal comparison
% of these 2 techniques. The depths may still be off by a scaling factor
% and an offset, but this initial study shows that the algorithm works
% reasonably well.  

%% Future work
% We plan to show the true benefits of this method of calculating a depth
% map.  The algorithm works identically for cases where the flashes, and
% cameras are in different positions.  We plan to investigate this
% scenario.  Also, we have hypothesized that this algorithm will work, with
% the flashes at different positions (for example, side-by-side), but the
% math involved will be slightly different.  We plan to investigate these
% scenarios as well.  Finally, we also plan to form experiments where we
% use local windows to improve accuracy, while sacrificing resolution.  

