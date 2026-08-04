from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer

def send_notification(recipient, title_en, title_bn, message_en, message_bn, category='SYSTEM', sender=None):
    """
    Helper function to safely dispatch in-app notifications.
    """
    if not recipient:
        return None
    try:
        return Notification.objects.create(
            recipient=recipient,
            sender=sender,
            title_en=title_en,
            title_bn=title_bn,
            message_en=message_en,
            message_bn=message_bn,
            category=category
        )
    except Exception:
        return None

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        category = self.request.query_params.get('category')
        qs = Notification.objects.filter(recipient=self.request.user)
        if category and category != 'ALL':
            qs = qs.filter(category=category)
        return qs

class NotificationMarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, recipient=request.user)
            notification.is_read = True
            notification.save()
            return Response({'status': 'marked as read'})
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)

class NotificationMarkAllReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'all marked as read'})
