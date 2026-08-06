from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from .models import Notification, FCMDevice
from .serializers import NotificationSerializer, FCMDeviceSerializer
from .services import NotificationManager, send_notification

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(receiver=self.request.user, is_deleted=False).order_by('-created_at')

class UnreadNotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(receiver=self.request.user, is_read=False, is_deleted=False).order_by('-created_at')

class NotificationCountView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(receiver=request.user, is_read=False, is_deleted=False).count()
        return Response({'unread_count': count})

class MarkNotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, receiver=request.user, is_deleted=False)
            notif.is_read = True
            notif.save()
            return Response({'status': 'marked as read'})
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)

class MarkAllNotificationsReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(receiver=request.user, is_read=False, is_deleted=False).update(is_read=True)
        return Response({'status': 'all marked as read'})

class DeleteNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, receiver=request.user, is_deleted=False)
            notif.is_deleted = True
            notif.save()
            return Response({'status': 'deleted'})
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)

class DeleteAllNotificationsView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        Notification.objects.filter(receiver=request.user, is_deleted=False).update(is_deleted=True)
        return Response({'status': 'all deleted'})

class RegisterFCMDeviceView(generics.CreateAPIView):
    serializer_class = FCMDeviceSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        fcm_token = serializer.validated_data.get('fcm_token')
        device_type = serializer.validated_data.get('device_type', 'web')
        # Update or create
        FCMDevice.objects.update_or_create(
            user=self.request.user,
            fcm_token=fcm_token,
            defaults={'device_type': device_type, 'is_active': True}
        )

