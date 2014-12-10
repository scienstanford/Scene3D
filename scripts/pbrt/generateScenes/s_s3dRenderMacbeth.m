%% Render Scene Radiance Using pbrtObjects
for i = 1:14
    
    clear curPbrt;
    curPbrt = pbrtObject();
    
    %camera position
    newCamPos =    [0  0 0;
        0   0 -1;
        0 1.00000 0];
    curPbrt.camera.setPosition(newCamPos);
    curPbrt.camera.lens.filmDistance = 133.33;
    curPbrt.camera.lens.filmDiag = 70;
    
    scaleFactor = 4;
    % curPbrt.camera.setResolution(100, 100);    %LQ mode
    
    %uncomment to use a 2 element lens instead of a pinhole
    % curPbrt.camera.setLens(fullfile(s3dRootPath, 'data', 'lens', '2ElLens50mm.pbrt'));
    
    %sampler
    sampler = curPbrt.sampler.removeProperty();
    sampler.value = 2048 * 4;
    curPbrt.sampler.addProperty(sampler);
    
    %backdrop Depth
    % backDropDepth = -100 * scaleFactor;  %backdrop distance increases with depth of spheres
    backDropDepth = -160;
    foregroundDepth = -80;
    foregroundDepth2 = -70;
    foregroundDepth3= -90;
    
    
    %calculate sphere offsets
    xValues = linspace(-2.5*scaleFactor, 2.5*scaleFactor, 6);
    yValues = linspace(-1.5*scaleFactor, 1.5*scaleFactor, 4);
    [xOffset yOffset] = meshgrid(xValues, yValues);
    
    
    
    lightSpectrumFile = fullfile(s3dRootPath, 'papers', 'ReflectanceAndDepth', 'Illuminant.mat');
    [lights,wave,comment,fName]  = ieReadSpectra(lightSpectrumFile, 400:10:700, []);
    lights = Energy2Quanta(wave, lights); %convert to photons
    
    %res is returned as a 31 x 14 matrix, where it's rows: wavelength and cols:
    %light source
    
    
    
    % lightRight = pbrtLightSpotObject('rightLight', [], [], [], inFrom, inTo);
    % curPbrt.removeLight();
    curPbrt.removeLight();
    
    spectrum = lights(:, i)';
    %spectrum = ones(size(spectrum));  %temp debug
    tempMatrix = [400:10:700; spectrum];  %helps put data in 400 1 500 .5 600 .5 700 1 format
    spectrumObject = pbrtSpectrumObject('spectrum I', tempMatrix(:));
    
    
    lightFront = pbrtLightSpotObject(['light' int2str(i)], spectrumObject, [], [], [0 0 80], [0 0 -79]);
    curPbrt.addLightSource(lightFront);
    
    
    
    %add a new material
    matRGB= [400 1 500 1 600 1 700 1 ];
    newMaterial = pbrtMaterialObject('grayMat', 'matte', pbrtPropertyObject('spectrum Kd', matRGB));
    curPbrt.addMaterial(newMaterial);
    
    %add material file
    curPbrt.addMaterial(fullfile(s3dRootPath, 'data', 'materials', 'simpleTarget-mat.pbrt'));
    
    % remove default geometry
    curPbrt.removeGeometry();
    %add a backdrop
    backDropTransform = ...
        [50 0 0 0;
        0 50 0 0 ;
        0 0 1 0;
        0 0 backDropDepth  1];
    backDrop = pbrtGeometryObject('backdrop', 'Material', [], [], backDropTransform);
    curPbrt.addGeometry(backDrop);
    
    
   
    
    %read macbeth color checker refletance values
    macbethSpectrumFile = fullfile(isetRootPath, 'data', 'surfaces', 'macbethChart.mat');
    [reflectances,wave,comment,fName]  = ieReadSpectra(macbethSpectrumFile, 400:10:700, []);
    
    
    %add new material for macbeth color checker reflectances
    for index = 1:24
        spectrum= [wave;
                   reflectances(:, index)'];
        spectrumObject = pbrtPropertyObject('spectrum Kd', spectrum(:));
        newMaterial = pbrtMaterialObject(['macbeth' int2str(index)], 'matte', spectrumObject);
        curPbrt.addMaterial(newMaterial);
    end
    
    
    for ii = 1:6
        for jj = 1:4
            %add a foreground target
            foregroundTransform = ...
                [2 0 0 0;
                0 2 0 0 ;
                0 0 1 0;
                xOffset(jj,ii) yOffset(jj,ii) foregroundDepth  1];
            
            frontSquare = pbrtGeometryObject(['checker' int2str(ii) int2str(jj)], ['macbeth' int2str(3 -(jj -1) + (ii-1) * 4 + 1)], [], [], foregroundTransform);
            frontSquare = pbrtGeometryObject(['checker' int2str(ii) int2str(jj)], ['graymat'], [], [], foregroundTransform);

            curPbrt.addGeometry(frontSquare);
        end
    end
    
    % xOffsets = xOffsets(:);
    % yOffsets = yOffsets(:);
    % for i = 1:length(xOffsets)
    %     %add new geoemtry
    %     translateTransform = [scaleFactor 0 0 0;
    %         0 scaleFactor 0 0 ;
    %         0 0 scaleFactor 0;
    %         xOffsets(i) yOffsets(i) sphereDepths  1]; %8.87306690216     %x direction is to the right, y is into the screen, z is up
    %     newGeometry = pbrtGeometryObject(['sphere' int2str(i)], 'grayMat', pbrtShapeObject('sphere', 'radius', 1), [], translateTransform);
    %     curPbrt.addGeometry(newGeometry);
    % end
    
    tmpFileName = ['deleteMe' '.pbrt'];
    curPbrt.writeFile(tmpFileName);
    noScale = true;
    scene = s3dRenderScene( curPbrt, 'simpleScene', noScale);
    
    %% Render Depth map

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

    scene = sceneSet(scene, 'depthmap', groundTruthDepthMap);
    scene = sceneSet(scene, 'name', ['light' int2str(i)]);
    vcAddObject(scene); sceneWindow;
end