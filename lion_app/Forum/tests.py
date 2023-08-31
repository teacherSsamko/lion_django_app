import json
import tempfile
from unittest.mock import patch, MagicMock

from django.contrib.auth.models import User
from django.urls import reverse
from django.http import HttpResponse
from rest_framework.test import APITestCase
from rest_framework import status

from .models import Topic, Post, TopicGroupUser


class PostTest(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.superuser = User.objects.create_superuser("supueruser")
        cls.private_topic = Topic.objects.create(
            name="private topic",
            is_private=True,
            owner=cls.superuser,
        )
        cls.public_topic = Topic.objects.create(
            name="public topic",
            is_private=False,
            owner=cls.superuser,
        )

        # Posts on private topic
        for i in range(5):
            Post.objects.create(
                topic=cls.private_topic,
                title=f"{i+1}",
                content=f"{i+1}",
                owner=cls.superuser,
            )
        # Posts on public topic
        for i in range(5):
            Post.objects.create(
                topic=cls.public_topic,
                title=f"{i+1}",
                content=f"{i+1}",
                owner=cls.superuser,
            )

        cls.authorized_user = User.objects.create_user("authorized")
        cls.unauthorized_user = User.objects.create_user("unauthorized")
        TopicGroupUser.objects.create(
            topic=cls.private_topic,
            group=TopicGroupUser.GroupChoices.common,
            user=cls.authorized_user,
        )

    def test_write_permission_on_private_topic(self):
        data = {
            "title": "test",
            "content": "test",
            "topic": self.private_topic.pk,
        }

        # when unauthorized user tries to write a post on Topic => fail. 401
        self.client.force_login(self.unauthorized_user)
        res = self.client.post(reverse("post-list"), data=data)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

        # when authorized user tries to write a post on Topic => success. 201
        self.client.force_login(self.authorized_user)
        res: HttpResponse = self.client.post(reverse("post-list"), data=data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        res_data = json.loads(res.content)
        Post.objects.get(pk=res_data["id"])

        # Admin => 201
        admin = User.objects.create_user("admin")
        TopicGroupUser.objects.create(
            topic=self.private_topic,
            group=TopicGroupUser.GroupChoices.admin,
            user=admin,
        )
        self.client.force_login(admin)
        res = self.client.post(reverse("post-list"), data=data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Owner => 201
        self.client.force_login(self.superuser)
        res = self.client.post(reverse("post-list"), data=data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_read_permission_on_topics(self):
        # read public topic
        # unauthorized user requests => 200. public topic's posts
        self.client.force_login(self.unauthorized_user)
        res = self.client.get(reverse("topic-posts", args=[self.public_topic.pk]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = json.loads(res.content)
        posts_n = Post.objects.filter(topic=self.public_topic).count()
        self.assertEqual(len(data), posts_n)

        # read private topic
        # unauthorized user requests => 401.
        self.client.force_login(self.unauthorized_user)
        res = self.client.get(reverse("topic-posts", args=[self.private_topic.pk]))
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        # authorized user requests => 200. private topic's posts
        self.client.force_login(self.authorized_user)
        res = self.client.get(reverse("topic-posts", args=[self.private_topic.pk]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = json.loads(res.content)
        posts_n = Post.objects.filter(topic=self.private_topic).count()
        self.assertEqual(len(data), posts_n)

    def test_read_permission_on_posts(self):
        # read public topic's post
        # unauthorized user requests => 200.
        self.client.force_login(self.unauthorized_user)
        public_post = Post.objects.filter(topic=self.public_topic).first()
        res = self.client.get(reverse("post-detail", args=[public_post.pk]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # read private topic's post
        # unauthorized user requests => 401.
        self.client.force_login(self.unauthorized_user)
        private_post = Post.objects.filter(topic=self.private_topic).first()
        res = self.client.get(reverse("post-detail", args=[private_post.pk]))
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        # authorized user requests => 200.
        self.client.force_login(self.authorized_user)
        private_post = Post.objects.filter(topic=self.private_topic).first()
        res = self.client.get(reverse("post-detail", args=[private_post.pk]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    @patch("Forum.views.boto3.client")
    def test_post_with_or_without_image(self, client: MagicMock):
        # mock s3
        s3 = MagicMock()
        client.return_value = s3
        s3.upload_fileobj.return_value = None
        s3.put_object_acl.return_value = None

        # without image => success.
        data = {
            "title": "test",
            "content": "test",
            "topic": self.public_topic.pk,
        }
        self.client.force_login(self.authorized_user)
        res = self.client.post(reverse("post-list"), data=data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # with image => success.
        with tempfile.NamedTemporaryFile(suffix=".jpg") as tmpfile:
            data["image"] = tmpfile
            res = self.client.post(reverse("post-list"), data=data)
            self.assertEqual(res.status_code, status.HTTP_201_CREATED)
            res_data = json.loads(res.content)
            self.assertTrue(res_data["image_url"].startswith("https://"))

        s3.upload_fileobj.assert_called_once()
        s3.put_object_acl.assert_called_once()
