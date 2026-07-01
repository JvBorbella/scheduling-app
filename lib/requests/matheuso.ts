// import { Injectable, inject, signal } from '@angular/core';
// import { HttpClient, HttpHeaders } from '@angular/common/http';
// import { firstValueFrom, timeout } from 'rxjs';
// import { LynxbdService } from './lynxbd.service';
// import { TenantService } from './tenant.service';
// import { environment } from '../../../environments/environment';

// export interface PaymentPayload {
//     type: 'pix' | 'credit_card' | 'debit_card' | 'boleto';
//     order_id: string;
//     payment_method_id: string;
//     amount: number;
//     customer: {
//         email: string;
//         name: string;
//         document: string;
//         phone?: string;
//     };
//     vault_token?: string;
//     installments?: number;
//     card?: {
//         payment_method_id: string;
//     };
//     // Campos mantidos para Pix/Boleto
//     expiration_time?: string;
//     description?: string;
// }

// /**
//  * Resposta do Vault ao tokenizar um cartão (novo ou salvo).
//  */
// export interface VaultTokenResponse {
//     vault_token: string;
//     last_four: string;
//     brand: string;
//     expires_at: string;
//     card_id?: string;
// }

// @Injectable({
//     providedIn: 'root'
// })
// export class PaymentService {
//     private http = inject(HttpClient);
//     private lynxbd = inject(LynxbdService);
//     private tenantService = inject(TenantService);

//     activeGateway = signal<any | null>(null);
//     loadingGateway = signal<boolean>(false);

//     /**
//      * Carrega o gateway de pagamento ativo para o tenant atual.
//      */
//     async loadActiveGateway(): Promise<any | null> {
//         this.loadingGateway.set(true);
//         try {
//             const gws: any[] = await firstValueFrom(this.lynxbd.getSelect({
//                 tabela: 'payment_gateways',
//                 where: { tenant_id: this.tenantService.currentTenantId, is_active: 1 }
//             }));
//             if (gws && gws.length > 0) {
//                 this.activeGateway.set(gws[0]);
//                 return gws[0];
//             } else {
//                 this.activeGateway.set(null);
//                 return null;
//             }
//         } catch (err) {
//             console.error('Erro ao carregar gateway ativo:', err);
//             this.activeGateway.set(null);
//             return null;
//         } finally {
//             this.loadingGateway.set(false);
//         }
//     }

//     /**
//      * Obtém a chave pública do gateway ativo para tokenização.
//      */
//     async getPublicKey(): Promise<string> {
//         const gw = this.activeGateway() || await this.loadActiveGateway();
//         if (gw && gw.public_key) {
//             return gw.public_key;
//         }

//         // Chamada à API como fallback secundário
//         try {
//             const headers = new HttpHeaders().set('X-Tenant-ID', this.tenantService.currentTenantId);
//             const res: any = await firstValueFrom(
//                 this.http.get(`${environment.apiUrl}/api/payments/public-key`, { headers })
//             );
//             return res.public_key || '';
//         } catch (err) {
//             console.warn('API de public-key indisponível, usando fallback local');
//             return gw?.public_key || 'TEST-PUBLIC-KEY-MOCK';
//         }
//     }

//     /**
//      * Envia a transação de pagamento para a API com timeout estrito de 15 segundos.
//      * Para cartão de crédito, o payload deve conter `vault_token` obtido via `tokenizeVault()`.
//      */
//     async processPayment(payload: PaymentPayload): Promise<any> {
//         const tenantId = this.tenantService.currentTenantId;
//         const headers = new HttpHeaders({
//             'Content-Type': 'application/json',
//             'X-Tenant-ID': tenantId
//         });

//         const base = environment.apiUrl;
//         let url = `${base}/api/payments`;
//         if (payload.type === 'credit_card' || payload.type === 'debit_card') {
//             url = `${base}/api/payments/card`;
//         }

//         // Detecta se estamos em modo sandbox e sanitiza o e-mail do cliente caso necessário
//         let gateway = this.activeGateway();
//         if (!gateway) {
//             gateway = await this.loadActiveGateway();
//         }
//         const isSandbox = gateway ? gateway.environment === 'sandbox' : true;

//         if (isSandbox && payload.customer && payload.customer.email) {
//             const email = payload.customer.email;
//             if (!email.endsWith('@testuser.com')) {
//                 const parts = email.split('@');
//                 const localPart = parts[0].replace(/[^a-zA-Z0-9]/g, ''); // Remove caracteres especiais
//                 payload.customer.email = `${localPart}@testuser.com`;
//                 console.log(`🔧 [PaymentService] Sandbox mode detected. Automatically rewritten customer email to: ${payload.customer.email}`);
//             }
//         }

//         console.log(`🚀 [PaymentService] Attempting payment request to: ${url} (Timeout: 15s)`);

//         try {
//             const response: any = await firstValueFrom(
//                 this.http.post(url, payload, { headers }).pipe(timeout(15000))
//             );

//             // Validação estrita e literal
//             if (!response) {
//                 throw new Error('Nenhuma resposta recebida do servidor de pagamentos.');
//             }

//             if (response.success !== true) {
//                 throw new Error(response.error || response.status_detail || 'Erro no processamento do pagamento no gateway.');
//             }

//             return response;
//         } catch (err: any) {
//             console.error('❌ [PaymentService] Payment request failed or timed out:', err);
//             if (err.name === 'TimeoutError') {
//                 throw new Error('O processamento do pagamento excedeu o limite de tempo de 15 segundos. O carrinho foi mantido salvo para que você possa tentar novamente.');
//             }

//             // Se for um erro HTTP com corpo de erro do backend (ex: status 400 ou 422)
//             if (err.error) {
//                 const backendError = err.error.error || err.error.status_detail || err.error.message;
//                 if (backendError) {
//                     throw new Error(backendError);
//                 }
//             }

//             throw err;
//         }
//     }

//     /**
//      * Tokeniza um cartão de crédito NOVO usando o endpoint Vault do backend.
//      * O backend abstrai o SDK do Mercado Pago — nenhum script externo é necessário no frontend.
//      *
//      * @param cardDetails Dados do cartão a ser tokenizado
//      * @returns VaultTokenResponse com vault_token, last_four, brand, expires_at e card_id (se save_card=true)
//      */
//     async tokenizeVault(cardDetails: {
//         cardNumber: string;
//         securityCode: string;
//         expirationMonth: string;
//         expirationYear: string;
//         cardholderName: string;
//         documentType?: string;
//         documentNumber: string;
//         saveCard?: boolean;
//         customerEmail?: string;
//         paymentType?: string;
//     }): Promise<VaultTokenResponse> {
//         const tenantId = this.tenantService.currentTenantId;
//         const headers = new HttpHeaders({
//             'Content-Type': 'application/json',
//             'X-Tenant-ID': tenantId
//         });

//         const body: any = {
//             card_number: cardDetails.cardNumber.replace(/\s+/g, ''),
//             security_code: cardDetails.securityCode,
//             expiration_month: cardDetails.expirationMonth,
//             expiration_year: cardDetails.expirationYear,
//             cardholder_name: cardDetails.cardholderName,
//             document_type: cardDetails.documentType || 'CPF',
//             document_number: cardDetails.documentNumber
//         };

//         if (cardDetails.paymentType) {
//             body.payment_type = cardDetails.paymentType;
//         }

//         // Flags opcionais para salvar o cartão no Mercado Pago
//         if (cardDetails.saveCard) {
//             body.save_card = true;
//             if (cardDetails.customerEmail) {
//                 body.customer_email = cardDetails.customerEmail;
//             }
//         }

//         console.log(`🔐 [PaymentService] Tokenizando cartão via Vault: POST /api/vault/card/tokenize`);

//         try {
//             const res: any = await firstValueFrom(
//                 this.http.post(`${environment.apiUrl}/api/vault/card/tokenize`, body, { headers }).pipe(timeout(10000))
//             );

//             if (!res || !res.ok || !res.data?.vault_token) {
//                 throw new Error('Não foi possível gerar o vault token do cartão de crédito.');
//             }

//             console.log(`✅ [PaymentService] Vault token gerado: ${res.data.vault_token.substring(0, 8)}... (last4: ${res.data.last_four})`);

//             return {
//                 vault_token: res.data.vault_token,
//                 last_four: res.data.last_four || '',
//                 brand: res.data.brand || '',
//                 expires_at: res.data.expires_at || '',
//                 card_id: res.data.card_id
//             };
//         } catch (err: any) {
//             console.error('❌ [PaymentService] Erro na tokenização via Vault:', err);
//             throw new Error(
//                 err?.error?.error || err?.error?.message || err?.message ||
//                 'Falha ao processar os dados do cartão de crédito. Por favor, verifique os dados informados.'
//             );
//         }
//     }

//     /**
//      * Tokeniza um cartão SALVO usando o endpoint Vault de reutilização.
//      * O backend busca o cartão pelo card_id no Mercado Pago e gera um novo vault_token.
//      *
//      * @param cardId ID do cartão salvo no Mercado Pago
//      * @param securityCode CVV (opcional, depende da configuração do gateway)
//      * @returns VaultTokenResponse com novo vault_token temporário
//      */
//     async tokenizeSavedCard(cardId: string, securityCode?: string): Promise<VaultTokenResponse> {
//         const tenantId = this.tenantService.currentTenantId;
//         const headers = new HttpHeaders({
//             'Content-Type': 'application/json',
//             'X-Tenant-ID': tenantId
//         });

//         const body: any = { card_id: cardId };
//         if (securityCode) {
//             body.security_code = securityCode;
//         }

//         console.log(`🔐 [PaymentService] Tokenizando cartão salvo via Vault: POST /api/vault/card/tokenize/saved (card_id: ${cardId})`);

//         try {
//             const res: any = await firstValueFrom(
//                 this.http.post(`${environment.apiUrl}/api/vault/card/tokenize/saved`, body, { headers }).pipe(timeout(10000))
//             );

//             if (!res || !res.ok || !res.data?.vault_token) {
//                 throw new Error('Não foi possível gerar o vault token para o cartão salvo.');
//             }

//             console.log(`✅ [PaymentService] Vault token (saved card) gerado: ${res.data.vault_token.substring(0, 8)}...`);

//             return {
//                 vault_token: res.data.vault_token,
//                 last_four: res.data.last_four || '',
//                 brand: res.data.brand || '',
//                 expires_at: res.data.expires_at || '',
//                 card_id: res.data.card_id
//             };
//         } catch (err: any) {
//             console.error('❌ [PaymentService] Erro na tokenização do cartão salvo via Vault:', err);
//             throw new Error(
//                 err?.error?.error || err?.error?.message || err?.message ||
//                 'Falha ao processar o cartão salvo. Tente novamente ou utilize um novo cartão.'
//             );
//         }
//     }
// }