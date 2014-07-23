function oi = estimatePSF(obj,nLines, jitterFlag)
% Estimate the PSF of a psfCamera
%
%   oi = psfCamera.estimatePSF(obj)
%
% The camera has a point source, lens, and film.
%
% Returns the optical image of the film
%
% AL/BW Vistasoft Team, Copyright 2014

if ieNotDefined('nLines'),     nLines = false;     end
if ieNotDefined('jitterFlag'), jitterFlag = false; end

% Trace from the point source to the entrance aperture of the
% multielement lens
ppsfCFlag = true;
obj.rays = obj.lens.rtSourceToEntrance(obj.pointSource, ppsfCFlag, jitterFlag);

% Duplicate the existing rays for each wavelength
% Note that both lens and film have a wave, sigh.
% obj.rays.expandWavelengths(obj.film.wave);
obj.rays.expandWavelengths(obj.lens.wave);

%lens intersection and raytrace
obj.lens.rtThroughLens(obj.rays, nLines);

% Something like this?  Extend the rays to the film plane?
% if nLines > 0; obj.rays.draw(obj.film); end

% intersect with "film" and add to film
obj.rays.recordOnFilm(obj.film);

% Create an oi. (Needed so that oi can be returned as stated from function
% contract. AL)
oi = obj.oiCreate();
end