import uuid

import boto3
from django.core.files.base import File
from django.shortcuts import get_object_or_404
from django.conf import settings
from drf_spectacular.utils import extend_schema
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response

from .models import Topic, Post, TopicGroupUser
from .serializers import TopicSerializer, PostSerializer, PostUploadSerializer


@extend_schema(tags=["Topic"])
class TopicViewSet(viewsets.ModelViewSet):
    queryset = Topic.objects.all()
    serializer_class = TopicSerializer

    @extend_schema(summary="새 토픽 생성")
    def create(self, request: Request, *args, **kwargs):
        serializer = TopicSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            data["owner"] = request.user
            res: Topic = serializer.create(data)
            return Response(
                status=status.HTTP_201_CREATED, data=TopicSerializer(res).data
            )
        else:
            return Response(status=status.HTTP_400_BAD_REQUEST, data=serializer.errors)

    @action(detail=True, methods=["get"], url_name="posts")
    def posts(self, request: Request, *args, **kwargs):
        topic: Topic = self.get_object()
        user = request.user

        if not topic.can_be_access_by(user):
            return Response(
                status=status.HTTP_401_UNAUTHORIZED,
                data="This user is not allowed to read this topic",
            )

        posts = topic.posts
        serializer = PostSerializer(posts, many=True)

        return Response(data=serializer.data)


@extend_schema(tags=["Post"])
class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer

    def get_serializer_class(self):
        if self.action == "create":
            return PostUploadSerializer
        return super().get_serializer_class()

    @extend_schema(deprecated=True)
    def list(self, request, *args, **kwargs):
        return Response(status=status.HTTP_400_BAD_REQUEST, data="Deprecated API")

    def create(self, request: Request, *args, **kwargs):
        user = request.user
        data = request.data
        topic_id = data.get("topic")
        topic = get_object_or_404(Topic, id=topic_id)

        if not topic.can_be_access_by(user):
            return Response(
                status=status.HTTP_401_UNAUTHORIZED,
                data="This user is not allowed to write a post on this topic",
            )

        if image := request.data.get("image"):
            image: File
            endpoint_url = "https://kr.object.ncloudstorage.com"
            access_key = settings.NCP_ACCESS_KEY
            secret_key = settings.NCP_SECRET_KEY
            bucket_name = "post-image-es"

            s3 = boto3.client(
                "s3",
                endpoint_url=endpoint_url,
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
            )
            image_id = str(uuid.uuid4())
            ext = image.name.split(".")[-1]
            image_filename = f"{image_id}.{ext}"
            s3.upload_fileobj(image.file, bucket_name, image_filename)
            s3.put_object_acl(
                ACL="public-read",
                Bucket=bucket_name,
                Key=image_filename,
            )
            image_url = f"{endpoint_url}/{bucket_name}/{image_filename}"

        serializer = PostSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            data["owner"] = user
            data["image_url"] = image_url if image else None
            res: Post = serializer.create(data)
            return Response(
                status=status.HTTP_201_CREATED, data=PostSerializer(res).data
            )
        else:
            return Response(status=status.HTTP_400_BAD_REQUEST, data=serializer.errors)

    def retrieve(self, request: Request, *args, **kwargs):
        user = request.user
        post: Post = self.get_object()
        topic = post.topic

        if not topic.can_be_access_by(user):
            return Response(
                status=status.HTTP_401_UNAUTHORIZED,
                data="This user is not allowed to read this post",
            )

        return super().retrieve(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        post: Post = self.get_object()
        topic: Topic = post.topic
        if (
            topic.owner == request.user
            or post.owner == request.user
            or TopicGroupUser.objects.filter(
                user=request.user,
                group=TopicGroupUser.GroupChoices.admin,
                topic=topic,
            ).exists()
        ):
            return super().destroy(request, *args, **kwargs)
        else:
            return Response(
                status=status.HTTP_401_UNAUTHORIZED,
                data="This user is not allowed to delete this post",
            )
