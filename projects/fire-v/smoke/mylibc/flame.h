// SL 2021-01-22 @sylefeb
 
//      GNU AFFERO GENERAL PUBLIC LICENSE
//        Version 3, 19 November 2007
//      
//  A copy of the license full text is included in 
//  the distribution, please refer to it for details.

// trigonometry (fixed precision: 7 bits - a unit = 128)
extern int costbl[256]; // 256 entries
int fxcos(int angle);   // angles in [0,255]
int fxsin(int angle);

// matrix transforms (fixed precision: 7 bits - a unit = 128)
void rotX (int *M, int angle);
void rotY (int *M, int angle);
void rotZ (int *M, int angle);
void scale(int *M, int scale);
void mulM (int *M, const int *A,const int *B);

// draw a triangle (fixed precision: 5 bits - a unit = 32)
// color: base palette color
// shade: if 0, disabled, if 1 uses triangle area to shade from index color in [color,color+16(recheck)]
void draw_triangle(char color,char shade,int px0,int py0,int px1,int py1,int px2,int py2);

// clear screen (uses triangles)
void clear(int xm,int ym,int xM,int yM);
