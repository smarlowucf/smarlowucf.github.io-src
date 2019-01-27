# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Sean Marlow'
SITENAME = 'smarlowucf'
SIDEBAR_DIGEST = 'Coder, Photographer, Traveler'
SITEURL = ''

DISPLAY_PAGES_ON_MENU = True
MENUITEMS = (('Blog', 'https://smarlowucf.github.io'),)

PATH = 'content'

TIMEZONE = 'America/Chicago'

DEFAULT_LANG = 'en'

THEME = 'themes/pelican-blue'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (('Pelican', 'http://getpelican.com/'),
         ('Python.org', 'http://python.org/'),)

# Social widget
SOCIAL = (('github', 'https://github.com/smarlowucf'),)

DEFAULT_PAGINATION = False

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True
