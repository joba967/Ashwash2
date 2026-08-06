from rest_framework import serializers
from .models import Resource

class ResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Resource
        fields = [
            'id', 'title_en', 'title_bn', 'summary_en', 'summary_bn',
            'content_en', 'content_bn', 'resource_type', 'media_url',
            'media_file', 'duration_minutes', 'is_premium', 'created_at'
        ]

