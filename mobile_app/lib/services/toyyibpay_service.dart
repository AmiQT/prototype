import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/payment_config.dart';

class ToyyibPayService {
  /// Create a bill on ToyyibPay and return the Bill Code
  Future<String?> createBill({
    required String billName,
    required String billDescription,
    required double billAmount,
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    try {
      // Validate phone number - ToyyibPay requires valid phone
      final validPhone = userPhone.isNotEmpty ? userPhone : '0123456789';

      // Truncate billName to max 30 chars (ToyyibPay limit)
      final truncatedBillName =
          billName.length > 30 ? '${billName.substring(0, 27)}...' : billName;

      debugPrint(
          'ToyyibPay: Creating bill for $truncatedBillName (RM $billAmount)');
      debugPrint('ToyyibPay: Using phone: $validPhone');

      final requestBody = {
        'userSecretKey': ToyyibPayConfig.userSecretKey,
        'categoryCode': ToyyibPayConfig.categoryCode,
        'billName': truncatedBillName,
        'billDescription': billDescription,
        'billPriceSetting': '1', // Fixed amount
        'billPayorInfo': '1', // Valid payor info required
        'billAmount': (billAmount * 100).toStringAsFixed(0), // Amount in cents
        'billReturnUrl':
            'https://toyyibpay.com', // Will be intercepted by WebView
        'billCallbackUrl': 'https://toyyibpay.com', // Optional callback
        'billExternalReferenceNo':
            DateTime.now().millisecondsSinceEpoch.toString(),
        'billTo': userName,
        'billEmail': userEmail,
        'billPhone': validPhone,
        'billSplitPayment': '0',
        'billPaymentChannel': '0', // 0 = FPX, 2 = Credit Card
        'billContentEmail': 'Thank you for your payment!',
        'billChargeToCustomer': '1', // 1 = Customer pays fee, 2 = Merchant pays
      };

      debugPrint('ToyyibPay: Request URL: ${ToyyibPayConfig.createBill}');
      debugPrint('ToyyibPay: Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(ToyyibPayConfig.createBill),
        body: requestBody,
      );

      debugPrint('ToyyibPay Response Status: ${response.statusCode}');
      debugPrint('ToyyibPay Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // ToyyibPay returns a JSON array or object depending on success/error
        // Success example: [{"BillCode":"8p7s6d5f"}]
        final dynamic data = json.decode(response.body);
        debugPrint('ToyyibPay Parsed Data: $data');

        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          if (firstItem is Map && firstItem.containsKey('BillCode')) {
            debugPrint('✅ ToyyibPay BillCode: ${firstItem['BillCode']}');
            return firstItem['BillCode'];
          } else {
            // Error response from ToyyibPay
            debugPrint('❌ ToyyibPay API Error: $firstItem');
            return null;
          }
        } else if (data is Map && data.containsKey('BillCode')) {
          debugPrint('✅ ToyyibPay BillCode: ${data['BillCode']}');
          return data['BillCode'];
        }
      }

      debugPrint(
          '❌ ToyyibPay Error: Invalid response format or status code ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ ToyyibPay Exception: $e');
      return null;
    }
  }

  /// Get the full payment URL for a given Bill Code
  String getPaymentUrl(String billCode) {
    return '${ToyyibPayConfig.baseUrl}/$billCode';
  }
}
