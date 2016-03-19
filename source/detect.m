
function [x,y,score] = detect(I,template,ndet)
%
% return top ndet detections found by applying template to the given image.
%   x,y should contain the coordinates of the detections in the image
%   score should contain the scores of the detections
%


% compute the feature map for the image
f = hog(I);
nori = size(f,3);

% cross-correlate template with feature map to get a total response
% template is also three dimensional
R = zeros(size(f,1),size(f,2));
for i = 1:nori
  fliptemp = flipud(fliplr(template(:,:,i)));
  R = R + conv2(f(:,:,i),fliptemp,'same'); % cross-correlate here with template
end
% R holds the final responses of all orientations. is of the size H/8 x W/8

% NOW RETURN LOCATIONS OF THE TOP NDET DETECTIONS

% sort response from high to low
[val,ind] = sort(R(:),'descend');

% work down the list of responses, removing overlapping detections as we go
x = [];
y = [];
i = 1;
detcount = 0;
while ((detcount < ndet) & (i < length(ind)))
  % convert ind(i) back to (i,j) values to get coordinates of the block
  xblock = floor(ind(i)./size(f,1));
  yblock = ind(i) - xblock*size(f,1);
  if yblock == 0        % handling corner case for y-axis index
      if xblock == 0
          xblock = 1;
          yblock = 1;
      else
        yblock = size(f,1);
      end
  else
      xblock = xblock + 1; % we add 1 because the indexing begins at 1
  end
  
  assert(val(i)==R(yblock,xblock)); %make sure we did the indexing correctly

  % now convert yblock,xblock to pixel coordinates 
  ypixel = 8*yblock;
  xpixel = 8*xblock;

  % check if this detection overlaps any detections which we've already added to the list
  overlap = 0;
  ydiff = abs(ypixel - y)./8; % compute the differences between this y coordinate and the stored ones
  xdiff = abs(xpixel - x)./8; % compute the differences between thix x coordinate and the stored ones
  ydiff = ydiff < (size(template,1));
  xdiff = xdiff < (size(template,2));
  diff = ydiff & xdiff;
  if(sum(diff) > 0)
      overlap = 1;
  end

  % if not, then add this detection location and score to the list we return
  if (~overlap)
    detcount = detcount+1;
    x(detcount) = xpixel;
    y(detcount) = ypixel;
    score(detcount) = val(i);
  end
  i = i + 1
end


