from django.contrib import admin
from django.urls import path, include

from blog.urls import urlpatterns as blog_urls

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include(blog_urls)),
]
