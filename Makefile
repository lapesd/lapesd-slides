PDFLATEX=pdflatex
BIBTEX=bibtex
MAKEINDEX=makeindex
LTX=$(PDFLATEX) -shell-escape -interaction=nonstopmode
XINDY=xindy
INKS=inkscape
GIT=git
PDFINFO=pdfinfo
PODOFOBOX=podofobox
GNUPLOT=gnuplot


###################################################
# Compute some target enumerations                #
###################################################

srcs=$(wildcard *.tex) $(wildcard *.bib)
svgs=$(wildcard imgs/*.svg)
frames=$(foreach k,1 2 3 4 5,imgs/animation-$k.pdf)
pdfs=$(svgs:.svg=.pdf) 

###################################################
# phony targets                                   #
###################################################

all: imgs userguide.robust.pdf

imgs: $(pdfs)

.PHONY: all imgs clean

clean: 
	rm -fr *.64 main-logo.pdf _minted-* *.aux *.bbl *.blg *.brf *.out *.synctex.gz *.log main.pdf main.robust.pdf *.idx *.ilg *.ind *.lof *.lot *.lol *.loalgorithm *.glsdefs *.xdy *.toc *.acn *.glo *.ist *.prv  *.fls *.fdb_latexmk _region*  *~ auto imgs/*.tmp.pdf {imgs,plots}/*-eps-converted-to.pdf; 

###################################################
# SVG -> PDF conversion                           #
###################################################

INKS_VER:=$(shell (inkscape --version 2>&1 | grep -E 'Inkscape [1-9]' &>/dev/null) && echo 1 || echo 0)
INKSCAPE=$(INKS) $(if $(subst 0,,$(INKS_VER)),,-z)
define inkscape2pdf
	$(INKSCAPE) $(3) $(if $(subst 0,,$(INKS_VER)),--export-filename,-A)=$(2) $(1) 
endef

# directly convert a SVG to PDF. The SVG's contents will be cropped to the page
imgs/%.pdf: imgs/%.svg
	$(call inkscape2pdf,$<,$@,-C)

#Possible bug: inkscape -z -D -i gSlide1 -A=out.pdf in.svg
#Workaround: generate a pdf of the whole drawing (-D, beyond page borders); get bottom:left:width:height of object; convert px to PostScript pts; crop from the pdf
#Quirk: inkscape -Y has top-left corner of page at origin
define svg2pdf
	$(call inkscape2pdf,$(1).svg,$(3).tmp.pdf,-D)
	PTS=$$($(PDFINFO) $(3).tmp.pdf | grep 'Page size' | sed 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9].*/\1/'); \
	IW=$$($(INKSCAPE) --query-width $(1).svg); \
	FAC=$$(echo "scale=3; 100 * $$PTS / $$IW" | bc); \
	X=$$(awk "BEGIN {printf \"%.3f\", $$FAC * $$($(INKSCAPE) -I $(2) -X $(1).svg)}"); \
	Y=$$(awk "BEGIN {printf \"%.3f\", $$FAC * (-1)*($$($(INKSCAPE) -I $(2) -Y $(1).svg))}"); \
	W=$$(awk "BEGIN {printf \"%.3f\", $$FAC * $$($(INKSCAPE) -I $(2) -W $(1).svg)}"); \
	H=$$(awk "BEGIN {printf \"%.3f\", $$FAC * $$($(INKSCAPE) -I $(2) -H $(1).svg)}"); \
	$(PODOFOBOX) $(3).tmp.pdf $(3).pdf media $$X $$Y $$W $$H
	rm $(3).tmp.pdf
endef

###################################################
# Frane targets                                   #
###################################################

imgs/animation-1.pdf: imgs/animation.svg
	$(call svg2pdf,imgs/animation,gSlide1,imgs/animation-1)
imgs/animation-2.pdf: imgs/animation.svg
	$(call svg2pdf,imgs/animation,gSlide2,imgs/animation-2)
imgs/animation-3.pdf: imgs/animation.svg
	$(call svg2pdf,imgs/animation,gSlide3,imgs/animation-3)
imgs/animation-4.pdf: imgs/animation.svg
	$(call svg2pdf,imgs/animation,gSlide4,imgs/animation-4)
imgs/animation-5.pdf: imgs/animation.svg
	$(call svg2pdf,imgs/animation,gSlide5,imgs/animation-5)

###################################################
# main targets                                    #
###################################################

userguide.aux: $(srcs) $(pdfs) $(frames)
	$(LTX) userguide.tex; $(LTX) userguide.tex || true

userguide.blg: userguide.aux $(srcs)
	$(BIBTEX) userguide.aux

userguide.pdf: $(srcs) userguide.aux userguide.blg
	$(LTX) userguide.tex; \
	$(LTX) userguide.tex || true

# Converts userguide.pdf to PDF version 1.4 and embedd all fonts
# This is required by IEEE (this is done by PDF Xpress) and Elsevier journals
userguide.robust.pdf: userguide.pdf
	gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dEmbedAllFonts=true -sOutputFile="$@" -f "$<" 
