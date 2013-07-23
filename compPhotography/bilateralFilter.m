function newImage = bilateralFilter(inputImage, sigmaS, sigmaI, kernelSize, padding)
% performs the bilateral filter, using inputImage, simgaS, sigmaI, and kernelSize
% inputImage: the input image of interest
% sigmaS: spatial standard deviation
% sigmaI: intensity standard deviation for edge retention
% kernelSize: the size of the sliding window
% 
% For boundary cases, the window size changes to be constrained to the boundary of the image. 
% We assume that inputImage only has 1 value per pixel.


%correct for NaN boundary problems

if (ieNotDefined('padding'))
    padding = 1;
end

inputImage(isnan(inputImage)) = 0;

imageWidth = size(inputImage, 2);
imageHeight = size(inputImage, 1);
newImage = zeros(imageHeight, imageWidth);
colNumberImage = repmat(1:imageWidth, [imageHeight 1]);
rowNumberImage = repmat((1:imageHeight)', [1 imageWidth]);

for j = 1 + padding:imageHeight - padding
    for i = 1 + padding:imageWidth - padding
        if (i == 290 && j == 243)
            disp('at debug position')
        end
        totalWeight = 0;
        currentValue = inputImage(j,i);
        weightedValue = 0;
        
        %these patches speed up the bilateral filter by allowing the 2
        %inner loops to be done using matrix operations which are much more
        %efficient.  See below for the original, slow, looping version.
        %we can speed this up even more using FFT (Durand, Dorsey 2002)
        intensityPatch = inputImage(max(j-kernelSize, 1):min(j+kernelSize, imageHeight), max(i-kernelSize, 1):min(i+kernelSize, imageWidth));
        rowPatch = rowNumberImage(max(j-kernelSize, 1):min(j+kernelSize, imageHeight), max(i-kernelSize, 1):min(i+kernelSize, imageWidth));
        columnPatch = colNumberImage(max(j-kernelSize, 1):min(j+kernelSize, imageHeight), max(i-kernelSize, 1):min(i+kernelSize, imageWidth));
        spatialDistancePatch = sqrt((rowPatch - j).^2 + (columnPatch - i).^2);
        
        spatialWeight = gaussian(spatialDistancePatch, 0, sigmaS);
        intensityWeight = gaussian(intensityPatch, currentValue, sigmaI);
        totalWeight = spatialWeight .* intensityWeight;
        
        weightedValue = totalWeight .*intensityPatch;
        newImage(j,i) = sum(weightedValue(:))/sum(totalWeight(:));
        
        %this is the slow version, which is much more intuitive
        % for jj = max(j-kernelSize, 1):min(j+kernelSize, imageHeight)
        %     for ii = max(i-kernelSize, 1):min(i+kernelSize, imageWidth)
        %         spatialWeight = gaussian(sqrt((ii - i) ^2 + (jj-j)^2), 0, sigmaS);
        %         intensityWeight = gaussian(inputImage(jj,ii), currentValue, sigmaI);
        %         currentWeight = spatialWeight * intensityWeight;
        %         totalWeight = totalWeight + currentWeight;
        %         weightedValue = weightedValue + currentWeight * inputImage(jj,ii);
        %     end
        % end
        %weightedValue = weightedValue/totalWeight; 
        %newImage(j,i) = weightedValue;
    end
end
    

end


function weight = gaussian(x, mu, sigma)
%returns the gaussian weight depending on x, mu, and sigma
    weight = exp(-(x - mu).^2./ (2 * sigma.^2));
end