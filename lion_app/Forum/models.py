from django.db import models
from django.contrib.auth.models import User


class Topic(models.Model):
    name = models.TextField(max_length=128, unique=True)
    is_private = models.BooleanField(default=False)
    owner = models.ForeignKey(User, on_delete=models.PROTECT)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    posts: models.QuerySet["Post"]
    members: models.QuerySet["TopicGroupUser"]

    def __str__(self):
        return self.name

    def can_be_access_by(self, user: User):
        if (
            not self.is_private
            or self.owner == user
            or self.members.filter(user=user).exists()
        ):
            return True
        return False


class Post(models.Model):
    topic = models.ForeignKey(Topic, on_delete=models.CASCADE, related_name="posts")
    title = models.TextField(max_length=200)
    content = models.TextField()
    image_url = models.URLField(null=True, blank=True)
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class TopicGroupUser(models.Model):
    class GroupChoices(models.IntegerChoices):
        common = 0
        admin = 1

    topic = models.ForeignKey(Topic, on_delete=models.CASCADE, related_name="members")
    group = models.IntegerField(default=0, choices=GroupChoices.choices)
    user = models.ForeignKey(User, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.topic} | {self.group} | {self.user}"
