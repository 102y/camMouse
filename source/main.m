%% CLEAR, SET AND INITIALIZE:
clear all
close all
import java.awt.Robot;
import java.awt.event.*;
% camera parameters:
camHeight = 720;
camWidth = 1280;
% set number of frames to run for:
T = 300;
% initialize for mouse control
mouse = Robot();
% get screen dimensions:
dim = get(0, 'screensize');
screenDim = [dim(3) dim(4)];
% scale of mouse movement:
scale = 15;
%% USE THE IMAGE ACQUISITION TOOLBOX:
% creating video object:
vid = videoinput('macvideo');
% change the colorspace of the camera's output:
set(vid,'ReturnedColorSpace','rgb');
% set the Region Of Interest for the camera (we just want the face)
%set(vid,'ROIPosition',[camWidth/4, 0, 2*camWidth/4, 720]);
% set camera up only once; camera is not closed with getsnapshot function:
triggerconfig(vid, 'manual');
% start the video object:
start(vid);

%% DETECTING FACE:
for i = 1:50
    im = imresize(fliplr(getsnapshot(vid)),0.5);
    imagesc(im); 
    title('Stabilize yourself'); pause(0.01);
end
% converting last frame to type double for computation:
im = im2double(im);
% obtain face template from user:
title('Now select your face for detection');
faceTemplCoord = getrect; % format of face: [xmin ymin width height]
face = im(faceTemplCoord(2):(faceTemplCoord(2)+faceTemplCoord(4)), faceTemplCoord(1):(faceTemplCoord(1)+faceTemplCoord(3)),:);
% compute HOG of the face:
faceHOG = hog(rgb2gray(face));
% detect the face in the picture using the template:
[x,y,score] = detect(rgb2gray(im),faceHOG,1);
% defining bounding box of detected face:
bbox = [x-faceTemplCoord(3)/2 y-faceTemplCoord(4)/2 faceTemplCoord(3) faceTemplCoord(4)]; %[xmin ymin width height]
bboxPoints = bbox2points(bbox);
% displaying detected face:
imagesc(im);
title('Detected Face')
hold on; 
h = rectangle('Position',bbox,'EdgeColor','green','LineWidth',3,'Curvature',[0.3 0.3]);
hold off
% detect feature points in the face region.
points = detectMinEigenFeatures(rgb2gray(im), 'ROI', bbox);
% display the detected points:
hold on;
title('Detected Features');
plot(points); pause(0.01); % to display
    
%bboxx = (x - faceTemplCoord(3)/2 + 25):(x + faceTemplCoord(3)/2 - 25);
%bboxy = (y - faceTemplCoord(4)/2 + 25):(y + faceTemplCoord(4)/2 - 25);
%points = [];
%for i=1:length(bboxx)
%    for j = 1:length(bboxy)
%        points = [points; [bboxx(i) bboxy(j)]];
%    end
%end 

% setting the mouse to the center of the screen:
mouseCoords = [screenDim(1)/2 screenDim(2)/2];
mouse.mouseMove(mouseCoords(1), mouseCoords(2));

%% TRACKING THE FEATURES:

% Create a point tracker and enable the bidirectional error constraint:
pointTracker = vision.PointTracker('MaxBidirectionalError', 3);
% Initialize the tracker with the initial point locations and the initial
% video frame.
points = points.Location;
initialize(pointTracker, points, im);

oldPoints = points;
oldMeanFacePos = mean(points);

timenow = clock;
startTime = timenow(5:6);

for i = 1:T
    % capture the next frame and flip it horizontally:
    frame = im2double(imresize(fliplr(getsnapshot(vid)),0.5));
    
    % Track the points. Some points may be lost:
    [points, isFound] = step(pointTracker, frame);
    visiblePoints = points(isFound, :);
    oldInliers = oldPoints(isFound, :);
    
    if size(visiblePoints,1) >= 100

        % Display tracked points:
        frame = insertMarker(frame, visiblePoints, '+', ...
            'Color', 'white');
        newMeanFacePos = mean(visiblePoints);
        frame = insertMarker(frame, newMeanFacePos, '*', 'Color', 'red', 'Size', 20);
        
        % set the new mouse position:
        mouseCoords = floor(double(getMouseCoords(newMeanFacePos-oldMeanFacePos,mouseCoords,scale,screenDim)));
        mouse.mouseMove(mouseCoords(1), mouseCoords(2));
        
        % Reset the points:
        oldPoints = visiblePoints;
        oldMeanFacePos = newMeanFacePos;
        setPoints(pointTracker, oldPoints);
    else
        % remove the pointTracker:
        release(pointTracker);
        
        % notify the user that you have lost them:
        for j = 1:20
            frame = im2double(imresize(fliplr(getsnapshot(vid)),0.5));
            imagesc(frame); pause(0.01);
            title('Lost/losing you... Let me detect you again');
        end
        
        % stabilize the user:
        for j = 1:30
            frame = im2double(imresize(fliplr(getsnapshot(vid)),0.5));
            imagesc(frame); pause(0.01);
            title('Stabilize yourself');
        end
        
        % detect the face in the picture using the template:
        [x,y,score] = detect(rgb2gray(frame),faceHOG,1);
        % defining bounding box of detected face:
        bbox = [x-faceTemplCoord(3)/2 y-faceTemplCoord(4)/2 faceTemplCoord(3) faceTemplCoord(4)]; %[xmin ymin width height]
        % detect feature points in the face region:
        points = detectMinEigenFeatures(rgb2gray(frame), 'ROI', bbox);
        % display the detected points:
        hold on;
        title('Detected Features');
        plot(points); pause(0.01);
        % re-initialize the tracker:
        points = points.Location;
        initialize(pointTracker, points, frame);
        oldPoints = points;
        setPoints(pointTracker, oldPoints);
    end
    
    % display the annoted frame:
    imagesc(frame);
    title(['Tracking; Frame: ' num2str(i)]);
        pause(0.01); % for display purposes
    
end

timenow = clock;
endtime = timenow(5:6);

%% CLEAN UP:
% remove the pointTracker:
release(pointTracker);
% stop the video object:
stop(vid);
% this is a part of the clean-up process (according to MATLAB):
delete(vid);
imaqreset; % just in case the previous attempts didn't work well
