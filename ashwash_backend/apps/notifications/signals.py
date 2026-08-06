from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from apps.courses.models import Course, UserCourseProgress
from apps.appointments.models import Appointment
from .services import NotificationManager

User = get_user_model()

@receiver(post_save, sender=User)
def notify_new_user_registration(sender, instance, created, **kwargs):
    if created:
        NotificationManager.send_notification(
            receiver=instance,
            title="Welcome to Ashwash!",
            body="Your account has been successfully created.",
            notif_type="SYSTEM"
        )
        # Notify admins
        admins = User.objects.filter(role=User.Role.ADMIN)
        for admin in admins:
            NotificationManager.send_notification(
                receiver=admin,
                title="New User Registered",
                body=f"A new user ({instance.username}) has joined the platform.",
                notif_type="SYSTEM",
                related_object_id=instance.id,
                related_object_type="User"
            )

@receiver(post_save, sender=Appointment)
def notify_appointment_changes(sender, instance, created, **kwargs):
    if created:
        # Notify Specialist
        NotificationManager.send_notification(
            receiver=instance.specialist.user,
            title="New Appointment Booked",
            body=f"You have a new session booked with {instance.patient.user.first_name}.",
            notif_type="APPOINTMENT",
            related_object_id=instance.id,
            related_object_type="Appointment"
        )
        # Notify Patient
        NotificationManager.send_notification(
            receiver=instance.patient.user,
            title="Session Confirmed",
            body=f"Your session with Dr. {instance.specialist.user.last_name} is confirmed.",
            notif_type="APPOINTMENT",
            related_object_id=instance.id,
            related_object_type="Appointment"
        )
