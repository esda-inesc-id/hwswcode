#
# Makefile for creating documents in the build directory
#

SHELL = bash
DOC ?= presentation

#build document
build: $(DOC).pdf

#make figures
figs:
	make -C ./figs build

#build presentation document type
presentation.pdf: figs presentation.tex
	pdflatex -jobname pres presentation.tex
	pdflatex -jobname pres presentation.tex

#view document
view: $(DOC).pdf
	evince $< &

clean:
	@find .  -maxdepth 1 -type f -not \( -name \*.pdf -o -name Makefile -o -name \*.mk -o -name $(DOC)\* \) -delete
	@rm -rf $(PYTHON_DIR)/__pycache__ ../*.tex

veryclean: clean
	make -C figures clean 

.PHONY: clean veryclean figs build view

