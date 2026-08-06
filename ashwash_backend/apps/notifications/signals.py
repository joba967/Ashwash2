import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from apps.courses.models import Course, UserCourseProgress
from apps.appointments.models import Appointment
from apps.community.models import Post, Comment, Report
from apps.knowledge_hub.models import Resource
from apps.mood_tracker.models import MoodLog
from apps.authentication.models import SpecialistProfile
from .services import NotificationManager

logger = logging.getLogger(__name__)
User = get_user_model()

@receiver(post_save, sender=User)
def notify_user_events(sender, instance, created, **kwargs):
    try:
        if created:
            if instance.role == User.Role.SPECIALIST:
                # Specialist applied
                NotificationManager.send_notification(
                    receiver=instance,
                    title="Application Received",
                    body="Thank you for applying as a Specialist! Your profile is pending Administrator review.",
                    notif_type="SYSTEM",
                    related_object_id=instance.id,
                    related_object_type="User"
                )
                # Notify admins
                for admin in User.objects.filter(role=User.Role.ADMIN):
                    NotificationManager.send_notification(
                        receiver=admin,
                        title="New Specialist Application",
                        body=f"Specialist {instance.get_full_name() or instance.username} has applied for verification.",
                        notif_type="SYSTEM",
                        related_object_id=instance.id,
                        related_object_type="User"
                    )
            else:
                # Patient welcome
                NotificationManager.send_notification(
                    receiver=instance,
                    title="Welcome to Ashwash!",
                    body="Your account has been successfully created. Explore mental wellness resources and connect with specialists.",
                    notif_type="SYSTEM"
                )
                # Notify admins
                for admin in User.objects.filter(role=User.Role.ADMIN):
                    NotificationManager.send_notification(
                        receiver=admin,
                        title="New User Registered",
                        body=f"A new user ({instance.username}) has joined the platform.",
                        notif_type="SYSTEM",
                        related_object_id=instance.id,
                        related_object_type="User"
                    )
    except Exception as e:
        logger.error(f"Error in notify_user_events signal: {e}")

@receiver(post_save, sender=SpecialistProfile)
def notify_specialist_profile_status(sender, instance, created, **kwargs):
    try:
        if not created and instance.is_profile_complete:
            # Profile approved / completed
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Profile Approved & Active",
                body="Congratulations! Your specialist profile is verified and you can now accept appointments.",
                notif_type="PROFILE",
                related_object_id=instance.id,
                related_object_type="SpecialistProfile"
            )
    except Exception as e:
        logger.error(f"Error in notify_specialist_profile_status signal: {e}")

@receiver(post_save, sender=Appointment)
def notify_appointment_changes(sender, instance, created, **kwargs):
    try:
        patient_user = instance.user
        specialist_name = instance.specialist.name if instance.specialist else "Specialist"
        
        # Try to find specialist user account
        specialist_user = None
        specialists_users = User.objects.filter(role=User.Role.SPECIALIST)
        for s_user in specialists_users:
            if hasattr(s_user, 'specialist_profile') and s_user.specialist_profile.full_name == specialist_name:
                specialist_user = s_user
                break
        if not specialist_user and specialists_users.exists():
            specialist_user = specialists_users.first()

        if created:
            # Patient Notification
            if patient_user:
                NotificationManager.send_notification(
                    receiver=patient_user,
                    title="Appointment Booked",
                    body=f"Your session with {specialist_name} on {instance.appointment_date} ({instance.time_slot}) has been scheduled.",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
            # Specialist Notification
            if specialist_user:
                NotificationManager.send_notification(
                    receiver=specialist_user,
                    title="New Session Booking",
                    body=f"New appointment booked by {patient_user.get_full_name() or patient_user.username} for {instance.appointment_date} ({instance.time_slot}).",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
            # Admin Notification
            for admin in User.objects.filter(role=User.Role.ADMIN):
                NotificationManager.send_notification(
                    receiver=admin,
                    title="New Appointment Scheduled",
                    body=f"Session booked between {patient_user.username} and {specialist_name}.",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
        else:
            if instance.status == 'completed':
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        title="Session Completed",
                        body=f"Your consultation with {specialist_name} is complete. Please rate your experience!",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
                if specialist_user:
                    NotificationManager.send_notification(
                        receiver=specialist_user,
                        title="Session Marked Completed",
                        body=f"Consultation with {patient_user.username} has been marked as completed.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
            elif instance.status == 'cancelled':
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        title="Appointment Cancelled",
                        body=f"Your session scheduled for {instance.appointment_date} has been cancelled.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
                if specialist_user:
                    NotificationManager.send_notification(
                        receiver=specialist_user,
                        title="Appointment Cancelled",
                        body=f"Session on {instance.appointment_date} with {patient_user.username} was cancelled.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
    except Exception as e:
        logger.error(f"Error in notify_appointment_changes signal: {e}")

@receiver(post_save, sender=Course)
def notify_course_events(sender, instance, created, **kwargs):
    try:
        if created:
            # Notify admins of newly submitted course
            for admin in User.objects.filter(role=User.Role.ADMIN):
                NotificationManager.send_notification(
                    receiver=admin,
                    title="New Course Submitted",
                    body=f"Course '{instance.title_en}' was submitted and is awaiting approval.",
                    notif_type="COURSE",
                    related_object_id=instance.id,
                    related_object_type="Course"
                )
        elif instance.is_approved:
            # Notify instructor if available
            if instance.instructor:
                NotificationManager.send_notification(
                    receiver=instance.instructor,
                    title="Course Approved & Published",
                    body=f"Your course '{instance.title_en}' has been approved and published to students!",
                    notif_type="COURSE",
                    related_object_id=instance.id,
                    related_object_type="Course"
                )
    except Exception as e:
        logger.error(f"Error in notify_course_events signal: {e}")

@receiver(post_save, sender=UserCourseProgress)
def notify_course_progress(sender, instance, created, **kwargs):
    try:
        if created:
            # Enrolled
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Enrolled in Course",
                body=f"You have enrolled in '{instance.course.title_en}'. Start your first lesson today!",
                notif_type="COURSE",
                related_object_id=instance.course.id,
                related_object_type="Course"
            )
            if instance.course.instructor:
                NotificationManager.send_notification(
                    receiver=instance.course.instructor,
                    title="New Student Enrolled",
                    body=f"{instance.user.username} enrolled in your course '{instance.course.title_en}'.",
                    notif_type="COURSE",
                    related_object_id=instance.course.id,
                    related_object_type="Course"
                )
        elif instance.is_completed:
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Course Completed! 🎓",
                body=f"Congratulations! You completed '{instance.course.title_en}'. Your certificate is ready to view.",
                notif_type="COURSE",
                related_object_id=instance.course.id,
                related_object_type="Course"
            )
    except Exception as e:
        logger.error(f"Error in notify_course_progress signal: {e}")

@receiver(post_save, sender=Post)
def notify_community_post(sender, instance, created, **kwargs):
    try:
        if created:
            # Notify all specialists
            for spec in User.objects.filter(role=User.Role.SPECIALIST):
                NotificationManager.send_notification(
                    receiver=spec,
                    title="New Community Discussion",
                    body=f"A patient posted in community: '{instance.content[:60]}...'. Reply to support them.",
                    notif_type="COMMUNITY",
                    related_object_id=instance.id,
                    related_object_type="Post"
                )
    except Exception as e:
        logger.error(f"Error in notify_community_post signal: {e}")

@receiver(post_save, sender=Comment)
def notify_community_comment(sender, instance, created, **kwargs):
    try:
        if created:
            post_author = instance.post.author
            if post_author and post_author != instance.author:
                NotificationManager.send_notification(
                    receiver=post_author,
                    title="New Reply to Your Post",
                    body=f"{instance.author_alias} replied: '{instance.content[:60]}...'",
                    notif_type="COMMUNITY",
                    related_object_id=instance.post.id,
                    related_object_type="Post"
                )
    except Exception as e:
        logger.error(f"Error in notify_community_comment signal: {e}")

@receiver(post_save, sender=Report)
def notify_community_report(sender, instance, created, **kwargs):
    try:
        if created:
            for admin in User.objects.filter(role=User.Role.ADMIN):
                NotificationManager.send_notification(
                    receiver=admin,
                    title="Community Content Reported",
                    body=f"A post was reported for: {instance.reason[:60]}",
                    notif_type="COMMUNITY",
                    related_object_id=instance.post.id,
                    related_object_type="Post"
                )
    except Exception as e:
        logger.error(f"Error in notify_community_report signal: {e}")

@receiver(post_save, sender=Resource)
def notify_knowledge_hub_resource(sender, instance, created, **kwargs):
    try:
        if created:
            # Notify active patients about new resource
            for patient in User.objects.filter(role=User.Role.PATIENT)[:50]:
                NotificationManager.send_notification(
                    receiver=patient,
                    title=f"New {instance.resource_type.capitalize()} in Knowledge Hub",
                    body=f"Check out: '{instance.title_en}'",
                    notif_type="KNOWLEDGE_HUB",
                    related_object_id=instance.id,
                    related_object_type="Resource"
                )
    except Exception as e:
        logger.error(f"Error in notify_knowledge_hub_resource signal: {e}")

@receiver(post_save, sender=MoodLog)
def notify_mood_log(sender, instance, created, **kwargs):
    try:
        if created:
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Mood Tracker Updated 🌟",
                body=f"You logged your mood as '{instance.mood}'. Keep building your daily wellness habit!",
                notif_type="GENERAL",
                related_object_id=instance.id,
                related_object_type="MoodLog"
            )
    except Exception as e:
        logger.error(f"Error in notify_mood_log signal: {e}")
