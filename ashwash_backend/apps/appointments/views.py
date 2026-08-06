from rest_framework import generics, permissions
from .models import Specialist, Appointment
from .serializers import SpecialistSerializer, AppointmentSerializer

class SpecialistListView(generics.ListAPIView):
    serializer_class = SpecialistSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Specialist.objects.all()
        loc_type = self.request.query_params.get('type') # local, international
        category_id = self.request.query_params.get('category_id')
        search = self.request.query_params.get('search') or self.request.query_params.get('name') or self.request.query_params.get('q')

        if loc_type and loc_type != 'all':
            queryset = queryset.filter(location_type=loc_type)
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(name__icontains=search) | 
                Q(title_en__icontains=search) | 
                Q(title_bn__icontains=search) | 
                Q(bio_en__icontains=search) | 
                Q(bio_bn__icontains=search)
            )

        return queryset

class SpecialistDetailView(generics.RetrieveAPIView):
    queryset = Specialist.objects.all()
    serializer_class = SpecialistSerializer
    permission_classes = [permissions.AllowAny]

class AppointmentListCreateView(generics.ListCreateAPIView):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role in ['SPECIALIST', 'DOCTOR']:
            from django.db.models import Q
            full_n = f"{user.first_name} {user.last_name}".strip() or user.username
            return Appointment.objects.filter(
                Q(specialist__name__icontains=user.first_name) | 
                Q(specialist__name__icontains=user.username) | 
                Q(user=user)
            )
        return Appointment.objects.filter(user=user)

    def perform_create(self, serializer):
        appointment = serializer.save(user=self.request.user)

        # Trigger 4: Notify patient & specialist on session booking request
        try:
            from apps.notifications.views import send_notification
            spec_name = appointment.specialist.name if appointment.specialist else 'Specialist'
            patient_name = self.request.user.get_full_name() or self.request.user.username
            app_date = getattr(appointment, 'appointment_date', getattr(appointment, 'date', 'Scheduled Date'))
            app_time = getattr(appointment, 'time_slot', getattr(appointment, 'time', 'Scheduled Time'))
            
            # 1. Patient notification
            send_notification(
                recipient=self.request.user,
                title_en=f"Session Booking Requested 🩺",
                title_bn=f"সেশন বুকিং রিকোয়েস্ট পাঠানো হয়েছে 🩺",
                message_en=f"Your appointment request with {spec_name} for {app_date} ({app_time}) has been received.",
                message_bn=f"{spec_name}-এর সাথে আপনার সেশন বুকিং রিকোয়েস্টটি গৃহীত হয়েছে ({app_date})।",
                category='APPOINTMENT'
            )

            # 2. Specialist notification (if specialist user exists)
            from django.contrib.auth import get_user_model
            User = get_user_model()
            spec_user = None
            if appointment.specialist:
                spec_first_word = appointment.specialist.name.split()[0] if appointment.specialist.name else ''
                spec_user = User.objects.filter(role__in=['SPECIALIST', 'DOCTOR'], first_name__icontains=spec_first_word).first()
            if not spec_user:
                spec_user = User.objects.filter(role__in=['SPECIALIST', 'DOCTOR']).first()

            if spec_user:
                send_notification(
                    recipient=spec_user,
                    sender=self.request.user,
                    title_en=f"New Session Request from {patient_name} 🩺",
                    title_bn=f"{patient_name}-এর কাছ থেকে সেশন বুকিং রিকোয়েস্ট 🩺",
                    message_en=f"Patient {patient_name} requested a session for {app_date} ({app_time}).",
                    message_bn=f"পেশেন্ট {patient_name} {app_date} ({app_time})-এর জন্য সেশন বুক করতে চেয়েছেন।",
                    category='APPOINTMENT'
                )
        except Exception:
            pass

class AppointmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        old_status = serializer.instance.status
        appointment = serializer.save()

        # Trigger 5: Notify patient when specialist confirms session
        try:
            if old_status != 'confirmed' and appointment.status == 'confirmed':
                from apps.notifications.views import send_notification
                spec_name = appointment.specialist.name if appointment.specialist else 'Specialist'
                app_date = getattr(appointment, 'appointment_date', getattr(appointment, 'date', 'Scheduled Date'))
                app_time = getattr(appointment, 'time_slot', getattr(appointment, 'time', 'Scheduled Time'))
                send_notification(
                    recipient=appointment.user,
                    sender=self.request.user,
                    title_en=f"Session Confirmed! 🩺",
                    title_bn=f"সেশন কনফার্ম করা হয়েছে! 🩺",
                    message_en=f"Your appointment with {spec_name} on {app_date} at {app_time} is confirmed.",
                    message_bn=f"{spec_name}-এর সাথে {app_date} {app_time}-এর সেশনটি নিশ্চিত করা হয়েছে।",
                    category='APPOINTMENT'
                )
        except Exception:
            pass

