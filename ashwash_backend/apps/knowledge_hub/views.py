from rest_framework import generics, permissions
from .models import Resource
from .serializers import ResourceSerializer

class ResourceListView(generics.ListAPIView):
    serializer_class = ResourceSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Resource.objects.all()
        res_type = self.request.query_params.get('type')
        is_premium = self.request.query_params.get('is_premium')

        if res_type and res_type != 'all':
            queryset = queryset.filter(resource_type=res_type)
        if is_premium is not None:
            queryset = queryset.filter(is_premium=(is_premium.lower() == 'true'))

        return queryset

class ResourceDetailView(generics.RetrieveAPIView):
    queryset = Resource.objects.all()
    serializer_class = ResourceSerializer
    permission_classes = [permissions.AllowAny]
