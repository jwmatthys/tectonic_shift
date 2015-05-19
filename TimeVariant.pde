void timer()
{
  drawEdges = (minute()%10)>=5;
  drawBars = (minute()%15)>=6;
  blur = (minute()%3)+1;
  poster = (minute()%12)+3;
  invert = minute()%30>=22;
}

