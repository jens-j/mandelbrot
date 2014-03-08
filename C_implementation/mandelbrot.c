#include <stdio.h>
#include "SDL/SDL.h"

main()
{
  int gd=DETECT,gm;
  initgraph(&gd,&gm,""); /* initialization of graphic mode */
  circle(150,150,100);
  getch();
  closegraph(); /* Restore orignal screen mode */
}