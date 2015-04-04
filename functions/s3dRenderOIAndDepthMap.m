function oi = s3dRenderOIAndDepthMap(pbrt, focalLength, oiName, dockerFlag)
%This function renders an oi AND the depth map, given a pbrt object.
%
%   oi = s3dRenderOIAndDepthMap(pbrt, focalLength, oiName, dockerFlag)
%
%  pbrt:        The pbrt structure set up elsewhere
%  focalLength: In millimeters of the lens assumed in the oi
%  oiName:      Output name of the oi
%  dockerFlag:  Run as a docker container from docker hub.
%
% See also:  s_s3dRenderHDRBenchLF.m
%
% AL, VISTASOFT, 2014

%% Input argument checking
if (ieNotDefined('dockerFlag'))
    dockerFlag = false;
end
if (ieNotDefined('oiName'))
    oiName = 'unamedScene';
end
if (ieNotDefined('focalLength'))
    % This is needed for rendering.  But we can change this when we get the
    % oi returned with an oiSet(oi,'optics focal length',val)
    focalLength = 0.050; %default focal length in meters
end

%%
if (isa(pbrt, 'pbrtObject'))
    %% render oi irradiance
    
    %Must make a copy because the docker container will overwrite the
    %object.
    radianceRenderPbrt = pbrtObject;
    radianceRenderPbrt.makeDeepCopy(pbrt);
    
    oi = s3dRenderOI(radianceRenderPbrt, focalLength, oiName, dockerFlag);
    
    %% Render Depth map
    %change the sampler to stratified for non-noisy depth map
    depthRenderPbrt = pbrtObject; depthRenderPbrt.makeDeepCopy(pbrt);
    groundTruthDepthMap = s3dRenderDepthMap(depthRenderPbrt, 1, oiName, dockerFlag);
    oi = sceneSet(oi, 'depthmap', groundTruthDepthMap);
elseif (ischar(pbrt))
    % Renders from a pbrt text file
    oi = s3dRenderOI( pbrt, focalLength, oiName, dockerFlag);
    
    [directory, fileName, extension] = fileparts(pbrt);
    %depth map pbrt file must have a _depth appended to name
    depthPbrtFile = fullfile(directory, [fileName '_depth', extension]);
    groundTruthDepthMap = s3dRenderDepthMap(depthPbrtFile, 1, oiName, dockerFlag);
    oi = sceneSet(oi, 'depthmap', groundTruthDepthMap);
else
    error('invalid inputPbrt type.  Must be either a character array of the pbrt file, or a pbrtObject');
end

end