PY?=python3
PELICAN?=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/smarlowucf.github.io
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py

GITHUB_PAGES_BRANCH=master

PAGESDIR=$(INPUTDIR)/pages
POSTSDIR=$(INPUTDIR)/articles
DATE := $(shell date +'%Y-%m-%d %H:%M:%S')
SLUG := $(shell echo '${NAME}' | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)
AUTHORS ?= "Sean Marlow"
EXT ?= adoc
EDITOR ?= vim

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE), 1)
	PELICANOPTS += --relative-urls
endif

help:
	@echo 'Makefile for a pelican Web site                                           '
	@echo '                                                                          '
	@echo 'Usage:                                                                    '
	@echo '   make html                           (re)generate the web site          '
	@echo '   make clean                          remove the generated files         '
	@echo '   make regenerate                     regenerate files upon modification '
	@echo '   make publish                        generate using production settings '
	@echo '   make serve [PORT=8000]              serve site at http://localhost:8000'
	@echo '   make serve-global [SERVER=0.0.0.0]  serve (as root) to $(SERVER):80    '
	@echo '   make devserver [PORT=8000]          serve and regenerate together      '
	@echo '   make ssh_upload                     upload the web site via SSH        '
	@echo '   make rsync_upload                   upload the web site via rsync+ssh  '
	@echo '   make github                         upload the web site via gh-pages   '
	@echo '                                                                          '
	@echo 'Set the DEBUG variable to 1 to enable debugging, e.g. make DEBUG=1 html   '
	@echo 'Set the RELATIVE variable to 1 to enable relative urls                    '
	@echo '                                                                          '

html:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

regenerate:
	$(PELICAN) -r $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

serve:
ifdef PORT
	$(PELICAN) -l $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -p $(PORT)
else
	$(PELICAN) -l $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
endif

serve-global:
ifdef SERVER
	$(PELICAN) -l $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -p $(PORT) -b $(SERVER)
else
	$(PELICAN) -l $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -p $(PORT) -b 0.0.0.0
endif


devserver:
ifdef PORT
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -p $(PORT)
else
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
endif

publish:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)

github: publish
	ghp-import -m "Generate Pelican site" -b $(GITHUB_PAGES_BRANCH) $(OUTPUTDIR)
	git push origin $(GITHUB_PAGES_BRANCH)

newpost:
ifdef NAME
				echo "Title: $(NAME)" >  $(POSTSDIR)/$(SLUG).$(EXT)
				echo "Slug: $(SLUG)" >> $(POSTSDIR)/$(SLUG).$(EXT)
				echo "Date: $(DATE)" >> $(POSTSDIR)/$(SLUG).$(EXT)
				echo "Modified: $(DATE)" >> $(POSTSDIR)/$(SLUG).$(EXT)
				echo "Authors: $(AUTHORS)" >> $(POSTSDIR)/$(SLUG).$(EXT)
				echo ""              >> $(POSTSDIR)/$(SLUG).$(EXT)
				echo ""              >> $(POSTSDIR)/$(SLUG).$(EXT)
				${EDITOR} ${POSTSDIR}/${SLUG}.${EXT}
else
				@echo 'Variable NAME is not defined.'
				@echo 'Do make newpost NAME='"'"'Post Name'"'"
endif

editpost:
ifdef NAME
				${EDITOR} ${POSTSDIR}/${SLUG}.${EXT}
else
				@echo 'Variable NAME is not defined.'
				@echo 'Do make editpost NAME='"'"'Post Name'"'"
endif

newpage:
ifdef NAME
				echo "Title: $(NAME)" >  $(PAGESDIR)/$(SLUG).$(EXT)
				echo "Slug: $(SLUG)" >> $(PAGESDIR)/$(SLUG).$(EXT)
				echo "Authors: $(AUTHORS)" >> $(PAGESDIR)/$(SLUG).$(EXT)
				echo ""              >> $(PAGESDIR)/$(SLUG).$(EXT)
				echo ""              >> $(PAGESDIR)/$(SLUG).$(EXT)
				${EDITOR} ${PAGESDIR}/${SLUG}.$(EXT)
else
				@echo 'Variable NAME is not defined.'
				@echo 'Do make newpage NAME='"'"'Page Name'"'"
endif

editpage:
ifdef NAME
				${EDITOR} ${PAGESDIR}/${SLUG}.$(EXT)
else
				@echo 'Variable NAME is not defined.'
				@echo 'Do make editpage NAME='"'"'Page Name'"'"
endif


.PHONY: html help clean regenerate serve serve-global devserver stopserver publish github newpost editpost newpage editpage
