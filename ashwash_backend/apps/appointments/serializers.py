from rest_framework import serializers
from .models import Specialist, Appointment

class SpecialistSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.title_en', read_only=True, allow_null=True)

    class Meta:
        model = Specialist
        fields = [
            'id', 'name', 'title_en', 'title_bn', 'category', 'category_name',
            'bio_en', 'bio_bn', 'experience_years', 'rating', 'fee_bdt',
            'location_type', 'is_available', 'is_online', 'avatar_url'
        ]

class AppointmentSerializer(serializers.ModelSerializer):
    specialist = SpecialistSerializer(read_only=True)
    specialist_id = serializers.PrimaryKeyRelatedField(
        queryset=Specialist.objects.all(), source='specialist', write_only=True
    )

    class Meta:
        model = Appointment
        fields = [
            'id', 'user', 'specialist', 'specialist_id', 'appointment_date',
            'time_slot', 'status', 'meeting_link', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'meeting_link', 'created_at']
