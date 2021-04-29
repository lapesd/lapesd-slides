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

RED=$(shell tput sgr0 ; tput setab 1 ; tput setaf 7)
YELLOW=$(shell tput sgr0 ; tput setab 3 ; tput setaf 0)
DIM=$(shell tput sgr0 ; tput dim)
BOLD=$(shell tput bold)
NORM=$(shell tput sgr0)


###################################################
# Compute some target enumerations                #
###################################################

srcs=$(wildcard *.tex) $(wildcard *.bib)
svgs=$(wildcard imgs/*.svg)
frames=$(foreach k,1 2 3 4 5,imgs/animation-$k.pdf)
pdfs=$(svgs:.svg=.pdf)

basename:=$(shell (grep -rE '\\documentclass.*lapesd-slides' | cut -d : -f 1 | grep -E '.tex$$' | xargs -n 1 bash -c 'echo $$(echo $$@ | wc -c):$$@' a | sed -E 's/^([0-9]):/00\1:/' | sed -E 's/^([0-9][0-9]):/0\1:/' | sort -u | head -n 1 | sed -E 's/^[0-9]+:(.*).tex$$/\1/g' > basename.make.log && test "$$(cat basename.make.log)" != "001:" && cat basename.make.log && rm -f basename.make.log)  || echo userguide)


###################################################
# phony targets                                   #
###################################################

all: imgs $(basename).robust.pdf

imgs: $(pdfs)

.PHONY: all imgs clean

# Avoid deletion by make (chained pattern rules)
.SECONDARY: $(basename).aux $(basename).blg $(basename).pdf

clean:
	rm -fr *.64 main-logo.pdf _minted-* *.aux *.bbl *.blg *.brf *.out *.synctex.gz *.log "$(basename).pdf" "$(basename).robust.pdf" *.idx *.ilg *.ind *.lof *.lot *.lol *.loalgorithm *.glsdefs *.xdy *.toc *.acn *.glo *.ist *.prv  *.fls *.fdb_latexmk _region*  *~ auto imgs/*.tmp.pdf {imgs,plots}/*-eps-converted-to.pdf;

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
	$(call inkscape2pdf,$(1).svg,$(3).tmp.pdf,--export-area-drawing)
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

%.aux: %.tex $(srcs) $(pdfs) $(frames)
	@for i in 1 2 3; do \
		echo '$(LTX) $< &>/dev/null' ; \
		($(LTX) "$<" 2>&1 | grep 'Label(s) may have changed' | &>/dev/null) || break; \
	done; true

%.blg: %.aux
	@echo $(BIBTEX) "$<" $(DIM); \
	$(BIBTEX) "$<" &> "$<.make.log"; RET=$$? ;\
	sed -E 's/[Ww]arning/$(YELLOW)\0$(DIM)/' <"$<.make.log" \
		| sed -E 's/[Ee]rror/$(RED)\0$(DIM)/'; echo $(NORM) ;\
	rm -f "$<.make.log";\
	test "$$RET" == 0

%.pdf: %.tex %.aux %.blg
	@ RET=0; \
  for i in 1 2 3 4; do \
		echo '$(LTX) $< ' ; \
		$(LTX) "$<" &> "$<.make.log" ; RET=$$?; \
		grep 'Label(s) may have changed' "$<.make.log"&>/dev/null || break ; \
	done; \
	WARNS=$$(grep -i warning "$<.make.log" | wc -l); \
	echo -n $(DIM) ; sed -E 's/[Ww]arning/$(YELLOW)\0$(DIM)/' <"$<.make.log"\
		| sed -E 's/^! Undefined control sequence/$(RED)\0$(DIM)/' ;\
		echo $(NORM) ; \
	rm -f "$<.make.log" ; \
	test "$$RET" == 0 || echo "$(PDFLATEX) $(RED)failed$(NORM) with code $$RET (see the log above)"; \
	test "$$WARNS" == 0 || echo "$(PDFLATEX) spewed $$WARNS $(YELLOW)warnings$(NORM)"; \
	test "$$RET" == 0

# Converts userguide.pdf to PDF version 1.4 and embedd all fonts
# This is required by IEEE (this is done by PDF Xpress) and Elsevier journals
%.robust.pdf: %.pdf $(srcs)
	@echo gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dEmbedAllFonts=true \
		-sOutputFile="$@" -f "$<" $(DIM) ;\
	gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dEmbedAllFonts=true \
		-sOutputFile="$@" -f "$<" ;\
	echo $(NORM)
