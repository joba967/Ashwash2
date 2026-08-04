from django.urls import path
from .views import InitiatePaymentView, UserPaymentHistoryView

urlpatterns = [
    path('initiate/', InitiatePaymentView.as_view(), name='initiate_payment'),
    path('history/', UserPaymentHistoryView.as_view(), name='payment_history'),
]
