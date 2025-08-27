// ✅ PANTALLA PRINCIPAL DE CHAT - CORREGIDA
// Archivo: lib/ui/chat/ServiceChatScreen.dart

import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_app/data/services/ChatService.dart';
import 'package:Voltgo_app/ui/MenuPage/Chats/ServiceChatScreenRealTime.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceChatScreen extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final String userType; // 'user' o 'technician'

  const ServiceChatScreen({
    Key? key,
    required this.serviceRequest,
    required this.userType,
  }) : super(key: key);

  @override
  State<ServiceChatScreen> createState() => _ServiceChatScreenState();
}

class _ServiceChatScreenState extends State<ServiceChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatPolling _chatPolling = ChatPolling(); // AGREGAR ESTO

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String _otherParticipantName = '';
  int _currentUserId = 0;

  // Animaciones
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPolling();

    _initializeChat();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // ✅ LÓGICA CORREGIDA
      if (widget.userType == 'technician') {
        _otherParticipantName = widget.serviceRequest.user?.name ?? 'Cliente';

        // ✅ MÚLTIPLES FUENTES PARA OBTENER EL ID DEL TÉCNICO
        _currentUserId = widget.serviceRequest.technicianId ??
            widget.serviceRequest.technician?.id ??
            0;

        print('🔍 DEBUG: technicianId=${widget.serviceRequest.technicianId}');
        print(
            '🔍 DEBUG: technician.id=${widget.serviceRequest.technician?.id}');
        print('🔍 DEBUG: _currentUserId final=$_currentUserId');
      } else {
        _otherParticipantName =
            widget.serviceRequest.technician?.name ?? 'Técnico';
        _currentUserId = widget.serviceRequest.userId;
      }

      // Resto del código igual...
      final messages =
          await ChatService.getChatHistory(widget.serviceRequest.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });

      _slideController.forward();
      _scrollToBottom();
      print('✅ Chat inicializado: ${_messages.length} mensajes');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error inicializando chat: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Limpiar campo inmediatamente
    _messageController.clear();
    HapticFeedback.lightImpact();

    setState(() => _isSending = true);

    try {
      final sentMessage = await ChatService.sendMessage(
        serviceRequestId: widget.serviceRequest.id,
        message: message,
      );

      setState(() {
        _messages.add(sentMessage);
        _isSending = false;
      });

      _scrollToBottom();
      print('✅ Mensaje enviado: ${sentMessage.id}');
    } catch (e) {
      setState(() => _isSending = false);

      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al enviar mensaje: ${e.toString()}',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Restaurar el mensaje en el campo
      _messageController.text = message;
      print('❌ Error enviando mensaje: $e');
    }
  }

  void _startPolling() {
    _chatPolling.startPolling(widget.serviceRequest.id, (newMessages) {
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(newMessages);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    _chatPolling.stopPolling(); // AGREGAR ESTA LÍNEA

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Información del servicio
          _buildServiceInfo(),

          // Lista de mensajes
          Expanded(
            child: _buildMessagesList(),
          ),

          // Campo de entrada
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat con $_otherParticipantName',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Servicio #${widget.serviceRequest.id}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.brandBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshMessages,
          tooltip: 'Actualizar mensajes',
        ),
      ],
    );
  }

  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.electric_bolt,
              color: _getStatusColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(widget.serviceRequest.status),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(widget.serviceRequest.status),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando mensajes...',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el chat',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Intentar nuevamente',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final showAvatar =
              index == 0 || _messages[index - 1].senderId != message.senderId;

          return _buildMessageBubble(message, showAvatar);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Inicia la conversación',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userType == 'user'
                  ? 'Comunícate con tu técnico para coordinar el servicio'
                  : 'Comunícate con el cliente para coordinar el servicio',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showAvatar) {
    final isMyMessage = message.senderId == _currentUserId;

    print('📨 Message ID: ${message.id}');
    print('📨 Sender ID: ${message.senderId}');
    print('📨 Current User ID: $_currentUserId');
    print('📨 Is my message: $isMyMessage');
    print('---');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del remitente (solo si no es mi mensaje)
          if (!isMyMessage && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (message.sender?.name.isNotEmpty == true)
                      ? message.sender!.name[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMyMessage) ...[
            const SizedBox(width: 40),
          ],

          // Burbuja de mensaje
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: GoogleFonts.inter(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: GoogleFonts.inter(
                          color: isMyMessage
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final canSendMessages = !_isSending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canSendMessages,
                maxLines: null,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: canSendMessages ? (_) => _sendMessage() : null,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      canSendMessages ? 'Escribe un mensaje...' : 'Enviando...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor:
                      canSendMessages ? Colors.white : Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color:
                    canSendMessages ? AppColors.primary : Colors.grey.shade400,
                shape: BoxShape.circle,
                boxShadow: canSendMessages
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canSendMessages ? _sendMessage : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Center(
                    child: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODOS AUXILIARES

  Future<void> _refreshMessages() async {
    HapticFeedback.lightImpact();
    await _initializeChat();
  }

  Color _getStatusColor() {
    switch (widget.serviceRequest.status) {
      case 'pending':
        return Colors.blue;
      case 'accepted':
      case 'en_route':
        return Colors.blue;
      case 'on_site':
        return Colors.purple;
      case 'charging':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Cliente asignado';
      case 'accepted':
        return 'Cliente asignado';
      case 'en_route':
        return 'Técnico en camino';
      case 'on_site':
        return 'Técnico en sitio';
      case 'charging':
        return 'Cargando vehículo';
      case 'completed':
        return 'Servicio completado';
      case 'cancelled':
        return 'Servicio cancelado';
      default:
        return status;
    }
  }
}
