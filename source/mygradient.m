function [mag,ori] = mygradient(I)
%
% compute image gradient magnitude and orientation at each pixel
%

der = [-1 0 1]; % from the Dalal and Triggs paper

dx = imfilter(I, der);  % this is like how much of the orientation is in the x-direction
dy = imfilter(I, der'); % this is like how much of the orientation is in the y-direction

mag = sqrt(dx.^2 + dy.^2);  % magnitude of the angles at all the pixels
ori = atan(dy./dx);         % orientation of the angles at all the pixels (between -pi/2 and pi/2)

