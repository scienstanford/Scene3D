%% Renders a test scene consisting of hemispheres with a plane to reduce shadows
%
% Andy L. Lin
%
% This script renders the basic setup of 2 side-by-side light sources and a
% simple surface in between them.  There will be 2 captures.  One with each
% light source.  The hope is that we can derive some information on the
% normal vectors using this setup.  These captures are rendered using
% pbrtObjects.  This particular script renders it using a reasonably wide
% field of view (~50 degrees) to simulate capture by a typical wide-angle
% camera.


s_initISET

%% Render Lower Right Flash Oi
clear curPbrt;
curPbrt = pbrtObject();

%camera position
newCamPos =    [0  0 80.0000;
    0   0 79.0000;
    0 1.00000 0];
curPbrt.camera.setPosition(newCamPos);
filmDistance = 35;  %this allows for a reassonably wide field of view ~50dFOV
filmDiag = 43.26;
pinholeLens = pbrtLensPinholeObject(filmDistance, filmDiag) ;
curPbrt.camera.setLens(pinholeLens)

%field of view calculation
sensorWidth = filmDiag/sqrt(2);
sensorDistance = filmDistance;
fieldOfView = atan(sensorWidth/2/sensorDistance) * 2 * 180/pi;

%depths
sphereDepths = -170;  %negative is into the screen

%flash separation
flashSeparation = 50;

%scaleFactor
scaleFactor = (-sphereDepths + 80)/(80) * 4;

%backdrop Depth
% backDropDepth = -100 * scaleFactor;  %backdrop distance increases with depth of spheres
backDropDepth = sphereDepths;  %backdrop distance increases with depth of spheres

%calculate sphere offsets
xValues = linspace(-6 * scaleFactor, 6 * scaleFactor, 5);
yValues = linspace(-6 * scaleFactor, 6 * scaleFactor, 5);
[xOffsets yOffsets] = meshgrid(xValues, yValues); 

%light sources

%make a circle of lights
%use 16 different radially symmetric lights for now
curPbrt.removeLight();
lightLocation = [ 5 -5 80];
light = pbrtLightSpotObject('lightLowerRight', [], [], [], lightLocation, [0 0 lightLocation-1]);
curPbrt.addLightSource(light);

%add a new material
matRGB= [1 1 1];
newMaterial = pbrtMaterialObject('grayMat', 'matte', pbrtPropertyObject('color Kd', matRGB));
curPbrt.addMaterial(newMaterial);

% remove default geometry
curPbrt.removeGeometry();
%add a backdrop
backDropTransform = ...
    [100*scaleFactor 0 0 0;
    0 100*scaleFactor 0 0 ;
    0 0 1 0;
    0 0 backDropDepth  1];
backDrop = pbrtGeometryObject(['sphere' int2str(i)], 'grayMat', [], [], backDropTransform);
curPbrt.addGeometry(backDrop);

%serialize the x and y values for easier looping
xOffsets = xOffsets(:);
yOffsets = yOffsets(:);

for i = 1:length(xOffsets)
    %add new geoemtry
    translateTransform = [scaleFactor 0 0 0;
        0 scaleFactor 0 0 ;
        0 0 scaleFactor 0;
        xOffsets(i) yOffsets(i) sphereDepths  1]; %8.87306690216     %x direction is to the right, y is into the screen, z is up
    newGeometry = pbrtGeometryObject(['sphere' int2str(i)], 'grayMat', pbrtShapeObject('sphere', 'radius', 1), [], translateTransform);
    curPbrt.addGeometry(newGeometry);
end

tmpFileName = ['deleteMe' '.pbrt'];
curPbrt.writeFile(tmpFileName);
lowerRightOi = s3dRenderOI(curPbrt, .050, tmpFileName);

%% Render Lower Left Flash Oi

%light sources
curPbrt.removeLight();
lightLocation = [-5 -5 80];
light = pbrtLightSpotObject('lightLowerLeft', [], [], [], lightLocation, [0 0 lightLocation + flashSeparation - 1]);
curPbrt.addLightSource(light);

tmpFileName = ['deleteMe' '.pbrt'];
curPbrt.writeFile(tmpFileName);
lowerLeftOi = s3dRenderOI(curPbrt, .050, tmpFileName);

%% Render Upper Right Flash Oi

%light sources
curPbrt.removeLight();
lightLocation = [5 5 80];
light = pbrtLightSpotObject('lightUpperRight', [], [], [], lightLocation, [0 0 lightLocation + flashSeparation - 1]);
curPbrt.addLightSource(light);

tmpFileName = ['deleteMe' '.pbrt'];
curPbrt.writeFile(tmpFileName);
upperRightOi = s3dRenderOI(curPbrt, .050, tmpFileName);

%% Render Upper Left Flash Oi

%light sources
curPbrt.removeLight();
lightLocation = [-5 5 80];
light = pbrtLightSpotObject('lightUpperLeft', [], [], [], lightLocation, [0 0 lightLocation + flashSeparation - 1]);
curPbrt.addLightSource(light);

tmpFileName = ['deleteMe' '.pbrt'];
curPbrt.writeFile(tmpFileName);
upperLeftOi = s3dRenderOI(curPbrt, .050, tmpFileName);


%% render depth map

%change the sampler to stratified for non-noisy depth map
samplerProp = pbrtPropertyObject();
curPbrt.sampler.setType('stratified');
curPbrt.sampler.removeProperty();
curPbrt.sampler.addProperty(pbrtPropertyObject('integer xsamples', '1'));
curPbrt.sampler.addProperty(pbrtPropertyObject('integer ysamples', '1'));
curPbrt.sampler.addProperty(pbrtPropertyObject('bool jitter', '"false"'));

%write file and render
tmpFileName = ['deleteMe'  '.pbrt'];
curPbrt.writeFile(tmpFileName);
groundTruthDepthMap = s3dRenderDepthMap(tmpFileName, 1);
figure; imagesc(groundTruthDepthMap);

%% normal vectors

[normalVector scaledNormal] = s3dCalculateNormals(groundTruthDepthMap, fieldOfView);
vcNewGraphWin; imshow(scaledNormal );

%% front flash image processing
% %load oi from file (optional)
% % vcLoadObject('opticalimage', ['50mmFront.pbrt.mat']);
% % oi = vcGetObject('oi');
% 
% % backOi = oi;
% 
% % sensor processing
% sensor = s3dProcessSensor(frontOi, 0, [400 400],0, 'analog');    %low noise, auto exposure
% % sensor = s3dProcessSensor(oi, .0096, [], .03);     %high noise
% vcAddAndSelectObject('sensor',sensor); sensorImageWindow;
% 
% % image processing
% vciFlash = s3dProcessImage(sensor);
% vcAddAndSelectObject(vciFlash); vcimageWindow;
% 
% %% back flash image processing
% %load oi from file
% % vcLoadObject('opticalimage', ['50mmBack.pbrt.mat']);
% % oi = vcGetObject('oi');
% 
% % sensor processing
% frontFlashExpDur = sensorGet(sensor, 'expTime');
% sensor = s3dProcessSensor(backOi, 0, [400 400],frontFlashExpDur, 'analog');    %low noise
% % sensor = s3dProcessSensor(oi, .0096, [], .03);     %high noise
% vcAddAndSelectObject('sensor',sensor); sensorImageWindow;
% 
% % image processing
% vciFlashBack = s3dProcessImage(sensor);
% vcAddAndSelectObject(vciFlashBack); vcimageWindow;
% 