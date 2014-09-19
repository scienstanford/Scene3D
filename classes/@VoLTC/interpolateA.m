function [ AInterp, A1stInterp, A2ndInterp ] = interpolateA(obj, wantedPSLocation, wantedWavelength )
% Interpolate the A matrices to the specified locations
%
% The three different matrices (all the way, front to middle, middle to
% exit) are all returned
%
% The positions and wantedPSLocations are (x,y,z) locations.  We really
% only use the (y,z) values.  Let's think about that.
%
% For now - we will assume that x coordinates are 0 and interpolation can
% only be done on the y axis and depth.  TODO: allow for rotations for
% anything out of this plane.
%
% This is going to be the basis of the 'get' part of the VOLT class, when
% we return an interpolated linear transformation
%
% AL VISTASOFT 2014

%% parameter testing
if (ieNotDefined('wantedWavelength')), wantedWavelength = 550; end
    
%% Interpolate the three types of A matrices

AInterp = zeros(4,4);
A1stInterp = zeros(4,4);
A2ndInterp = zeros(4,4);

AComplete = obj.get('ACollection');
A1stComplete = obj.get('A1stCollection');
A2ndComplete = obj.get('A2ndCollection');

% [x,y,z] = obj.get('ps locations')
%  w = obj.get('wave')

numDepths = obj.get('numDepths');
numPositions = obj.get('numFieldPositions');
numWaves = length(obj.get('wave'));
pSY = obj.get('fieldPositions');
pSZ = obj.get('depths');
pSW = obj.get('wave');
[meshZ, meshY, meshW] = meshgrid(pSZ , pSY, pSW);

% Could we do a single interp, instead of a separate one for every entry?
% for fp
%     for depths
%         for wave
%             this() = [fp,depth,wave]
%             allCoefs = [allCoef,coef(:)]
%         end
%     end
% end
% 


for i = 1:4
    for j = 1:4
        coefValues = AComplete(i,j,:,:,:);
        %coefValues dimensions: (1,1, #fieldPositions, #depths, #wavelengths);
        %coefValues = reshape(coefValues, numDepths, numPositions, numWaves);
        coefValues = squeeze(coefValues); 
        yi = interp3(meshZ,meshY,  meshW, coefValues, wantedPSLocation(3),wantedPSLocation(2),  wantedWavelength);
        AInterp(i,j) = yi;
        
        coefValues = A1stComplete(i,j,:,:,:);
        %coefValues = coefValues(:);
        %coefValues = reshape(coefValues, numDepths, numPositions, numWaves);
        coefValues = squeeze(coefValues); 
        yi = interp3(meshZ,meshY,  meshW, coefValues, wantedPSLocation(3), wantedPSLocation(2), wantedWavelength);
        A1stInterp(i,j) = yi;
        
        coefValues = A2ndComplete(i,j,:,:,:);
        %coefValues = coefValues(:);
        %yi = interp1(pSY,coefValues, wantedPSLocation);
       % coefValues = reshape(coefValues, numDepths, numPositions, numWaves);
        coefValues = squeeze(coefValues);
        yi = interp3( meshZ,meshY, meshW, coefValues, wantedPSLocation(3), wantedPSLocation(2),  wantedWavelength);
        A2ndInterp(i,j) = yi;
    end
end   

end

