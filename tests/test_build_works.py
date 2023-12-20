from groundlight import Groundlight 
import numpy 
from framegrab import FrameGrabber, MotionDetector  


if __name__=="__main__":
    sdk_client = Groundlight(api_token="invalid-api-token")
    frame_grabbers = FrameGrabber.autodiscover()
    
    help(sdk_client)
    help(frame_grabbers)