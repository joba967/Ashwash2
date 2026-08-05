from django.urls import path
from .views import DashboardSummaryView
from .specialist_views import SpecialistDashboardSummaryView
from apps.dashboard.web_views import (
    AdminMetricsAPIView, AdminVerifySpecialistAPIView, AdminToggleUserStatusAPIView,
    AdminSpecialistsListAPIView, AdminUsersListAPIView, AdminUpdateProfileAPIView,
    SpecialistUpdateProfileAPIView
)

urlpatterns = [
    path('summary/', DashboardSummaryView.as_view(), name='dashboard_summary'),
    path('overview/', DashboardSummaryView.as_view(), name='dashboard_overview'),
    path('specialist-summary/', SpecialistDashboardSummaryView.as_view(), name='specialist_dashboard_summary'),
    path('admin-metrics/', AdminMetricsAPIView.as_view(), name='admin_metrics_api'),
    path('admin-specialists/', AdminSpecialistsListAPIView.as_view(), name='admin_specialists_api'),
    path('admin-users/', AdminUsersListAPIView.as_view(), name='admin_users_api'),
    path('admin-update-profile/', AdminUpdateProfileAPIView.as_view(), name='admin_update_profile_api'),
    path('specialist-update-profile/', SpecialistUpdateProfileAPIView.as_view(), name='specialist_update_profile_api'),
    path('admin-verify-specialist/<int:pk>/', AdminVerifySpecialistAPIView.as_view(), name='admin_verify_specialist_api'),
    path('admin-toggle-user/<int:pk>/', AdminToggleUserStatusAPIView.as_view(), name='admin_toggle_user_api'),
]
