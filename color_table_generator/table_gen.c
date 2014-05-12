#include <stdio.h>
#include <math.h>

void main(){
	int i,r,g,y,b;
	float j,k;

	j = 256.0 / 6.0;

	for(i=0; i<256; i++){
		switch( (int) (((float)i)/j) ){
			case 0 : 
				r = 15;
				y = (int) 15*sqrt(1-pow(((42-i)/42.0),2));
				g = (y<0) ? 0 : ((y > 15) ? 15 : y);
				b = 0;
				break;
			case 1 :
				y = (int) 15*sqrt(1-pow(((i-j)/42.0),2));
				r = (y<0) ? 0 : ((y > 15) ? 15 : y);
				g = 15;
				b = 0;
				break;
			case 2 : 
				r = 0;
				g = 15;
				y = (int) 15*sqrt(1-pow((((42-(i-2*j)))/42.0),2));
				b = (y<0) ? 0 : ((y > 15) ? 15 : y);
				break;
			case 3 :
				r = 0;
				y = (int) 15*sqrt(1-pow(((i-3*j)/42.0),2));
				g = (y<0) ? 0 : ((y > 15) ? 15 : y);
				b = 15;
				break;
			case 4 : 
				y = (int) 15*sqrt(1-pow(((42-(i-4*j))/42.0),2));
				r = (y<0) ? 0 : ((y > 15) ? 15 : y);
				g = 0;
				b = 15;
				break;
			default :
				r = 15;
				g = 0;
				y = (int) 15*sqrt(1-pow((((i-5*j))/42.0),2));
				b = (y<0) ? 0 : ((y > 15) ? 15 : y);
		}

		printf("x\"%x\" & x\"%x\" & x\"%x\",\n",b,g,r);
	}
}