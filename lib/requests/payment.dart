import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Modelos de Payload para as requisições

class CustomerPayload {
  String email;
  final String name;
  final String document;
  final String? phone;

  CustomerPayload({
    required this.email,
    required this.name,
    required this.document,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'document': document,
      if (phone != null) 'phone': phone,
    };
  }
}

class CardPayload {
  final String paymentMethodId;

  CardPayload({required this.paymentMethodId});

  Map<String, dynamic> toJson() {
    return {'payment_method_id': paymentMethodId};
  }
}

class PaymentPayload {
  final String type; // 'pix' | 'credit_card' | 'debit_card' | 'boleto'
  final String orderId;
  final String paymentMethodId;
  final double amount;
  final CustomerPayload customer;
  final String? vaultToken;
  final int? installments;
  final CardPayload? card;
  final String? expirationTime;
  final String? description;

  PaymentPayload({
    required this.type,
    required this.orderId,
    required this.paymentMethodId,
    required this.amount,
    required this.customer,
    this.vaultToken,
    this.installments,
    this.card,
    this.expirationTime,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'order_id': orderId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'customer': customer.toJson(),
      if (vaultToken != null) 'vault_token': vaultToken,
      if (installments != null) 'installments': installments,
      if (card != null) 'card': card!.toJson(),
      if (expirationTime != null) 'expiration_time': expirationTime,
      if (description != null) 'description': description,
    };
  }
}

class VaultTokenResponse {
  final String vaultToken;
  final String lastFour;
  final String brand;
  final String expiresAt;
  final String? cardId;

  VaultTokenResponse({
    required this.vaultToken,
    required this.lastFour,
    required this.brand,
    required this.expiresAt,
    this.cardId,
  });

  factory VaultTokenResponse.fromJson(Map<String, dynamic> json) {
    return VaultTokenResponse(
      vaultToken: json['vault_token'],
      lastFour: json['last_four'] ?? '',
      brand: json['brand'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      cardId: json['card_id'],
    );
  }
}

class CardDetails {
  final String cardNumber;
  final String securityCode;
  final String expirationMonth;
  final String expirationYear;
  final String cardholderName;
  final String? documentType;
  final String documentNumber;
  final bool? saveCard;
  final String? customerEmail;
  final String? paymentType;

  CardDetails({
    required this.cardNumber,
    required this.securityCode,
    required this.expirationMonth,
    required this.expirationYear,
    required this.cardholderName,
    this.documentType = 'CPF',
    required this.documentNumber,
    this.saveCard,
    this.customerEmail,
    this.paymentType,
  });
}

// Adaptado da classe PaymentService do arquivo matheuso.ts

class PaymentService {
  static String baseUrl = 'http://oblynx.com:5000';

  final String tenantId;
  String token = '';
  Map<String, dynamic>? activeGateway;
  bool loadingGateway = false;

  PaymentService({required this.tenantId});

  Future<void> getToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login_usuario'),
      body: jsonEncode({
        "api": "ecommerce",
        "user": "brendoudias.dev@gmail.com",
        "pass": "171195",
      }),
    );
    if (response.statusCode == 200) {
      token = jsonDecode(response.body)['access_token'];
    } else {
      throw Exception('Failed to load token');
    }
  }

  /// Carrega o gateway de pagamento ativo para o tenant atual.
  Future<Map<String, dynamic>?> loadActiveGateway() async {
    loadingGateway = true;
    try {
      final responseT = await http.post(
        Uri.parse('$baseUrl/api/auth/login_usuario'),
        body: jsonEncode({
          "api": "ecommerce",
          "user": "brendoudias.dev@gmail.com",
          "pass": "171195",
        }),
      );

      // Como o LynxbdService é um serviço de banco de dados do Angular frontend,
      // realizamos uma consulta simulada via HTTP ou geramos um mock padrão.
      final url = Uri.parse('$baseUrl/api/lynxbd/query');
      final body = jsonEncode({
        "q": "SELECT * FROM payment_gateways WHERE tenant_id = '$tenantId'",
      });
      print(tenantId);
      print(token);
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Bearer ${jsonDecode(responseT.body)['access_token']}',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        activeGateway = data;
        return data;
      }

      // Fallback sandbox caso o endpoint não exista no backend
      activeGateway = {
        'tenant_id': tenantId,
        'is_active': 1,
        'public_key': 'TEST-PUBLIC-KEY-MOCK',
        'environment': 'sandbox',
      };
      return activeGateway;
    } catch (err) {
      print('Erro ao carregar gateway ativo: $err');
      activeGateway = null;
      return null;
    } finally {
      loadingGateway = false;
    }
  }

  /// Obtém a chave pública do gateway ativo para tokenização.
  Future<String> getPublicKey() async {
    final gw = activeGateway ?? await loadActiveGateway();
    if (gw != null && gw['public_key'] != null) {
      return gw['public_key'];
    }

    try {
      final url = Uri.parse('$baseUrl/api/payments/public-key');
      final response = await http.get(url, headers: {'X-Tenant-ID': tenantId});
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['public_key'] ?? '';
      }
    } catch (err) {
      print('API de public-key indisponível, usando fallback local: $err');
    }
    return gw?['public_key'] ?? 'TEST-PUBLIC-KEY-MOCK';
  }

  /// Envia a transação de pagamento para a API com timeout estrito de 15 segundos.
  /// Para cartão de crédito, o payload deve conter `vault_token` obtido via `tokenizeVault()`.
  Future<Map<String, dynamic>> processPayment(PaymentPayload payload) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'X-Tenant-ID': tenantId,
    };

    String url = '$baseUrl/api/payments';
    if (payload.type == 'credit_card' || payload.type == 'debit_card') {
      url = '$baseUrl/api/payments/card';
    }

    // Detecta se estamos em modo sandbox e sanitiza o e-mail do cliente caso necessário
    var gateway = activeGateway;
    if (gateway == null) {
      gateway = await loadActiveGateway();
    }
    final isSandbox = gateway != null
        ? gateway['environment'] == 'sandbox'
        : true;

    if (isSandbox && payload.customer.email.isNotEmpty) {
      final email = payload.customer.email;
      if (!email.endsWith('@testuser.com')) {
        final parts = email.split('@');
        final localPart = parts[0].replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '',
        ); // Remove caracteres especiais
        payload.customer.email = '$localPart@testuser.com';
        print(
          '🔧 [PaymentService] Sandbox mode detected. Automatically rewritten customer email to: ${payload.customer.email}',
        );
      }
    }

    print(
      '🚀 [PaymentService] Attempting payment request to: $url (Timeout: 15s)',
    );

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic responseBody = jsonDecode(response.body);
      print(responseBody);
      print(jsonDecode(responseBody['qr_code']));
      print(response.statusCode);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (responseBody != null && responseBody is Map) {
          final backendError =
              responseBody['error'] ??
              responseBody['status_detail'] ??
              responseBody['message'];
          if (backendError != null) {
            throw Exception(backendError);
          }
        }
        throw Exception(
          'Erro no processamento do pagamento no gateway (Status: ${response.statusCode}).',
        );
      }

      if (responseBody == null) {
        throw Exception('Nenhuma resposta recebida do servidor de pagamentos.');
      }

      if (responseBody['success'] != true) {
        throw Exception(
          responseBody['error'] ??
              responseBody['status_detail'] ??
              'Erro no processamento do pagamento no gateway.',
        );
      }

      return responseBody;
    } catch (err) {
      print('❌ [PaymentService] Payment request failed or timed out: $err');
      if (err is TimeoutException) {
        throw Exception(
          'O processamento do pagamento excedeu o limite de tempo de 15 segundos. O carrinho foi mantido salvo para que você possa tentar novamente.',
        );
      }
      rethrow;
    }
  }

  /// Tokeniza um cartão de crédito NOVO usando o endpoint Vault do backend.
  /// O backend abstrai o SDK do Mercado Pago — nenhum script externo é necessário no frontend.
  Future<VaultTokenResponse> tokenizeVault(CardDetails cardDetails) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Tenant-ID': tenantId,
    };

    final Map<String, dynamic> body = {
      'card_number': cardDetails.cardNumber.replaceAll(RegExp(r'\s+'), ''),
      'security_code': cardDetails.securityCode,
      'expiration_month': cardDetails.expirationMonth,
      'expiration_year': cardDetails.expirationYear,
      'cardholder_name': cardDetails.cardholderName,
      'document_type': cardDetails.documentType ?? 'CPF',
      'document_number': cardDetails.documentNumber,
    };

    if (cardDetails.paymentType != null) {
      body['payment_type'] = cardDetails.paymentType!;
    }

    if (cardDetails.saveCard == true) {
      body['save_card'] = true;
      if (cardDetails.customerEmail != null) {
        body['customer_email'] = cardDetails.customerEmail!;
      }
    }

    print(
      '🔐 [PaymentService] Tokenizando cartão via Vault: POST /api/vault/card/tokenize',
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/vault/card/tokenize'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final resBody = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (resBody != null && resBody is Map) {
          final backendError = resBody['error'] ?? resBody['message'];
          if (backendError != null) {
            throw Exception(backendError);
          }
        }
        throw Exception(
          'Falha ao processar os dados do cartão de crédito. Por favor, verifique os dados informados.',
        );
      }

      if (resBody == null ||
          resBody['ok'] != true ||
          resBody['data']?['vault_token'] == null) {
        throw Exception(
          'Não foi possível gerar o vault token do cartão de crédito.',
        );
      }

      final data = resBody['data'];
      print(
        '✅ [PaymentService] Vault token gerado: ${data['vault_token'].substring(0, 8)}... (last4: ${data['last_four']})',
      );

      return VaultTokenResponse.fromJson(data);
    } catch (err) {
      print('❌ [PaymentService] Erro na tokenização via Vault: $err');
      rethrow;
    }
  }

  /// Tokeniza um cartão SALVO usando o endpoint Vault de reutilização.
  /// O backend busca o cartão pelo card_id no Mercado Pago e gera um novo vault_token.
  Future<VaultTokenResponse> tokenizeSavedCard(
    String cardId, {
    String? securityCode,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Tenant-ID': tenantId,
    };

    final Map<String, dynamic> body = {
      'card_id': cardId,
      if (securityCode != null) 'security_code': securityCode,
    };

    print(
      '🔐 [PaymentService] Tokenizando cartão salvo via Vault: POST /api/vault/card/tokenize/saved (card_id: $cardId)',
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/vault/card/tokenize/saved'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final resBody = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (resBody != null && resBody is Map) {
          final backendError = resBody['error'] ?? resBody['message'];
          if (backendError != null) {
            throw Exception(backendError);
          }
        }
        throw Exception(
          'Falha ao processar o cartão salvo. Tente novamente ou utilize um novo cartão.',
        );
      }

      if (resBody == null ||
          resBody['ok'] != true ||
          resBody['data']?['vault_token'] == null) {
        throw Exception(
          'Não foi possível gerar o vault token para o cartão salvo.',
        );
      }

      final data = resBody['data'];
      print(
        '✅ [PaymentService] Vault token (saved card) gerado: ${data['vault_token'].substring(0, 8)}...',
      );

      return VaultTokenResponse.fromJson(data);
    } catch (err) {
      print(
        '❌ [PaymentService] Erro na tokenização do cartão salvo via Vault: $err',
      );
      rethrow;
    }
  }
}
