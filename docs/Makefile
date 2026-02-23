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

#build lab guide document
lab_guide: lab_guide/hwsw_lab_guide.pdf

lab_guide/hwsw_lab_guide.pdf: lab_guide/hwsw_lab_guide.tex
	cd lab_guide && pdflatex -interaction=nonstopmode hwsw_lab_guide.tex
	cd lab_guide && bibtex hwsw_lab_guide
	cd lab_guide && pdflatex -interaction=nonstopmode hwsw_lab_guide.tex
	cd lab_guide && pdflatex -interaction=nonstopmode hwsw_lab_guide.tex

#view document
view: $(DOC).pdf
	evince $< &

clean:
	@find .  -maxdepth 1 -type f -not \( -name \*.pdf -o -name Makefile -o -name \*.mk -o -name $(DOC)\* \) -delete
	@rm -rf $(PYTHON_DIR)/__pycache__ ../*.tex
	@rm -f lab_guide/hwsw_lab_guide.aux lab_guide/hwsw_lab_guide.log lab_guide/hwsw_lab_guide.out lab_guide/hwsw_lab_guide.lof lab_guide/hwsw_lab_guide.toc lab_guide/hwsw_lab_guide.bbl lab_guide/hwsw_lab_guide.blg

veryclean: clean
	make -C figures clean 

.PHONY: clean veryclean figs build view lab_guide

