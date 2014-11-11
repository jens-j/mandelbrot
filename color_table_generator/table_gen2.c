#include <stdio.h>
#include <stdlib.h>

typedef struct rgb {
    int r;
    int g;
    int b;
} rgb;

int main ( int argc, char *argv[] )
{
    int i,color_n;
    rgb *colors;


    if(argc < 3){
        printf("usage: $table_gen2 *number of colors* *'r,g,b'* ... *'r,g,b'*\n");
        exit(0);
    }

    colors = (rgb*) malloc((argc-2) * sizeof(rgb));

    if (sscanf(argv[1],"%d",&color_n) != 1) {
        printf("failed to parse color count\n");
        exit(0);
    }

    for(i=2; i<argc; i++){
        if( sscanf(argv[i],"%d,%d,%d",&colors[i-2].r,&colors[i-2].g,&colors[i-2].b) != 3 ){
            printf("failed to parse color number %d\n",i-1);
            exit(0);
        }
    }

    if(i-2 != color_n)
        printf("not enough or to many colors specified (%d of %d)\n",i-2,color_n);

    printf("colors : %d\n\n",color_n);
    for(i=0; i<color_n; i++)
        printf("(%d) (r,g,b) = (%d,%d,%d)\n",i,colors[i].r,colors[i].g,colors[i].b);   


}

