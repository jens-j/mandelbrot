#include <stdio.h>
#include <math.h>




void print_rgb(int x){
	int r,g,b,y;
	float j = 256.0 / 6.0;

	switch( (int) ( ( (float) x ) / j ) ){
		case 0 : 
			r = 15;
			y = (int) 15*sqrt(1-pow(((42-x)/42.0),2));
			g = (y<0) ? 0 : ((y > 15) ? 15 : y);
			b = 0;
			break;
		case 1 :
			y = (int) 15*sqrt(1-pow(((x-j)/42.0),2));
			r = (y<0) ? 0 : ((y > 15) ? 15 : y);
			g = 15;
			b = 0;
			break;
		case 2 : 
			r = 0;
			g = 15;
			y = (int) 15*sqrt(1-pow((((42-(x-2*j)))/42.0),2));
			b = (y<0) ? 0 : ((y > 15) ? 15 : y);
			break;
		case 3 :
			r = 0;
			y = (int) 15*sqrt(1-pow(((x-3*j)/42.0),2));
			g = (y<0) ? 0 : ((y > 15) ? 15 : y);
			b = 15;
			break;
		case 4 : 
			y = (int) 15*sqrt(1-pow(((42-(x-4*j))/42.0),2));
			r = (y<0) ? 0 : ((y > 15) ? 15 : y);
			g = 0;
			b = 15;
			break;
		default :
			r = 15;
			g = 0;
			y = (int) 15*sqrt(1-pow((((x-5*j))/42.0),2));
			b = (y<0) ? 0 : ((y > 15) ? 15 : y);
	}

	printf("%x%x%x",b,g,r);
}

void print_standard(int x){
	float w = 256.0 / 5.0;
	int i,y,z,r,g,b;
	int colors[6][3] = {{0,3,10},
						{13,15,15},
						{15,13,3},
						{8,2,1},
						{1,0,3},
						{0,3,10}};					

	if(x==0)
		y=0;
	else
		y = (int) (x / w);

	for(i=0;i<5;i++){
		if(x-((float)w)*i > 0){
			z = x - (int) (i*w); 
		}
	}

	

	r = (int) ((16.0/15.0) * ( (float)colors[y][0] + z * ((float)colors[y+1][0] - (float)colors[y][0] )/w ));
	g = (int) ((16.0/15.0) * ( (float)colors[y][1] + z * ((float)colors[y+1][1] - (float)colors[y][1] )/w ));
	b = (int) ((16.0/15.0) * ( (float)colors[y][2] + z * ((float)colors[y+1][2] - (float)colors[y][2] )/w ));

	//printf("%d : (%d,%d,%d)\n",x,y,z,b);
	printf("%x%x%x",r,g,b);
}

void main(){
	int i,y;
	double x;


	for(i=0; i<256; i++){
		print_standard(i);
		if(i != 255)
			printf(",\n");
	}
	printf(";");

	// for(i=0; i<256; i++){
	// 	if (i < 128){
	// 		x = log2(i/128.0 + 1);
	// 	}else{ 
	// 		x = log2(i/128.0) + 1;
	// 	}
	// 	//x = (x*256);
	// 	y = ((int)(x*256)) % 256;
	// 	print_rgb(y);
	// 	//printf("%d",y);
	// 	if(i!=8191)
	// 		printf(",\n");
	// }
	// printf(";");
}
