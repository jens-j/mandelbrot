 #include <stdio.h>
//#include <SDL.h>
#include "SDL/SDL.h"

#define WIDTH 480
#define HEIGHT 360
#define BPP 4
#define DEPTH 32
#define ITERATIONS 255

void setpixel(SDL_Surface *screen, int x, int y, Uint8 r, Uint8 g, Uint8 b)
{
    Uint32 *pixmem32;
    Uint32 colour;  
 
    colour = SDL_MapRGB( screen->format, r, g, b );
  
    pixmem32 = (Uint32*) screen->pixels  + y + x;
    *pixmem32 = colour;
}


void DrawScreen(SDL_Surface* screen, int **score, int iterations)
{ 
    int x, y, ytimesw, r,g,b;
  
    if(SDL_MUSTLOCK(screen)) 
    {
        if(SDL_LockSurface(screen) < 0) return;
    }

    for(y = 0; y < screen->h; y++ ) 
    {
        ytimesw = y*screen->pitch/BPP;
        for( x = 0; x < screen->w; x++ ) 
        {
            //set = ((score[y][x] == iterations) ? 0 : 255);
            if(score[y][x] == iterations)
                r = g = b = 0;
            else{
                r=255;
                g=255;
                b=score[y][x];
            }
            setpixel(screen, x, ytimesw, 0, b, b*b);
        }
    }

    if(SDL_MUSTLOCK(screen)) SDL_UnlockSurface(screen);
  
    SDL_Flip(screen); 
}

void mandelbrot(double orig_x, double orig_y, double len_x, double len_y, int iterations, int **score){
    int i,i_x,i_y;
    double c_real, c_imag, z_real, z_imag, z_real2, z_imag2;

    for(i_y=0; i_y< HEIGHT; i_y++){
        for(i_x=0; i_x<WIDTH; i_x++){
            c_real = orig_x + len_x * i_x / WIDTH ;
            c_imag = orig_y + len_y * i_y / HEIGHT;
            z_real = z_imag = 0;
            score[i_y][i_x] = iterations;
            i=0;
            while(i<iterations){
                z_real2 = z_real*z_real - z_imag*z_imag + c_real;
                z_imag2 = 2 * z_real * z_imag + c_imag;
                //printf("(x,y,i) = (real,imag) -> (%d,%d,%d) = (%1.3f,%1.3f)\n",i_x,i_y,i,z_real2,z_real);
                if (z_real2 > 2 || z_imag2 > 2)
                {
                    score[i_y][i_x] = i;
                    break;
                }
                z_real = z_real2;
                z_imag = z_imag2;
                i++;
            }
            if(i_y == HEIGHT/2)
                printf("(i_y,i_x,y,x,score) = (%d,%d,%1.5f,%1.5f,%d)\n", i_y,i_x,c_imag,c_real,score[i_y][i_x]);
            
        }
    }
}


int main(int argc, char* argv[])
{
    SDL_Surface *screen;
    SDL_Event event;
    int i;
    int **score;
    int keypress = 0;

    score = (int**) malloc(HEIGHT * sizeof(int*));
    for (i=0; i<HEIGHT; ++i)
        score[i] = (int*) malloc(WIDTH * sizeof(int));

    mandelbrot(-2.5,-1.5,4,3,ITERATIONS,score);
  
    if (SDL_Init(SDL_INIT_VIDEO) < 0 ) return 1;
   
    if (!(screen = SDL_SetVideoMode(WIDTH, HEIGHT, DEPTH, SDL_HWSURFACE)))
    {
        SDL_Quit();
        return 1;
    }
  
    while(!keypress) 
    {
        DrawScreen(screen, score, ITERATIONS);
        //DrawScreen(screen,h++);
        while(SDL_PollEvent(&event)) 
        {      
            switch (event.type) 
            {
                case SDL_QUIT:
	            keypress = 1;
	            break;
                case SDL_KEYDOWN:
                    keypress = 1;
                    break;
            }
        }
    }

    SDL_Quit();
  
    return 0;
}
