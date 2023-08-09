from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework import status

from .serializers import BlogSerializer


class BlogViewSet(ViewSet):
    serializer_class = BlogSerializer

    def list(self, request):
        return Response()

    def create(self, request):
        """
        request.data = {
            "title": "My second blog",
            "content": "This is my second blog",
            "author": "lion",
        }
        """
        serializer = BlogSerializer(data=request.data)
        if serializer.is_valid():
            serializer.create(serializer.validated_data)
            return Response(status=status.HTTP_201_CREATED, data=serializer.data)
        else:
            return Response(status=status.HTTP_400_BAD_REQUEST, data=serializer.errors)

    def update(self, request):
        ...

    def retrieve(self, request):
        ...

    def destroy(self, request):
        ...
