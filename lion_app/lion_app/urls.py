from django.contrib import admin
from django.urls import path, include

from blog.urls import router as blog_router
from Forum.urls import router as forum_router




urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include(blog_router.urls)),
    path('forum/', include(forum_router.urls)),
    path('api-auth/', include('rest_framework.urls')),
]
