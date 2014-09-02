%% ray-tracing for realistic lens - PPSF
%
% Towards a volume of linear transforms (volt)
%
% Check why we have a discontinuity at (0,0).  Something about the 0 always
% mapping to 0, or something ...
%
% Lens element positions are all negative, and the final exit plan can be
% considered as z = 0
%
%  This uses Snell's law and a lens prescription to create a tray trace.
%  The script is too long, and we need to start writing functions so that
%  the length is shortened and the clarity increased.
%  We are only ray-tracing ideal point sources in order to extract out point
%  spread functions.
%
%  We are also experimenting with the plenoptic point spread function
%  (PPSF).  this is a very early experiment, where we are splitting the
%  calculation into 2 steps.  The first step traces the rays from a single
%  point in the scene towards the lens.  Ray-tracing is performed through
%  the lens, and out the back aperture.  At this point, the rays may be
%  saved as data.  Next, the rays are traced from the end of the lens to
%  the sensor (this process is reasonably efficient and doesn't take much
%  time).  Using this format, differrent sensor depths may be used to
%  access the PSF.
%
%  This specific script renders 2 PPSFs at a set field position , but with
%  different depths.  We attempt to interpolate a PPSF for a
%  position half-way between these 2, and check the results with the ground
%  truth.
%
% AL Vistalab, 2014
%%
s_initISET

%% loop through different point source positions
pSLocations = 0.01:.3:2;
pSZ = -100;
%pSLocations = -1*(50:20:160);

AComplete = zeros(4, 4, length(pSLocations));

%% lens properties
% diffractionEnabled = false;
%turning on diffraction does NOT make sense yet since we have not modeled
%the transformation of uncertainty from the middle aperture to the end of the lens

%TODO: add diffraction into this somehow
%      Create a function lens.write() that makes a file from a lens
%      object.

%initialize and read multi-element lens from file
% lensFileName = fullfile(s3dRootPath,'data', 'lens', 'dgauss.50mm.dat');

lensFileName = fullfile(s3dRootPath,'data', 'lens', '2ElLens.dat');

nSamples = 151;
apertureMiddleD = 10;   % mm
lens = lensC('apertureSample', [nSamples nSamples], ...
    'fileName', lensFileName, ...
    'apertureMiddleD', apertureMiddleD);

%2 element lens
% lensFile = fullfile(s3dRootPath, 'data', 'lens', '2ElLens.mat');
% import = load(lensFile,'lens');
% thickLens = import.lens;
% thickLens.apertureMiddleD = 10;

for pSIndex = 1:length(pSLocations)

    close all;
    pSLocation = pSLocations(pSIndex);

    %% film (sensor) properties
    % position - relative to center of final lens surface
    % size - 'mm'
    % wavelength samples

    film = pbrtFilmC('position', [0 0 100 ], ...
        'size', [10 10], ...
        'wave', 400:50:700);

    %lens illustration - very small aperture in the middle
    % lens.draw();

    %% point sources (units are mm)

    % TODO:  Point in the psCreate here ..

    % Millimeters from last surface.  Always at least the lens thickness
    % away.
    pointSourceDepth = 100;   % What is happening when 10,000?
    pointSourceDepth = max(pointSourceDepth,-(lens.get('totaloffset')+1));
    % pointSources = [ pSLocation pSLocation -pointSourceDepth];  %large distance test
    pointSources = [ 0 pSLocation pSZ];  %large distance test

    pointSourceFieldHeight = 0;
    % pointSources = [ 0 0 -60];  %short distance test

    %% ray trace and save ppsf - Not sure camera should have pointSources

    % Use the multi element lens and film and a point source.  Combine into
    % a camera that calculates the point spread function.
    ppsfCamera = ppsfCameraC('lens', lens, 'film', film, 'pointSource', pointSources);

    %%
    nLines =  100;  % Draw the ray trace if nLines > 0
    ppsf = ppsfCamera.estimatePPSF(nLines);

    %% Record on film
    ppsfCamera.recordOnFilm();

    % Bring up the pointspread in an optics window
    oi = ppsfCamera.oiCreate;
    vcAddObject(oi); oiWindow;
    plotOI(oi,'illuminance mesh log');

    %% Calculate light field at the entrance pupil plane and exit pupil - estimate the linear transform

    % do we need to put this in terms of angles? or are direction using
    % cartesian coordinates good enough?
    % put this into Ax = b form

    % x will be a 4 x numSamples matrix containing the input lightfield
    % b will be a 4 x numSamples matrix containing the output lightfield
    % A will be the 4 x 4 least squares fit for this transformation

    % Light field representation of the (x,y) positions in the entrance pupil
    % of just those rays that actually make it to the film. There is a nan in
    % the value when the ray does not make it.
    %
    cAEntranceXY = ppsf.aEntranceInt.XY';   % 2 x nSamples_in_aperture x nWave

    % Eliminate nans
    survivedRays = ~isnan(cAEntranceXY(1,:));
    cAEntranceXY = cAEntranceXY(:, survivedRays);

    % This is the effective aperture
    vcNewGraphWin;
    whichElement = 1;
    r = lens.get('sdiameter',whichElement)/2; [x,y] = circlePoints([],r); plot(x,y,'.');
    hold on; plot(cAEntranceXY(1,:),cAEntranceXY(2,:),'o'); axis equal
    grid on
    title(sprintf('Entrance points that make it to the exit'));

    % Matrix of directions at entrance pupil.  This is 3 x nExitRays
    % Write this: lf = ppsf.get('entrance lf')
    %
    % This direction is an (x,y,z) vector
    entDirMatrix = ...
        [cAEntranceXY(1, :) - ppsf.pointSourceLocation(1);
        cAEntranceXY(2, :) - ppsf.pointSourceLocation(2);
        ppsf.aEntranceInt.Z * ones(size(cAEntranceXY(1,:))) - ppsf.pointSourceLocation(3)];
    entDirMatrix = normvec(entDirMatrix, 'dim', 1);

    % Here we have (x,y,z) positions in the entrace aperture.
    % We also have the first two entries of the unit length vector direction of
    % the ray.  Maybe we want the two angles of that ray.
    % x = [cAEntranceXY(1,:);
    %     cAEntranceXY(2,:);
    %     ppsf.aEntranceInt.Z * ones(size(cAEntranceXY(1,:)));
    %     entDirMatrix(1, :);
    %     entDirMatrix(2,:)];
    x = [cAEntranceXY(1,:);
        cAEntranceXY(2,:);
        entDirMatrix(1, :);
        entDirMatrix(2,:)];

    % Distribution of one of the angles 
    vcNewGraphWin;
    hist(entDirMatrix(1,:),100);

    %% All the ray directions from a common point
    vcNewGraphWin;
    nPoints = size(x,2);
    if nPoints > 1000, s = randi(nPoints,[500,1]);
    else              s = 1:nPoints;
    end
    z = zeros(1,length(s));
    line([z;x(1,s)+x(3,s)],[z;x(2,s)+x(4,s)],[z;x(3,s)+entDirMatrix(3,s)])
    view([20 58])
    title(sprintf('%i distance\n%i samples\n%.1f aperture',pointSourceDepth,nSamples,apertureMiddleD))
    set(gca,'xlim',[-10 10],'ylim',[-10,10],'zlim',[0 1.5]);

    % The directions from the actual aperture position
    % vcNewGraphWin;
    % line([x(1,:);x(1,:)+x(4,:)],[x(2,:);x(2,:)+x(5,:)],[x(3,:);x(3,:)+entDirMatrix(3,:)])
    % view([1 58])


    %% Compute exit lightfield
    cAExitXY = ppsf.aExitInt.XY';
    cAExitXY = cAExitXY(:, survivedRays);

    exitDirMatrix = ppsf.aExitDir';
    exitDirMatrix = exitDirMatrix(:, survivedRays);

    % b = [cAExitXY(1,:);
    %     cAExitXY(2,:);
    %     ppsf.aExitInt.Z * ones(size(cAExitXY(1,:)));
    %     exitDirMatrix(1, :);
    %     exitDirMatrix(2,:)];
    b = [cAExitXY(1,:);
        cAExitXY(2,:);
        exitDirMatrix(1, :);
        exitDirMatrix(2,:)];
    %%  We wonder about the linear relationship
    %  b = Ax
    % To solve, we would compute
    % A = b\x

    % A = (x'\b')';
    % bEst = A * x;

    A = b/x;
    bEst = A * x;

    % Scatter plot of positions
    for ii=1:4
        vcNewGraphWin; plot(b(ii,:),bEst(ii,:),'o');
        grid on;

        meanAbsError = mean(abs(bEst(ii,:) - b(ii,:)));
        averageAmp = mean(abs(b(ii,:)));
        meanPercentError = meanAbsError/averageAmp * 100
    end


    AComplete(:,:,pSIndex) = A;

end
% Can we interpret A?  Does it agree with MP's predict calculation from the
% method he uses?

% %% compare how A coefficients change 
% for i = 1:4
%     for j = 1:4
%         ASerial = AComplete(i,j, :);
%         ASerial = ASerial(:);
%         figure; plot(pSLocations, ASerial);
%     end
% end

%% Make an A movie

vcNewGraphWin; colormap(hot);
mn = min(AComplete(:));
mx = max(AComplete(:));
az = -37; el = 80;
% caxis([mn mx]);
for ii=1:size(AComplete,3)
    surf(AComplete(:,:,ii)); set(gca,'zlim',[mn mx/4])
    view(az,el);
    shading interp
    title(sprintf('%.2f',pSLocations(ii)));
    pause(0.5);
end
% [az el] = view;

%% Obtain an A given a pSLocation 

%desired pSLocation
wantedPSFieldHeight = 1.7;

AInterp = zeros(size(A));
for i = 1:4
    for j = 1:4   
        coefValues = AComplete(i,j,:);
        coefValues = coefValues(:);
        yi = interp1(pSLocations,coefValues, wantedPSFieldHeight);
        AInterp(i,j) = yi;
    end
end

%% Compute ground truth LF at the wanted Point source Field Height

%TODO : perhaps put this stuff in a function or script ?
    %% film (sensor) properties
    % position - relative to center of final lens surface
    % size - 'mm'
    % wavelength samples

    film = pbrtFilmC('position', [0 0 100 ], ...
        'size', [10 10], ...
        'wave', 400:50:700);

    %lens illustration - very small aperture in the middle
    % lens.draw();

    %% point sources (units are mm)

    % TODO:  Point in the psCreate here ..

    % Millimeters from last surface.  Always at least the lens thickness
    % away.
    pointSourceDepth = 100;   % What is happening when 10,000?
    pointSourceDepth = max(pointSourceDepth,-(lens.get('totaloffset')+1));
    % pointSources = [ pSLocation pSLocation -pointSourceDepth];  %large distance test
    pointSources = [ 0 wantedPSFieldHeight pSZ];  %large distance test

    pointSourceFieldHeight = 0;
    % pointSources = [ 0 0 -60];  %short distance test

    %% ray trace and save ppsf - Not sure camera should have pointSources

    % Use the multi element lens and film and a point source.  Combine into
    % a camera that calculates the point spread function.
    ppsfCamera = ppsfCameraC('lens', lens, 'film', film, 'pointSource', pointSources);

    %%
    nLines =  100;  % Draw the ray trace if nLines > 0
    
    ppsf = ppsfCamera.estimatePPSF(nLines);

    %% Record on film
    ppsfCamera.recordOnFilm();

    % Bring up the pointspread in an optics window
    oi = ppsfCamera.oiCreate;
    vcAddObject(oi); oiWindow;
    plotOI(oi,'illuminance mesh log');

    %% Calculate light field at the entrance pupil plane and exit pupil - estimate the linear transform

    % do we need to put this in terms of angles? or are direction using
    % cartesian coordinates good enough?
    % put this into Ax = b form

    % x will be a 4 x numSamples matrix containing the input lightfield
    % b will be a 4 x numSamples matrix containing the output lightfield
    % A will be the 4 x 4 least squares fit for this transformation

    % Light field representation of the (x,y) positions in the entrance pupil
    % of just those rays that actually make it to the film. There is a nan in
    % the value when the ray does not make it.
    %
    cAEntranceXY = ppsf.aEntranceInt.XY';   % 2 x nSamples_in_aperture x nWave

    % Eliminate nans
    survivedRays = ~isnan(cAEntranceXY(1,:));
    cAEntranceXY = cAEntranceXY(:, survivedRays);

    % This is the effective aperture
    vcNewGraphWin;
    whichElement = 1;
    r = lens.get('sdiameter',whichElement)/2; [x,y] = circlePoints([],r); plot(x,y,'.');
    hold on; plot(cAEntranceXY(1,:),cAEntranceXY(2,:),'o'); axis equal
    grid on
    title(sprintf('Entrance points that make it to the exit'));

    % Matrix of directions at entrance pupil.  This is 3 x nExitRays
    % Write this: lf = ppsf.get('entrance lf')
    %
    % This direction is an (x,y,z) vector
    entDirMatrix = ...
        [cAEntranceXY(1, :) - ppsf.pointSourceLocation(1);
        cAEntranceXY(2, :) - ppsf.pointSourceLocation(2);
        ppsf.aEntranceInt.Z * ones(size(cAEntranceXY(1,:))) - ppsf.pointSourceLocation(3)];
    entDirMatrix = normvec(entDirMatrix, 'dim', 1);

    % Here we have (x,y,z) positions in the entrace aperture.
    % We also have the first two entries of the unit length vector direction of
    % the ray.  Maybe we want the two angles of that ray.
    % x = [cAEntranceXY(1,:);
    %     cAEntranceXY(2,:);
    %     ppsf.aEntranceInt.Z * ones(size(cAEntranceXY(1,:)));
    %     entDirMatrix(1, :);
    %     entDirMatrix(2,:)];
    x = [cAEntranceXY(1,:);
        cAEntranceXY(2,:);
        entDirMatrix(1, :);
        entDirMatrix(2,:)];

    % Distribution of one of the angles 
    vcNewGraphWin;
    hist(entDirMatrix(1,:),100);

    %% All the ray directions from a common point
    vcNewGraphWin;
    nPoints = size(x,2);
    if nPoints > 1000, s = randi(nPoints,[500,1]);
    else              s = 1:nPoints;
    end
    z = zeros(1,length(s));
    line([z;x(1,s)+x(3,s)],[z;x(2,s)+x(4,s)],[z;x(3,s)+entDirMatrix(3,s)])
    view([20 58])
    title(sprintf('%i distance\n%i samples\n%.1f aperture',pointSourceDepth,nSamples,apertureMiddleD))
    set(gca,'xlim',[-10 10],'ylim',[-10,10],'zlim',[0 1.5]);

    % The directions from the actual aperture position
    % vcNewGraphWin;
    % line([x(1,:);x(1,:)+x(4,:)],[x(2,:);x(2,:)+x(5,:)],[x(3,:);x(3,:)+entDirMatrix(3,:)])
    % view([1 58])


    %% Compute exit lightfield
    cAExitXY = ppsf.aExitInt.XY';
    cAExitXY = cAExitXY(:, survivedRays);

    exitDirMatrix = ppsf.aExitDir';
    exitDirMatrix = exitDirMatrix(:, survivedRays);

    % b = [cAExitXY(1,:);
    %     cAExitXY(2,:);
    %     ppsf.aExitInt.Z * ones(size(cAExitXY(1,:)));
    %     exitDirMatrix(1, :);
    %     exitDirMatrix(2,:)];
    b = [cAExitXY(1,:);
        cAExitXY(2,:);
        exitDirMatrix(1, :);
        exitDirMatrix(2,:)];

    %plot phase space
    ppsf.plotPhaseSpace();
    
    %%  We wonder about the linear relationship
    %  b = Ax
    % To solve, we would compute
    % A = b\x

    % A = (x'\b')';
    % bEst = A * x;

    A = b/x;
    bEst = A * x;

    % Scatter plot of positions
    for ii=1:4
        vcNewGraphWin; plot(b(ii,:),bEst(ii,:),'o');
        grid on;

        meanAbsError = mean(abs(bEst(ii,:) - b(ii,:)));
        averageAmp = mean(abs(b(ii,:)));
        meanPercentError = meanAbsError/averageAmp * 100
    end
    
%% Calculate the same result, but using the interpolated A Matrix instead
    
    bEstInterp = AInterp * x;
    
    % calculate errors
    % Scatter plot of positions
    for ii=1:4
        vcNewGraphWin; plot(b(ii,:),bEstInterp(ii,:),'o');
        grid on;

        meanAbsError = mean(abs(bEstInterp(ii,:) - b(ii,:)));
        averageAmp = mean(abs(b(ii,:)));
        meanPercentError = meanAbsError/averageAmp * 100
    end

%% Plot phase space of linear interpolation model output
%this still needs to be debugged    


%find the z position of rays
zPos = ppsfCamera.film.position(3);

rayOrigin = zeros(3, size(bEstInterp, 2));
rayDir = rayOrigin;

rayOrigin(1,:) = bEstInterp(1,:);
rayOrigin(2,:) = bEstInterp(2,:);
rayOrigin(3,:) = 1 - bEstInterp(1,:).^2 + bEstInterp(2,:).^2;

rayDir(1,:) = bEstInterp(3,:);
rayDir(2,:) = bEstInterp(4,:);
rayDir(3,:) = 1 - rayDir(1,:).^2 + rayDir(2,:).^2;



calculatedRays = ppsfC('origin', rayOrigin', 'direction', rayDir');
calculatedRays.plotPhaseSpace();
%% Future development for modifying the rays.


% Make a second ppsf object
%     modifyRays = ppsfC();
%
%     % Take the ppsfRays from the first object, copy the properties of the
%     % ppsfRays into real data, not just a pointer to the data.
%     modifyRays.makeDeepCopy(ppsfCamera.ppsfRays);
%
%     % Trace the rays lens to sensor
%     modifyRays.recordOnFilm(ppsfCamera.film);

