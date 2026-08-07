import uuid
import random
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import PaymentTransaction
from .serializers import PaymentTransactionSerializer

class InitiatePaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        method = request.data.get('method', 'bkash')
        amount = request.data.get('amount')
        purpose = request.data.get('purpose', 'General Service')

        if not amount:
            return Response({'error': 'Amount is required'}, status=status.HTTP_400_BAD_REQUEST)

        tx_id = f"TXN-{uuid.uuid4().hex[:10].upper()}"

        transaction = PaymentTransaction.objects.create(
            user=request.user,
            method=method.lower(),
            amount=amount,
            purpose=purpose,
            transaction_id=tx_id,
            status='success'
        )

        return Response(PaymentTransactionSerializer(transaction).data, status=status.HTTP_201_CREATED)

class bKashExecutePaymentAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = request.user
        if not user.is_authenticated and token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                from django.contrib.auth import get_user_model
                User = get_user_model()
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user or not user.is_authenticated:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.filter(role='PATIENT').first() or User.objects.first()

        amount = request.data.get('amount', 1500)
        purpose = request.data.get('purpose', 'Patient Service Payment')
        course_id = request.data.get('course_id')
        appointment_id = request.data.get('appointment_id')
        mobile = request.data.get('mobile_number', '01770618575')

        tx_id = f"BKASH{random.randint(10000000, 99999999)}"

        transaction = PaymentTransaction.objects.create(
            user=user,
            method='bkash',
            amount=amount,
            purpose=purpose,
            transaction_id=tx_id,
            status='success'
        )

        # Enforce Course Enrollment or Appointment Booking confirmation if IDs provided
        if course_id:
            try:
                from apps.courses.models import Course, UserCourseProgress
                course = Course.objects.get(id=course_id)
                UserCourseProgress.objects.get_or_create(
                    user=user,
                    course=course,
                    defaults={'progress_percentage': 0, 'completed_lessons_count': 0}
                )
            except Exception:
                pass

        if appointment_id:
            try:
                from apps.appointments.models import AppointmentBooking
                AppointmentBooking.objects.filter(id=appointment_id).update(status='Confirmed')
            except Exception:
                pass

        # Send notification to patient
        try:
            from apps.notifications.views import send_notification
            send_notification(
                recipient=user,
                sender=None,
                title_en=f"bKash Payment Successful: ৳{amount} 💳",
                title_bn=f"বিকাশ পেমেন্ট সফল হয়েছে: ৳{amount} 💳",
                message_en=f"Your payment of ৳{amount} for '{purpose}' via bKash (TrxID: {tx_id}) was confirmed.",
                message_bn=f"আপনার '{purpose}'-এর জন্য ৳{amount} বিকাশ পেমেন্ট (TrxID: {tx_id}) সফল হয়েছে।",
                category='PAYMENT'
            )
        except Exception:
            pass

        return Response({
            'message': 'bKash Payment completed successfully!',
            'transaction_id': tx_id,
            'amount': float(amount),
            'method': 'bKash',
            'status': 'SUCCESS'
        }, status=status.HTTP_201_CREATED)

class NagadExecutePaymentAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = request.user
        if not user.is_authenticated and token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                from django.contrib.auth import get_user_model
                User = get_user_model()
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user or not user.is_authenticated:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.filter(role='PATIENT').first() or User.objects.first()

        amount = request.data.get('amount', 1500)
        purpose = request.data.get('purpose', 'Patient Service Payment')
        course_id = request.data.get('course_id')
        appointment_id = request.data.get('appointment_id')
        mobile = request.data.get('mobile_number', '01812345678')

        tx_id = f"NAGAD{random.randint(10000000, 99999999)}"

        transaction = PaymentTransaction.objects.create(
            user=user,
            method='nagad',
            amount=amount,
            purpose=purpose,
            transaction_id=tx_id,
            status='success'
        )

        if course_id:
            try:
                from apps.courses.models import Course, UserCourseProgress
                course = Course.objects.get(id=course_id)
                UserCourseProgress.objects.get_or_create(
                    user=user,
                    course=course,
                    defaults={'progress_percentage': 0, 'completed_lessons_count': 0}
                )
            except Exception:
                pass

        if appointment_id:
            try:
                from apps.appointments.models import AppointmentBooking
                AppointmentBooking.objects.filter(id=appointment_id).update(status='Confirmed')
            except Exception:
                pass

        try:
            from apps.notifications.views import send_notification
            send_notification(
                recipient=user,
                sender=None,
                title_en=f"Nagad Payment Successful: ৳{amount} 💳",
                title_bn=f"নগদ পেমেন্ট সফল হয়েছে: ৳{amount} 💳",
                message_en=f"Your payment of ৳{amount} for '{purpose}' via Nagad (TrxID: {tx_id}) was confirmed.",
                message_bn=f"আপনার '{purpose}'-এর জন্য ৳{amount} নগদ পেমেন্ট (TrxID: {tx_id}) সফল হয়েছে।",
                category='PAYMENT'
            )
        except Exception:
            pass

        return Response({
            'message': 'Nagad Payment completed successfully!',
            'transaction_id': tx_id,
            'amount': float(amount),
            'method': 'Nagad',
            'status': 'SUCCESS'
        }, status=status.HTTP_201_CREATED)

class UserPaymentHistoryView(generics.ListAPIView):
    serializer_class = PaymentTransactionSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = self.request.user
        if not user.is_authenticated and token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                from django.contrib.auth import get_user_model
                User = get_user_model()
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if user and user.is_authenticated:
            return PaymentTransaction.objects.filter(user=user)
        return PaymentTransaction.objects.all()[:20]
