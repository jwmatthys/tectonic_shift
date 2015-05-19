void keyPressed()
{
  if (key==' ')
  {
    PImage temp = new PImage(80,60);
    temp.loadPixels();
    temp.copy(cam, 0, 0, cam.width, cam.height, 
    0, 0, temp.width, temp.height);
    temp = getReversePImage(temp);
    fastblur(temp, blur);
    temp.updatePixels();
    arraycopy(temp.pixels, backgroundPixels);
  }
  else if (keyCode==UP)
    thresh += 0.05;
  else if (keyCode==DOWN)
    thresh -= 0.05;
  background(0);
  textCounter = 120;

  theBlobDetection.setThreshold(thresh); // will detect bright areas whose luminosity > 0.2f;
  println("Threshold: "+thresh);
}

