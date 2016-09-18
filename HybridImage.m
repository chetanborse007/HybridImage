

function [] = HybridImage(imgPath1, imgPath2)
% DESCRIPTION: Algorithm to create a Hybrid image by blending low frequency
%              component of one image with high frequency component of 
%              another image.
% INPUT:       %imgPath1        Path of first image
%              %imgPath2        Path of second image
% OUTPUT:      Create and save Hybrid image alongwith its Gaussian and 
%              Laplacian Pyramid.

    % Initialise algorithm's tuning parameters
    standardResolution = [640 480];
    levels             = 10;
    cutoffFrequency    = 8;
    downsamplingFactor = 0.8;
    upsamplingFactor   = 1/downsamplingFactor;
    
    % Read both input images from the disk
    imgName1 = strsplit(imgPath1, './input/');
    imgName1 = strsplit(char(imgName1(2)), '.'); imgName1 = imgName1(1);
    imgName2 = strsplit(imgPath2, './input/');
    imgName2 = strsplit(char(imgName2(2)), '.'); imgName2 = imgName2(1);
    img1     = imread(imgPath1);
    img2     = imread(imgPath2);

    % Resize both images to given standard resolution
    img1 = imresize(img1, standardResolution);
    img2 = imresize(img2, standardResolution);

    % Use both images in RGB colorspace and normalise them.
    % 
    % Reason:
    %   Using color for both Low and High frequency components enhances 
    %   Hybrid image effect.
    img1 = im2double(img1);
    img2 = im2double(img2);

    % Increase the contrast of RGB image that contributes High frequency 
    % component.
    % 
    % Reason:
    %   Increasing the contrast of RGB image enhances Hybrid image effect.
    img2 = imadjust(img2, [.2 .3 0; .6 .7 1], []);

    % Align both images together so that algorithm produces better results.
    %transform = imregcorr(img2, img1, 'similarity');
    %img2      = imresize(imwarp(img2, transform), standardResolution);
    
    % Generate 'Gaussian' Pyramid for the first image (Low frequency component)
    GaussianPyramid = GeneratePyramid(img1, ...
                                      levels, ...
                                      downsamplingFactor, ...
                                      'Gaussian');
    %pyramid_img      = DisplayPyramid(GaussianPyramid, ...
    %                                  size(img1, 1), ...
    %                                  3, ...
    %                                  'Gaussian');

    % Reconstruct Low frequency component from the first image
    LowFrequency    = ReconstructPyramid(GaussianPyramid, ...
                                         cutoffFrequency, ...
                                         upsamplingFactor, ...
                                         'Low');
    LowFrequency    = imresize(LowFrequency, standardResolution);
    
    % Generate 'Laplacian' Pyramid for the second image (High frequency component)
    LaplacianPyramid = GeneratePyramid(img2, ...
                                       levels, ...
                                       downsamplingFactor, ...
                                       'Laplacian');
    %pyramid_img      = DisplayPyramid(LaplacianPyramid, ...
    %                                  size(img2, 1), ...
    %                                  3, ...
    %                                  'Laplacian');

    % Reconstruct High frequency component from the second image
    HighFrequency    = ReconstructPyramid(LaplacianPyramid, ...
                                          cutoffFrequency-4, ...
                                          upsamplingFactor, ...
                                          'High');
    HighFrequency    = imresize(HighFrequency, standardResolution);

    % Combine Low frequency component of the first image with High frequency 
    % component of the second image for creating a Hybrid image.
    hybrid_img = LowFrequency + HighFrequency;
    figure; imshow(hybrid_img);
    imwrite(hybrid_img, char(strcat('HybridImage_', imgName1, '_', imgName2, '.jpg')));
    
    % Generate 'Gaussian' Pyramid for a Hybrid image
    HybridGaussianPyramid  = GeneratePyramid(hybrid_img, ...
                                             cutoffFrequency, ...
                                             downsamplingFactor, ...
                                             'Gaussian');
    pyramid_img            = DisplayPyramid(HybridGaussianPyramid, ...
                                            size(img1, 1), ...
                                            3, ...
                                            'Gaussian');
    imwrite(pyramid_img, char(strcat('GaussianPyramid_', imgName1, '_', imgName2, '.jpg')));

    % Generate 'Laplacian' Pyramid for a Hybrid image
    HybridLaplacianPyramid = GeneratePyramid(hybrid_img, ...
                                             cutoffFrequency, ...
                                             downsamplingFactor, ...
                                             'Laplacian');
    pyramid_img            = DisplayPyramid(HybridLaplacianPyramid, ...
                                            size(img2, 1), ...
                                            3, ...
                                            'Laplacian');
    imwrite(pyramid_img+0.5, char(strcat('LaplacianPyramid_', imgName1, '_', imgName2, '.jpg')));

end


function [pyramid] = GeneratePyramid(img, levels, downsamplingFactor, pyramidType)
% DESCRIPTION: Generate either 'Gaussian' or 'Laplacian' pyramid for the 
%              given image with specified tuning parameters.
% INPUT:       %img                  Image for which pyramid is to be generated
%              %levels               Number of frequency levels to be generated
%              %downsamplingFactor   Downsampling factor
%              %pyramidType          Type of pyramid to be generated
% OUTPUT:      Either 'Gaussian' or 'Laplacian' pyramid.

    % Create a 'Gaussian' filter with sufficiently large kernel size [25 25] 
    % and standard deviation 5.
    filter = fspecial('gaussian', [25 25], 5);

    % For specified number of levels,
    pyramid = cell(1, levels);
    for i = 1:levels
        % Apply 'Gaussian' filter.
        % If asked for 'Laplacian' pyramid, then subtract filtered image
        % from original image.
        if strcmp(pyramidType, 'Gaussian')
            filtered_img = imfilter(img, ...
                                    filter, ...
                                    'symmetric', ...
                                    'same', ...
                                    'conv');
        elseif strcmp(pyramidType, 'Laplacian')
            filtered_img = img - imfilter(img, ...
                                          filter, ...
                                          'symmetric', ...
                                          'same', ...
                                          'conv');
        end
        
        % Store the filtered image into pyramid
        pyramid{i}   = filtered_img;
        
        % Downsample the filtered image
        img          = imresize(filtered_img, ...
                                downsamplingFactor, ...
                                'bilinear');
    end

end


function [frequency] = ReconstructPyramid(pyramid, ...
                                          cutoffFrequency, ...
                                          upsamplingFactor, ...
                                          frequencyType)
% DESCRIPTION: Reconstruct either 'Low' or 'High' frequency component from
%              the given pyramid with specified tuning parameters.
% INPUT:       %pyramid            Pyramid from which frequency component
%                                  is to be constructed
%              %cutoffFrequency    Cutoff frequency
%              %upsamplingFactor   Upsampling factor
%              %frequencyType      Frequency type
% OUTPUT:      Returns reconstructed frequency component.

    % Determine start and end index based on cutoff frequency and frequency
    % type.
    % For Low frequency component, add specified number of levels from the 
    % end.
    % For High frequency component, add specified number of levels from the
    % beginning.
    if strcmp(frequencyType, 'Low')
        startIndex = size(pyramid, 2) - 1;
        endIndex   = size(pyramid, 2) - cutoffFrequency;
    elseif strcmp(frequencyType, 'High')
        startIndex = cutoffFrequency;
        endIndex   = 1;
    end
    
    % For reconstruction, follow procedure exactly reverse to pyramid
    % generation i.e. upsample each level instead downsampling it.
    for i = startIndex:endIndex
        pyramid{i} = pyramid{i} + imresize(pyramid{i+1}, ...
                                           upsamplingFactor, ...
                                           'bilinear');
    end
    
    % Set reconstructed frequency
    frequency = pyramid{endIndex};

end


function [pyramid_img] = DisplayPyramid(pyramid, height, colorChannels, pyramidType)
% DESCRIPTION: Display pyramid.
% INPUT:       %pyramid            Pyramid to be displayed
%              %height             Height of a pyramid
%              %colorChannels      Total number of color channels in a
%                                  pyramid
%              %pyramidType        Pyramid type
% OUTPUT:      Display a given pyramid and return a concatenated pyramid
%              images.

    % Concatenate every level together (also, pad if required)
    pyramid_img = [];
    for i = 1:size(pyramid, 2)
        tmp_img     = cat(1, ...
                          ones(height - size(pyramid{i},1), ...
                               size(pyramid{i},2), ...
                               colorChannels), ...
                          pyramid{i});
        pyramid_img = cat(2, pyramid_img, tmp_img);
    end
    
    % Display pyramid.
    % If it is a 'Laplacian' pyramid, then add 0.5 before displaying it.
    if strcmp(pyramidType, 'Gaussian')
        figure; imshow(pyramid_img);
    elseif strcmp(pyramidType, 'Laplacian')
        figure; imshow(pyramid_img+0.5);
    end
    
end

