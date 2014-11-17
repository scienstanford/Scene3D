function [LFin] = s3dLightFieldEntranceApodize(pointSource, lens, depthMap)
% Create a light field object for the input (point source) and lens
%
%
% General idea of this function:
%
% This function performs the same function as s3dLightFieldEntrance, except
% that it allows for the proper rendering of partially occluded regions,
% assuming that we have the proper information in those regions.

% For each ray that is shot at the aperture, we will project that ray onto
% the x-y plane.  For sampled places on this ray, we will compare and see
% if the ray is greater than or less than the depth of the scene.  If it is
% further from the scene than the depth, then that particular ray is
% occluded.
%
% The amount of sampling is important because we can potentially miss
% crucial parts of the scene if we sample too coursely.
%
% LF = s3dLightFieldApodize(pointSource, lens, depth)
%
% pointSOurce:
% lens
% film
%
% LF:  Light field object
%
% Example:
%  lens = lensC; pointSource = [0 1.7 -103];
%  [LFout, LFmid, LFin] = s3dLightField(pointSource, lens);
%
% See Also:
%
% AL, VISTASOFT, 2014

%% ray trace and save ppsf - Not sure camera should have pointSources

% Use the multi element lens and film and a point source.  Combine into
% a camera that calculates the point spread function.
film = pbrtFilmC;

ppsfCamera = ppsfCameraC('lens', lens, 'film', film, 'pointSource', pointSource);

% Plenoptic point spread calculated with Snell's Law
% change this function here. 
% we need a ppsfCamera.traceToEntrance(0, true, depthMap);

ppsf = ppsfCamera.traceToEntrance(0, true);  %0 debug lines; jitter set to true


%% Calculate light fields
    
LFin  = ppsf.LF('in');

end
