  // - Super Fast Blur v1.1 by Mario Klingemann <http://incubator.quasimondo.com>
// - BlobDetection library

import processing.video.*;
import blobDetection.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;
float thresh = 0.10f;
int[] backgroundPixels;
int maxBlobs = 0;
boolean drawBars = false;
boolean drawEdges = false;
boolean invert = false;
int blur = 1;
int poster = 2;
int textCounter = 0;

// ==================================================
// setup()
// ==================================================
void setup()
{
  // Size of applet
  //size(640, 480);
  size(displayWidth, displayHeight);
  smooth();
  rectMode(CORNERS);
  noCursor();
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("localhost", 12001);

  // Capture
  cam = new Capture(this, 640, 480, "/dev/video0");
  // Comment the following line if you use Processing 1.5
  cam.start();

  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(80, 60);
  backgroundPixels = new int[80*60];
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(thresh); // will detect bright areas whose luminosity > 0.2f;
  theBlobDetection.setConstants(16, 400, 50);
}

// ==================================================
// captureEvent()
// ==================================================
void captureEvent(Capture cam)
{
  cam.read();
  newFrame = true;
}

// ==================================================
// draw()
// ==================================================
void draw()
{
  timer();
  if (newFrame)
  {
    tint(255, 100);
    image(img, 0, 0, width, height);
    newFrame=false;
    img.copy(cam, 0, 0, cam.width, cam.height, 
    0, 0, img.width, img.height);
    img = getReversePImage(img);
    fastblur(img, blur);
    int presenceSum = frameDifference(img);
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(drawBars, (drawEdges || textCounter>0), presenceSum);
    filter(POSTERIZE, poster);
  }
  if (textCounter > 1)
  {
    fill(255);
    //else fill(0);
    noStroke();
    textSize(30);
    text("Setting threshold to "+nf(thresh,1,2), 20, 40);
    textCounter--;
  }
  else if (textCounter == 1)
  {
    background(0);
    textCounter = 0;
  }
}

int frameDifference (PImage img)
{
    int presenceSum = 0;
    img.loadPixels();
    for (int i=0; i<img.width*img.height; i++)
    {
      color currColor = img.pixels[i];
      color bkgdColor = backgroundPixels[i];
      // Extract the red, green, and blue components of the current pixel's color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixel's color
      int bkgdR = (bkgdColor >> 16) & 0xFF;
      int bkgdG = (bkgdColor >> 8) & 0xFF;
      int bkgdB = bkgdColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - bkgdR);
      int diffG = abs(currG - bkgdG);
      int diffB = abs(currB - bkgdB);
      if (invert)
      {
        diffR = 255-diffR;
        diffG = 255-diffG;
        diffB = 255-diffB;
      }
      // Add these differences to the running tally
      presenceSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      img.pixels[i] = color(diffR, diffG, diffB);
    }
    img.updatePixels();
    return presenceSum;
}

// ==================================================
// drawBlobsAndEdges()
// ==================================================
void drawBlobsAndEdges(boolean drawBars, boolean drawEdges, int sum)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  if (theBlobDetection.getBlobNb()>maxBlobs)
    maxBlobs = theBlobDetection.getBlobNb();
  OscMessage myMessage = new OscMessage ("/blobs");
  myMessage.add(theBlobDetection.getBlobNb());
  oscP5.send(myMessage, myRemoteLocation);
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      // Edges
      if (drawEdges)
      {
        strokeWeight(3);
        if (invert) stroke(10);
        else stroke(200);
        for (int m=0;m<b.getEdgeNb();m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null)
            line(
            eA.x*width, eA.y*height, 
            eB.x*width, eB.y*height);
        }
      }
    }
    if (drawBars)
    {
      noStroke();
      fill(255, b.w*128);
      rect(b.xMin*width, 0, b.xMax*width, height);
    }
    //bprintln(sum, frameRate);
    if (sum > 30000)
    {
      OscMessage myMessage2 = new OscMessage ("/clover");
      myMessage2.add(n);
      myMessage2.add(b.x);
      myMessage2.add(b.y);
      oscP5.send(myMessage2, myRemoteLocation);
    }
  }
}

// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img, int radius)
{
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0;i<256*div;i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0;y<h;y++) {
    rsum=gsum=bsum=0;
    for (i=-radius;i<=radius;i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0;x<w;x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0;x<w;x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius;i<=radius;i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0;y<h;y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}

public PImage getReversePImage( PImage image ) {
  PImage reverse = new PImage( image.width, image.height );
  for ( int i=0; i < image.width; i++ ) {
    for (int j=0; j < image.height; j++) {
      reverse.set( image.width - 1 - i, j, image.get(i, j) );
    }
  }
  return reverse;
}