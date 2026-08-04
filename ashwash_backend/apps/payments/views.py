import uuid
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import PaymentTransaction
from .serializers import PaymentTransactionSerializer

class InitiatePaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        method = request.data.get('method')
        amount = request.data.get('amount')
        purpose = request.data.get('purpose', 'General Service')

        if not method or not amount:
            return Response({'error': 'Method and amount are required'}, status=status.HTTP_400_BAD_REQUEST)

        tx_id = f"TXN-{uuid.uuid4().hex[:10].upper()}"

        transaction = PaymentTransaction.objects.create(
            user=request.user,
            method=method,
            amount=amount,
            purpose=purpose,
            transaction_id=tx_id,
            status='success'
        )

        return Response(PaymentTransactionSerializer(transaction).data, status=status.HTTP_201_CREATED)

class UserPaymentHistoryView(generics.ListAPIView):
    serializer_class = PaymentTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PaymentTransaction.objects.filter(user=self.request.user)
