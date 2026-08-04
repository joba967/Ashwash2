from django.db import models
from django.conf import settings

class Notification(models.Model):
    CATEGORY_CHOICES = (
        ('COURSE', 'Courses'),
        ('SYSTEM', 'System & Appointments'),
        ('COMMUNITY', 'Community'),
        ('REMINDER', 'Reminders'),
    )

    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='sent_notifications')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    message_en = models.TextField()
    message_bn = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='SYSTEM')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification to {self.recipient.username}: {self.title_en}"
