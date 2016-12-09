SRC	:= $(wildcard *.md)
PDF	:= $(SRC:%.md=%.pdf)

all: $(PDF)

%.pdf: %.html
	wkhtmltopdf $< $@

%.html: %.md
	markdown $< > $@

.PHONY: acrord
acrord: $(PDF)
	$(eval TMPPDF = LaTeX-$(shell sha1sum $< | awk '{print $$1}').pdf)
	$(MAKE) $(WINTMP)/$(TMPPDF)
	cd $(WINTMP); "$(ACRORD)" $(TMPPDF); true

$(WINTMP)/%.pdf: $(PDF)
	cp -a $< $@
