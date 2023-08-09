from rest_framework.routers import DefaultRouter

from . import views


router = DefaultRouter()
router.register('topic', views.TopicViewSet, basename='topic')
router.register('post', views.PostViewSet, basename='post')
