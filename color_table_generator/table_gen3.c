#include <stdio.h>
#include <stdlib.h>

typedef struct rgb {
    int r;
    int g;
    int b;
} rgb;

rgb color_set[20];

void print_set(int n){
	float w = 256.0 / (float)(n-1);
	int i,j,y,z,r,g,b;

	for(j=0; j<256; j++){
		if(j==0){
			y=0;
			z=0;
		}
		else{
			y = (int) (j / w);
			z = j - y*w;
		}

		r = (int) ((16.0/15.0) * ( (float)color_set[y].r + z * ((float)color_set[y+1].r - (float)color_set[y].r )/w ));
		g = (int) ((16.0/15.0) * ( (float)color_set[y].g + z * ((float)color_set[y+1].g - (float)color_set[y].g )/w ));
		b = (int) ((16.0/15.0) * ( (float)color_set[y].b + z * ((float)color_set[y+1].b - (float)color_set[y].b )/w ));

		r = (r<0) ? 0 : ( (r > 15) ? 15 : r );
		g = (g<0) ? 0 : ( (g > 15) ? 15 : g );
		b = (b<0) ? 0 : ( (b > 15) ? 15 : b );


		printf("%x%x%x,\n",b,g,r);
	}
}

void main (){
	int i,j, color=0, set=0;
	FILE *fp;
	char line[200];

	fp = fopen("color_sets.rgb", "r");
	if(!fp){
		printf("failed to open file\n");
		exit(0);
	}

	printf("MEMORY_INITIALIZATION_RADIX=16;\nMEMORY_INITIALIZATION_VECTOR=\n");


	while( fgets(line, sizeof(line), fp) != NULL ){
		//printf("%s",line);	

		if(line[0] == '#'){
			//printf("found comment\n");
			continue;
		}
		else if( line[0] == ';' ){
			//printf("color set complete (%d colors)\n", color);
			print_set(color);
			set++;
			color = 0;
		}	
		else if( sscanf( line, "(%d,%d,%d)\n", &color_set[color].r, &color_set[color].g, &color_set[color].b ) == 3 ){
			//printf("found color (%d,%d,%d)\n", color_set[color].r, color_set[color].g, color_set[color].b);		
			color_set[color].r /= 16;
			color_set[color].g /= 16;
			color_set[color].b /= 16;
			color++;
		}
		else{
			printf("could not parse color (%d,%d)\n", set, color);
			exit(0);
		}
	}
    
	//printf("done\n");

	fclose(fp);
}

