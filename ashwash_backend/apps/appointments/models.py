from django.db import models
from django.conf import settings
from apps.authentication.models import Category

class Specialist(models.Model):
    LOCATION_TYPES = [
        ('local', 'Local'),
        ('international', 'International'),
    ]

    name = models.CharField(max_length=150)
    title_en = models.CharField(max_length=150) # e.g. Clinical Psychologist
    title_bn = models.CharField(max_length=150)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='specialists')
    bio_en = models.TextField()
    bio_bn = models.TextField()
    experience_years = models.IntegerField(default=10)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.9)
    fee_bdt = models.IntegerField(default=1500)
    location_type = models.CharField(max_length=20, choices=LOCATION_TYPES, default='local')
    is_available = models.BooleanField(default=True)
    is_online = models.BooleanField(default=True)
    avatar_url = models.URLField(blank=True, default='')

    def __str__(self):
        return f"{self.name} ({self.title_en})"

class Appointment(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='appointments')
    specialist = models.ForeignKey(Specialist, on_delete=models.CASCADE, related_name='appointments')
    appointment_date = models.DateField()
    time_slot = models.CharField(max_length=50) # e.g. "10:00 AM - 11:00 AM"
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='confirmed')
    meeting_link = models.URLField(default='https://meet.google.com/ash-wash-wellness')
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-appointment_date']

    def __str__(self):
        return f"Appointment: {self.user.username} with {self.specialist.name} on {self.appointment_date}"
