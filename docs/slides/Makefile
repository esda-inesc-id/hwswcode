#usage make L=<lecture number>
L?=1

all:
	@echo "Building slides for lecture L$(L)*.tex"
	@pdflatex -shell-escape -interaction=nonstopmode -halt-on-error L$(L)*.tex

clean:
	@echo "Cleaning auxiliary files"
	@rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb *~

veryclean: clean
	@echo "Cleaning PDF files"
	@rm -f *.pdf
