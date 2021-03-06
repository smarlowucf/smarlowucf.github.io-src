# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

# Author
AUTHOR = 'Sean Marlow'
AUTHOR_INTRO = u'Hi! I\'m Sean - A Python developer.'
AUTHOR_DESCRIPTION = u'Hi! I\'m Sean - A Python developer.'
AUTHOR_AVATAR = 'https://i.stack.imgur.com/L2czk.jpg?s=328&g=1'

SITENAME = 'smarlowucf'
SITEURL = 'http://localhost:8000'

DISPLAY_PAGES_ON_MENU = True
MENUITEMS = ()

PATH = 'content'

TIMEZONE = 'America/Chicago'

DEFAULT_LANG = 'en'

THEME = 'themes/minimalxy'

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
SOCIAL = (
    ('github', 'https://github.com/smarlowucf'),
    ('stack-overflow', 'https://stackoverflow.com/users/5026601/smarlowucf'),
)

DEFAULT_PAGINATION = False

AUTHOR_WEB = 'https://smarlowucf.github.io'

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True
