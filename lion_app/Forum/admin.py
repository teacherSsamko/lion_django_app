from django.contrib import admin

from .models import Topic, Post, TopicGroupUser

admin.site.register(Topic)
admin.site.register(Post)
admin.site.register(TopicGroupUser)
