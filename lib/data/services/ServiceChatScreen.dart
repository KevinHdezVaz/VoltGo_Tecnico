// ✅ PANTALLA PRINCIPAL DE CHAT - ACTUALIZADA CON NOTIFICACIONES
// Archivo: lib/ui/chat/ServiceChatScreen.dart

import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_app/data/services/ChatNotificationProvider.dart';
import 'package:Voltgo_app/data/services/ChatService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/MenuPage/Chats/ServiceChatScreenRealTime.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatPolling _chatPolling = ChatPolling();

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
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _startPolling();
    _initializeChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ MARCAR COMO LEÍDO CUANDO LA APP VUELVE AL FOREGROUND
    if (state == AppLifecycleState.resumed) {
      _markChatAsRead();
    }
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
    // ✅ LÓGICA SIMPLIFICADA Y CORREGIDA
    if (widget.userType == 'technician') {
      _otherParticipantName = widget.serviceRequest.user?.name ?? 'Cliente';
      // ✅ USAR ID FIJO TEMPORAL O BUSCAR EN EL RESPONSE
      _currentUserId = 62; // kevinnn según tus logs
    } else {
      _otherParticipantName = widget.serviceRequest.technician?.name ?? 'Técnico';
      _currentUserId = widget.serviceRequest.userId;
    }

    print('🔍 FINAL DEBUG:');
    print('  - userType: ${widget.userType}');
    print('  - _currentUserId: $_currentUserId');
    print('  - _otherParticipantName: $_otherParticipantName');

      final messages =
          await ChatService.getChatHistory(widget.serviceRequest.id);
      
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });

      // ✅ MARCAR COMO LEÍDO AL CARGAR EL CHAT
      _markChatAsRead();

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

  // ✅ NUEVO: Marcar chat como leído
  Future<void> _markChatAsRead() async {
    try {
      final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
      await chatProvider.markServiceAsRead(widget.serviceRequest.id);
      print('📱 Chat marcado como leído: ${widget.serviceRequest.id}');
    } catch (e) {
      print('❌ Error marcando chat como leído: $e');
    }
  }


// Actualizar el método de error en _sendMessage()
Future<void> _sendMessage() async {
  final localizations = AppLocalizations.of(context);
  final message = _messageController.text.trim();
  if (message.isEmpty || _isSending) return;

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

    final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
    chatProvider.forceRefresh();

  } catch (e) {
    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.errorSendingMessage(e.toString()),
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    _messageController.text = message;
    print('❌ Error enviando mensaje: $e');
  }
}


  void _startPolling() {
    _chatPolling.startPolling(widget.serviceRequest.id, (newMessages) {
      if (mounted) {
        final bool hadNewMessages = newMessages.length > _messages.length;
        
        setState(() {
          _messages.clear();
          _messages.addAll(newMessages);
        });
        
        // ✅ MARCAR COMO LEÍDO SI HAY MENSAJES NUEVOS
        if (hadNewMessages) {
          _markChatAsRead();
        }
        
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
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    _chatPolling.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ MARCAR COMO LEÍDO AL SALIR DEL CHAT
        _markChatAsRead();
        return true;
      },
      child: Scaffold(
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
      ),
    );
  }


PreferredSizeWidget _buildAppBar() {
  final localizations = AppLocalizations.of(context);
  
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.chatWith(_otherParticipantName),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          localizations.serviceNumber(widget.serviceRequest.id.toString()),
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
      onPressed: () {
        _markChatAsRead();
        Navigator.pop(context);
      },
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.refresh, color: Colors.white),
        onPressed: _refreshMessages,
        tooltip: localizations.updateMessages,
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
  final localizations = AppLocalizations.of(context);
  
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
            localizations.loadingMessages,
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
              localizations.errorLoadingChat,
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
                localizations.tryAgain,
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
  final localizations = AppLocalizations.of(context);
  
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
            localizations.startConversation,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userType == 'user'
                ? localizations.communicateWithTechnician
                : localizations.communicateWithClient,
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
  print('🔍 MENSAJE: senderId=${message.senderId}, currentUserId=$_currentUserId, isMyMessage=$isMyMessage, }');

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
  final localizations = AppLocalizations.of(context);
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
                hintText: canSendMessages 
                    ? localizations.writeMessage 
                    : localizations.sending,
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


// Actualizar el método _getStatusText()
String _getStatusText(String status) {
  final localizations = AppLocalizations.of(context);
  
  switch (status) {
    case 'pending': 
      return localizations.statusPending;
    case 'accepted':
      return localizations.statusAccepted;
    case 'en_route':
      return localizations.statusEnRoute;
    case 'on_site':
      return localizations.statusOnSite;
    case 'charging':
      return localizations.statusCharging;
    case 'completed':
      return localizations.statusCompleted;
    case 'cancelled':
      return localizations.statusCancelled;
    default:
      return status;
  }
}}