from django.urls import path
from .views import DashboardSummaryView
from .specialist_views import SpecialistDashboardSummaryView
from .web_views import (
    AdminMetricsAPIView, AdminVerifySpecialistAPIView, AdminToggleUserStatusAPIView,
    AdminSpecialistsListAPIView
)

urlpatterns = [
    path('summary/', DashboardSummaryView.as_view(), name='dashboard_summary'),
    path('overview/', DashboardSummaryView.as_view(), name='dashboard_overview'),
    path('specialist-summary/', SpecialistDashboardSummaryView.as_view(), name='specialist_dashboard_summary'),
    path('admin-metrics/', AdminMetricsAPIView.as_view(), name='admin_metrics_api'),
    path('admin-specialists/', AdminSpecialistsListAPIView.as_view(), name='admin_specialists_api'),
    path('admin-verify-specialist/<int:pk>/', AdminVerifySpecialistAPIView.as_view(), name='admin_verify_specialist_api'),
    path('admin-toggle-user/<int:pk>/', AdminToggleUserStatusAPIView.as_view(), name='admin_toggle_user_api'),
]
