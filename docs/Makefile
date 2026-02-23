#
# Makefile for creating documents in the build directory
#

SHELL = bash

LAB_GUIDE  := lab_guide/hwsw_lab_guide
SLIDES_PDFS := $(patsubst slides/%.tex,slides/%.pdf,$(wildcard slides/lect*.tex))

#make figures
figs:
	make -C ./figs build

#build all documents
all: slides lab_guide

#build all slides
slides: figs $(SLIDES_PDFS)

slides/%.pdf: slides/%.tex
	pdflatex -jobname $(@:.pdf=) $<
	pdflatex -jobname $(@:.pdf=) $<

#build single lecture: make lecture <N>  (e.g. make lecture 0 → lect0)
N := $(word 2,$(MAKECMDGOALS))
.PHONY: lecture
lecture: figs slides/lect$(N).pdf

ifneq ($(filter lecture,$(MAKECMDGOALS)),)
$(N):
	@:
endif

#build lab guide and view pdf
lab_guide: $(LAB_GUIDE).pdf
	evince $(LAB_GUIDE).pdf &

$(LAB_GUIDE).pdf: $(LAB_GUIDE).tex
	pdflatex -interaction=nonstopmode -output-directory lab_guide $(LAB_GUIDE).tex
	BIBINPUTS=lab_guide: bibtex $(LAB_GUIDE)
	pdflatex -interaction=nonstopmode -output-directory lab_guide $(LAB_GUIDE).tex
	pdflatex -interaction=nonstopmode -output-directory lab_guide $(LAB_GUIDE).tex

clean:
	@find . slides/ lab_guide/ -maxdepth 1 -type f \
		-not \( -name \*.pdf -o -name \*.tex -o -name \*.bib -o -name Makefile -o -name \*.mk \) -delete
	@rm -f slides/*-blx.bib

veryclean: clean
	make -C figs clean
	@rm slides/*.pdf lab_guide/*.pdf

.PHONY: all slides lab_guide figs clean veryclean lecture

