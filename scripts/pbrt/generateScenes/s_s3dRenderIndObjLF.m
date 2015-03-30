%% Runs PBRT and imports it in ISET for the bench scene. 
% TODO: incorporate this into 1 main script, or generalize/organize it

%%
ieInit

%% render scene with PBRT using pbrtObjects (front flash)
tic

%initialization
clear curPbrt;
curPbrt = pbrtObject();

% Specify scene properties files
matFile = fullfile(dataPath, 'twoFlashDepth', 'indObject', 'pbrt', 'default-mat.pbrt');
geoFile = fullfile(dataPath, 'twoFlashDepth', 'indObject', 'pbrt', 'default-geom.pbrt');

% light properties
spectrum = pbrtSpectrumObject('rgb I', [1000 1000 1000]);
lightFrom = [  -56.914787 -105.385544 35.0148];  % Position of source
lightTo = [-56.487434 -104.481461 34.8  ];       % Direction of principal ray
coneAngle = 180;         % Angle of rays from light source
coneDeltaAngle = 180;    % Drop off of illumination???
lightSource = pbrtLightSpotObject('light', spectrum, coneAngle, coneDeltaAngle, lightFrom, lightTo);  
%lightSpotObject(inName, inSpectrum, inConeAngle, inDeltaAngle, inFrom, inTo)

%% camera properties
from = [ -56.914787 -105.385544 35.0148];
to = [-56.487434 -104.481461 34.8 ];
position = [from; to; 0 0 1];
curPbrt.camera.setPosition(position);

%lens = pbrtLensPinholeObject();
%filmDistance = 140;
%filmDiag = 50.9117;
%curPbrt.camera.setLens(pbrtLensPinholeObject(filmDistance, filmDiag));  %TODO: may want to switch to a real lens later
%curPbrt.camera.setResolution(300, 300);

%% add old parts, put in new ones
% Candidate for a function
curPbrt.removeMaterial();
curPbrt.addMaterial(matFile);
curPbrt.removeGeometry();
curPbrt.addGeometry(geoFile);
curPbrt.removeLight();
curPbrt.addLightSource(lightSource);

% set sampler
curPbrt.sampler.removeProperty();
nSamples = 32; %512;
curPbrt.sampler.addProperty(pbrtPropertyObject('integer pixelsamples', nSamples));

%% setup the lightfield camera properties

numPinholesW = 80;  %these 2 parameters must be even (for now)
numPinholesH = 80;

filmDist = 72; %40; %36.77; mm from the back of the lens
filmDiag = 30; % Sensor diagonal size

% Lens propertiess
specFile = 'dgauss.50mm.dat';  % The lens file
% specFile = '2ElLens.dat';
apertureDiameter = 16;
diffraction = false;
chromaticAberration =false;

%assign pinhole position to PBRT, and figure out correct cropWindow
lens = pbrtLensRealisticObject(filmDist, filmDiag, ...
    specFile, apertureDiameter, ...
    diffraction, chromaticAberration, [], [], [], ...
    numPinholesW, numPinholesH);

curPbrt.camera.setLens(lens);
curPbrt.camera.setResolution(720, 720);

%% TODO
% Create a method of writing out a summary table of the curPbrt structure
%

%% write file and render
focalLength = 0.050;   % In meters
sceneName = [];
dockerFlag = true;
oi = s3dRenderOIAndDepthMap(curPbrt,focalLength,sceneName,dockerFlag);
vcAddObject(oi); oiWindow;

%% END