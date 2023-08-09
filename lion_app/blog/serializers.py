from rest_framework import serializers
from pymongo import MongoClient


client = MongoClient(host="mongo")
db = client.likelion


class BlogSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=100)
    content = serializers.CharField()
    author = serializers.CharField(max_length=100)

    def create(self, validated_data):
        return db.blogs.insert_one(validated_data)
    
    def save(self, **kwargs):
        # Find item
        # if exists()
        # update
        # else
        # create
        
        return 
    