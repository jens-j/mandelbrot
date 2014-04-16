#include <stdio.h>

void main(){
	int i,r,g,b;
	float j,k;

	j = 255.0 / (4.0 * 6.0);

	for(i=0; i<256; i++){
		float i_f = (float)(i % 64);
		//printf("i_f, j, (int)i_f/j = %f, %f, %d",i_f,j,(int)(i_f/j));
		switch((int)(i_f/j)){
			case 0 : 
				r = 15;
				g = (int)(i_f * 15.0 / j); 
				b = 0;
				break;
			case 1 :
				r = (int)(15.0 - (i_f-j) * 15.0 / j);
				g = 15;
				b = 0;
				break;
			case 2 : 
				r = 0;
				g = 15;
				b = (int)((i_f-2*j) * 15.0 / j); 
				break;
			case 3 :
				r = 0;
				g = (int)(15.0 - (i_f-3*j) * 15.0 / j);
				b = 15;
				break;
			case 4 : 
				r = (int)((i_f-4*j) * 15.0 / j); 
				g = 0;
				b = 15;
				break;
			default :
				r = 15;
				g = 0;
				b = (int)(15.0 - (i_f-5*j) * 15.0 / j);
		}

		printf("x\"%x\" & x\"%x\" & x\"%x\",\n",b,g,r);
	}
}