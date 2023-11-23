extern void _bzero( void*, int );

int main(void) { 
	char stringB[4];
	_bzero( stringB, 4 );
	return 0;
}
