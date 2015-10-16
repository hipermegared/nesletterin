prueba: Newsletter_maker.pl templates/noticia-simple.html contenidos/noticia-simple.txt 
	./Newsletter_maker.pl -c contenidos/noticia-simple.txt -t templates/noticia-simple.html

var_test:
	./VARIABLE_TESTER.sh templates/noticia-simple.html contenidos/noticia-simple.txt 
