from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from blog.urls import router as blog_router
from Forum.urls import router as forum_router
from common.views import get_version


urlpatterns = [
    path("version/", get_version, name="version"),
    path("admin/", admin.site.urls),
    path("blog/", include(blog_router.urls)),
    path("forum/", include(forum_router.urls)),
    path("api-auth/", include("rest_framework.urls")),
    # drf-spectacular
    path("api/schema/", SpectacularAPIView.as_view(), name="api-schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="api-schema"),
        name="api-swagger-ui",
    ),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
