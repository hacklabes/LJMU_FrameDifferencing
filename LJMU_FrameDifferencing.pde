import processing.video.*;

// this is the number of pixels that have to change for a picture to be taken.
// making this higer makes it less sensitive (fewer pictures).
int MOVEMENT_THRESHOLD = 100000;

// this is the minimum amount of time between pictures in milliseconds.
// 1000 = 1 second
int CAPTURE_PERIOD = 1000;

// to avoid taking pictures of empty frames, this is the number of pixels 
//   that have to differ between the current frame and the calibration background.
int BACKGROUND_THRESHOLD = 200000;

// number of pictures to show in the slide show.
int PICS_IN_SLIDESHOW = 20;

// time for each picture in slideshow (in milliseconds).
// 500 = half-second
int SLIDESHOW_PERIOD = 500;

// whether to save pictures to hard-drive or not
boolean SAVE_PICTURES = true;

long lastCaptureMillis;
int numPixels;
boolean debug;
boolean needToCaptureBackground;
Capture video;
PImage mBackground, backDiff, frameDiff, previousFrame;
String YYYYMMDD = year()+"-"+month()+"-"+day();

ArrayList<PImage> mPics;
int displayIndex;
long lastSlideChangeMillis;

void setup() {
  size(640, 480);
  frameRate(30);

  video = new Capture(this, width, height);
  video.start(); 

  numPixels = video.width * video.height;

  lastCaptureMillis = millis();
  debug = false;
  needToCaptureBackground = true;
  mBackground = createImage(width, height, ARGB);
  backDiff = createImage(width, height, ARGB);
  frameDiff = createImage(width, height, ARGB);
  previousFrame = createImage(width, height, ARGB);

  mPics = new ArrayList<PImage>();
  displayIndex = 0;
  lastSlideChangeMillis = millis();
}

void draw() {
  if (video.available()) {
    video.read();
    video.loadPixels();

    if (needToCaptureBackground) {
      image(video, 0, 0);
      textSize(32);
      fill(255, 0, 255);
      text("Make sure no one is on camera and hit 'c' on the keyboard to calibrate the camera", 50, height/2-100, width-100, height-200);
    } else {
      backDiff.loadPixels();
      frameDiff.loadPixels();
      previousFrame.loadPixels();

      int movementSum = 0;
      int backgroundSum = 0;
      for (int i = 0; i < numPixels; i++) {
        color currColor = video.pixels[i];
        color prevColor = previousFrame.pixels[i];
        color backColor = mBackground.pixels[i];

        int currB = currColor & 0xFF;
        int prevB = prevColor & 0xFF;
        int backB = backColor & 0xFF;

        int backDiffB =  abs(currB - backB) & 0xFF;
        int frameDiffB = abs(currB - prevB) & 0xFF;

        movementSum += (frameDiffB>128)?frameDiffB:0;
        backgroundSum += (backDiffB>128)?backDiffB:0;

        frameDiff.pixels[i] = 0xff000000 | (frameDiffB << 16) | (frameDiffB << 8) | frameDiffB;
        backDiff.pixels[i] = 0xff000000 | (backDiffB << 16) | (backDiffB << 8) | backDiffB;
        previousFrame.pixels[i] = currColor;
      }
      previousFrame.updatePixels();

      if (debug) {
        frameDiff.updatePixels();
        image(frameDiff, 0, 0);
        println("move Sum: "+movementSum);
        println("back Sum: "+backgroundSum);
      } else if ((movementSum > MOVEMENT_THRESHOLD) && (backgroundSum > BACKGROUND_THRESHOLD)) {
        println("move Sum: "+movementSum);
        println("back Sum: "+backgroundSum);
        if (millis()-lastCaptureMillis > CAPTURE_PERIOD) {
          PImage newImage = createImage(width, height, ARGB);
          newImage.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height);
          // TODO: save picture
          if(SAVE_PICTURES == true){
            newImage.save("data/"+YYYYMMDD+"_"+hour()+minute()+second()+".jpg");
          }
          if (mPics.size()<PICS_IN_SLIDESHOW) {
            mPics.add(newImage);
          } else {
            mPics.get((displayIndex+PICS_IN_SLIDESHOW-1)%PICS_IN_SLIDESHOW).copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height);
          }

          lastCaptureMillis = millis();
        }
      } else if (mPics.size()>0) {
        if (millis()-lastSlideChangeMillis > SLIDESHOW_PERIOD) {
          displayIndex = (displayIndex+1)%mPics.size();
          lastSlideChangeMillis = millis();
        }
        image(mPics.get(displayIndex), 0, 0);
      }
    }
  }
}

void keyPressed() {
  if (key == ' ' || key == 'd' || key == 'D') {
    debug = !debug;
  } else if (key == 'c' || key == 'C') {
    mBackground.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height);
    needToCaptureBackground = false;
    image(video, 0, 0);
  }
}


