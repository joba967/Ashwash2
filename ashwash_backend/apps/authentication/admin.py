from django.contrib import admin
from .models import User, Category, PatientProfile, SpecialistProfile

admin.site.register(User)
admin.site.register(Category)
admin.site.register(PatientProfile)
admin.site.register(SpecialistProfile)
