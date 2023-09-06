import os

from .base import *


SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")

DEBUG = True

ALLOWED_HOSTS = [
    "*",
]

# CSRF_TRUSTED_ORIGINS = [
#     "http://lion-lb-staging-18975820-e3aa639c372a.kr.lb.naverncp.com",
# ]
