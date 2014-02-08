%% output = s3dRenderDepthMap(fname)
%
% Returns the ground truth depth map from given fname 
% (relative to s3droot/scripts/pbrtFiles/)
% fname must correspond to the pbrt file whose scene's depth map will be
% rendered.  **Note that the number of pixel samples here must be set to 1,
% and the number of reflections must be set to 0.

% This function works by rendering lots of 1 sample pbrt scenes, and taking
% the median value of those rendered depth maps, to create one that is of
% high quality.  There is some discussion of whether or not this produces a
% valid depth map, but for all intensive purposes, it is close enough.
function output = s3dRenderDepthMap(fullfname, numRenders)
    if (ieNotDefined('fullfname')) || ~exist(fullfname,'file')
        error('PBRT full file name required.');
    end
    if (ieNotDefined('numRenders'))
        numRenders = 31;
    end
    pbrtExe = fullfile(pbrtRootPath, 'src','bin','pbrt');
    if ~exist(pbrtExe,'file')
        error('PBRT executable not found');
    end
    
%     chdir(fullfile(s3dRootPath, 'scripts', 'pbrtFiles'));


    % Make a tempPBRT directory where the output files will go
    generatedDir = fullfile(dataPath, 'generatedPbrtFiles', 'tempPBRT');
    if exist(generatedDir,'dir')
        unix(['rm ' generatedDir]);
    else
        mkdir(generatedDir);
    end
    outfile  = fullfile(generatedDir, 'temp_out.dat');
%     mkdir('tempOutput');
%     chdir('tempOutput');
    
    
    outfile = 'tempPBRT/depthRender_out.dat';
    dMapFile = 'tempPBRT/depthRender_out_DM.dat';

    for i = 1:numRenders
        cmd = sprintf('%s %s --outfile %s',pbrtExe,fullfname,outfile);
        unix(cmd);
%         unix([fullfile(pbrtHome, '/src/bin/pbrt ') fullfname ' --outfile ' outfile]);
        if (i ==1)
            oi = pbrt2oi(outfile);
            imageHeight = oiGet(oi, 'rows');
            imageWidth = oiGet(oi, 'cols');
            depthMap = zeros(imageHeight, imageWidth, numRenders);
        end
        depthMap(:,:, i) = s3dReadDepthMapFile(dMapFile, [imageHeight imageWidth]);
%         unix('rm *');
    end

    depthMapProcessedMedian = median(depthMap, 3);
    output = depthMapProcessedMedian;
end