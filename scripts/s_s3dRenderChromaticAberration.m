% Runs PBRT and imports it in ISET for a test point.  This one tries to
% produce a high quality rendering, with chromatic abberation. 
%% PBRT will run the PBRT script
chdir(fullfile(s3dRootPath, 'scripts', 'pbrtFiles'));

% list of all chromatic aberration renderings - uncomment and run the one
% you wish to run

% slanted bar rendering
unix([fullfile(pbrtHome, '/src/bin/pbrt') ' chromaticAberration.pbrt']);

% radial lines rendering
%unix([fullfile(pbrtHome, '/src/bin/pbrt') ' chromaticAberrationRadial.pbrt']); 



%% ISET will read the PBRT output
% scene = sceneSet(scene,'fov', 8);
oi = pbrt2oi('output_d.dat');
% oi = oiSet (oi, 'horizontalfieldofview', 8 * 200/150 );
vcAddAndSelectObject(oi);
oiWindow;

m = oiGet(oi, 'mean illuminance')
unix('cd ..');
