function [mouseCoords] = getMouseCoords(faceDisp, oldMouseCoords, scale, maxDim)
    diffx = faceDisp(1);
    diffy = faceDisp(2);
    mouseCoords(1) = oldMouseCoords(1) + (scale * diffx);
    mouseCoords (2) = oldMouseCoords(2) + (scale * diffy);
    
    if mouseCoords(1) < 0
        mouseCoords(1) = 0;
    end
    
    if mouseCoords(1) > maxDim(1)
        mouseCoords(1) = maxDim(1);
    end
    
    if mouseCoords(2) < 0
        mouseCoords(2) = 0;
    end
    
    if mouseCoords(2) > maxDim(2)
        mouseCoords(2) = maxDim(2);
    end
    
end
